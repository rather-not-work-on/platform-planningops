#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_PATH="${ROOT_DIR}/planningops/config/plain-python-compat-manifest.json"
SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest.schema.json"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest.py" \
  --manifest-file "${MANIFEST_PATH}" \
  --schema-file "${SCHEMA_PATH}" \
  --output "${tmp_dir}/valid-report.json" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${tmp_dir}/valid-report.json"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert report["validation_output_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
assert report["entrypoint_count"] >= 1, report
assert report["resolved_entrypoint_count"] == report["entrypoint_count"], report
assert report["resolved_runtime_stack_sequence"]["issue_driven_entrypoint_id"] == report["runtime_stack_sequence"]["issue_driven_entrypoint_id"], report
assert report["resolved_runtime_stack_sequence"]["local_entrypoint_id"] == report["runtime_stack_sequence"]["local_entrypoint_id"], report
assert len(report["loop_guardrails_chain"]) >= 2, report
assert [step["id"] for step in report["resolved_loop_guardrails_chain"]] == [step["id"] for step in report["loop_guardrails_chain"]], report
assert str((root_dir / "planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh").resolve()) in report["resolved_guardrail_script_paths"], report
PY

python3 - <<'PY' "${MANIFEST_PATH}" "${tmp_dir}/invalid-manifest.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["entrypoints"][0]["id"] = doc["entrypoints"][1]["id"]
doc["entrypoints"][0]["mode"] = "import"
doc["entrypoints"][0].pop("symbol", None)
doc["runtime_stack_sequence"]["issue_driven_entrypoint_id"] = "missing-entrypoint"
doc["loop_guardrails_chain"][0]["id"] = doc["loop_guardrails_chain"][1]["id"]
doc["loop_guardrails_chain"][0]["workflow_command"] = ""
doc["loop_guardrails_chain"][0]["local_matrix_command"] = "bash planningops/scripts/missing_plain_python_guardrail.sh"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest.py" \
  --manifest-file "${tmp_dir}/invalid-manifest.json" \
  --schema-file "${SCHEMA_PATH}" \
  --output "${tmp_dir}/invalid-report.json" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid plain python compat manifest"
  exit 1
fi

python3 - <<'PY' "${tmp_dir}/invalid-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert report["error_count"] >= 3, report
assert any("entrypoints[0].symbol must be a non-empty string when mode=import" in item for item in report["errors"]), report
assert any("entrypoint ids must be unique" in item for item in report["errors"]), report
assert any("duplicate plain-python compat manifest id" in item for item in report["errors"]), report
assert any("loop_guardrails_chain ids must be unique" in item for item in report["errors"]), report
assert any("loop_guardrails_chain[0].workflow_command must be a non-empty string" in item for item in report["errors"]), report
assert any("loop_guardrails_chain[0].local_matrix_command references missing script: planningops/scripts/missing_plain_python_guardrail.sh" in item for item in report["errors"]), report
PY

echo "plain python compat manifest contract ok"
