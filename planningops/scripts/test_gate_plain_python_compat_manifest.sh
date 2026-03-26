#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
RESOLVER_PATH="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"

VALIDATION="${TMP_DIR}/plain-python-compat-validation.json"
STATUS="${TMP_DIR}/plain-python-compat-status.json"
STATUS_VALIDATION="${TMP_DIR}/plain-python-compat-status-validation.json"
STATUS_BUNDLE="${TMP_DIR}/plain-python-compat-status-bundle.json"
STATUS_BUNDLE_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-validation.json"
BROKEN_MANIFEST="${TMP_DIR}/broken-manifest.json"
EXPECTED_GUARDRAILS_JSON="$(python3 "${RESOLVER_PATH}" --mode guardrails)"

bash "${ROOT_DIR}/planningops/scripts/gate_plain_python_compat_manifest.sh" \
  --validation-output "${VALIDATION}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --status-bundle-output "${STATUS_BUNDLE}" \
  --status-bundle-validation-output "${STATUS_BUNDLE_VALIDATION}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${VALIDATION}" "${EXPECTED_GUARDRAILS_JSON}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
expected_guardrails = json.loads(sys.argv[3])
assert report["validation_output_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
assert report["loop_guardrails_chain"] == expected_guardrails, report
assert report["resolved_loop_guardrails_chain"] == expected_guardrails, report
assert report["resolved_loop_guardrails_chain"][-1]["id"] == "runtime-stack-sequence", report
assert str((root_dir / "planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh").resolve()) in report["resolved_guardrail_script_paths"], report
PY

python3 - <<'PY' "${ROOT_DIR}" "${STATUS}" "${STATUS_VALIDATION}" "${EXPECTED_GUARDRAILS_JSON}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
expected_guardrails = json.loads(sys.argv[4])
assert report["status_output_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["status_validation_output_path"] == str(Path(sys.argv[3]).resolve()), report
assert report["ready"] is True, report
assert report["next_step"] == "none", report
assert report["resolved_loop_guardrails_chain"] == expected_guardrails, report
assert str((root_dir / "planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh").resolve()) in report["resolved_guardrail_script_paths"], report
PY

python3 - <<'PY' "${STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["output_path"] == str(Path(sys.argv[1]).resolve()), report
assert report["status_validation_output_path"] == str(Path(sys.argv[1]).resolve()), report
assert report["verdict"] == "pass", report
assert report["status_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE}" "${STATUS}" "${STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["resolved_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), report
assert report["status_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["status_validation_path"] == str(Path(sys.argv[3]).resolve()), report
assert report["status_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE_VALIDATION}" "${STATUS_BUNDLE}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["output_path"] == str(Path(sys.argv[1]).resolve()), report
assert report["bundle_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["resolved_status_bundle_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["verdict"] == "pass", report
PY

python3 - <<'PY' "${ROOT_DIR}/planningops/config/plain-python-compat-manifest.json" "${BROKEN_MANIFEST}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["runtime_stack_sequence"]["issue_driven_entrypoint_id"] = "missing-entrypoint"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if bash "${ROOT_DIR}/planningops/scripts/gate_plain_python_compat_manifest.sh" \
  --manifest-file "${BROKEN_MANIFEST}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --status-bundle-output "${STATUS_BUNDLE}" \
  --status-bundle-validation-output "${STATUS_BUNDLE_VALIDATION}" >/dev/null 2>&1; then
  echo "expected gate to fail on broken manifest" >&2
  exit 1
fi

echo "gate plain python compat manifest ok"
