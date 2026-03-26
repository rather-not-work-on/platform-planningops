#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPORT_PATH="${TMP_DIR}/plain-python-compat-manifest-validation.json"
REPORT_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-validation.schema.json"

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest.py" \
  --output "${REPORT_PATH}" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${REPORT_PATH}" "${REPORT_SCHEMA_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["validation_output_path"] == str(report_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
assert report["resolved_entrypoint_count"] == report["entrypoint_count"], report
assert len(report["resolved_loop_guardrails_chain"]) == len(report["loop_guardrails_chain"]), report
assert len(report["resolved_guardrail_script_paths"]) >= 1, report
PY

python3 - <<'PY' "${REPORT_PATH}" "${TMP_DIR}/invalid-report.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["verdict"] = "maybe"
doc["error_count"] = "zero"
doc["resolved_runtime_stack_sequence"].pop("issue_driven_resolved_path")
doc["resolved_loop_guardrails_chain"][0].pop("workflow_command")
doc.pop("resolved_guardrail_script_paths")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "${ROOT_DIR}" "${TMP_DIR}/invalid-report.json" "${REPORT_SCHEMA_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert errors, report
assert any("$.verdict invalid enum value: maybe" in item for item in errors), errors
assert any("$.resolved_runtime_stack_sequence.issue_driven_resolved_path is required" in item for item in errors), errors
assert any("$.resolved_loop_guardrails_chain[0].workflow_command is required" in item for item in errors), errors
assert any("$.resolved_guardrail_script_paths is required" in item for item in errors), errors
PY

echo "validate plain python compat manifest validation contract ok"
