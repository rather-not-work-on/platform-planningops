#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
RESOLVER_PATH="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"

REPORT="${TMP_DIR}/doctor.txt"
VALIDATION="${TMP_DIR}/plain-python-compat-validation.json"
VALIDATION_REAL="$(python3 - <<'PY' "${VALIDATION}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
STATUS="${TMP_DIR}/plain-python-compat-status.json"
STATUS_REAL="$(python3 - <<'PY' "${STATUS}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
STATUS_VALIDATION="${TMP_DIR}/plain-python-compat-status-validation.json"
STATUS_VALIDATION_REAL="$(python3 - <<'PY' "${STATUS_VALIDATION}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
STATUS_BUNDLE="${TMP_DIR}/plain-python-compat-status-bundle.json"
STATUS_BUNDLE_REAL="$(python3 - <<'PY' "${STATUS_BUNDLE}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
STATUS_BUNDLE_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-validation.json"
STATUS_BUNDLE_VALIDATION_REAL="$(python3 - <<'PY' "${STATUS_BUNDLE_VALIDATION}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
BROKEN_MANIFEST="${TMP_DIR}/broken-manifest.json"
BROKEN_REPORT="${TMP_DIR}/doctor-broken.txt"
EXPECTED_GUARDRAILS_JSON="$(python3 "${RESOLVER_PATH}" --mode guardrails)"
EXPECTED_GUARDRAILS_COUNT="$(python3 - <<'PY' "${EXPECTED_GUARDRAILS_JSON}"
import json
import sys

print(len(json.loads(sys.argv[1])))
PY
)"
EXPECTED_GUARDRAILS_CHAIN="$(python3 - <<'PY' "${EXPECTED_GUARDRAILS_JSON}"
import json
import sys

print(" -> ".join(step["id"] for step in json.loads(sys.argv[1])))
PY
)"

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --validation-output "${VALIDATION}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --status-bundle-output "${STATUS_BUNDLE}" \
  --status-bundle-validation-output "${STATUS_BUNDLE_VALIDATION}" >"${REPORT}"

grep -q "validation output path: ${VALIDATION_REAL}" "${REPORT}"
grep -q "status output path: ${STATUS_REAL}" "${REPORT}"
grep -q "status validation output path: ${STATUS_VALIDATION_REAL}" "${REPORT}"
grep -q "status bundle output path: ${STATUS_BUNDLE_REAL}" "${REPORT}"
grep -q "status bundle validation output path: ${STATUS_BUNDLE_VALIDATION_REAL}" "${REPORT}"
grep -q "verdict: pass" "${REPORT}"
grep -q "status validation verdict: pass" "${REPORT}"
grep -q "status bundle verdict: pass" "${REPORT}"
grep -q "status bundle validation verdict: pass" "${REPORT}"
grep -q "issue-driven entrypoint id: planningops-run-issue-driven-runtime-stack-smoke" "${REPORT}"
grep -q "local entrypoint id: planningops-run-local-runtime-stack-smoke" "${REPORT}"
grep -q "loop-guardrails step count: ${EXPECTED_GUARDRAILS_COUNT}" "${REPORT}"
grep -q "loop-guardrails chain ids: ${EXPECTED_GUARDRAILS_CHAIN}" "${REPORT}"
grep -q "ready: True" "${REPORT}"
grep -q "next step: none" "${REPORT}"

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
assert report["resolved_runtime_stack_sequence"]["issue_driven_entrypoint_id"] == "planningops-run-issue-driven-runtime-stack-smoke", report
assert report["resolved_runtime_stack_sequence"]["local_entrypoint_id"] == "planningops-run-local-runtime-stack-smoke", report
assert report["resolved_loop_guardrails_chain"] == expected_guardrails, report
assert report["resolved_loop_guardrails_chain"][-1]["id"] == "runtime-stack-sequence", report
assert str((root_dir / "planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh").resolve()) in report["resolved_guardrail_script_paths"], report
PY

python3 - <<'PY' "${ROOT_DIR}" "${STATUS}" "${STATUS_VALIDATION_REAL}" "${EXPECTED_GUARDRAILS_JSON}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
expected_guardrails = json.loads(sys.argv[4])
assert report["status_output_path"] == str(Path(sys.argv[2]).resolve()), report
assert report["status_validation_output_path"] == sys.argv[3], report
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
assert report["status_ready"] is True, report
PY

python3 - <<'PY' "${STATUS_BUNDLE}" "${STATUS_REAL}" "${STATUS_VALIDATION_REAL}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["resolved_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), report
assert report["status_path"] == sys.argv[2], report
assert report["status_validation_path"] == sys.argv[3], report
assert report["status_verdict"] == "pass", report
assert report["status_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE_VALIDATION}" "${STATUS_BUNDLE_REAL}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["output_path"] == str(Path(sys.argv[1]).resolve()), report
assert report["bundle_path"] == sys.argv[2], report
assert report["resolved_status_bundle_path"] == sys.argv[2], report
assert report["verdict"] == "pass", report
assert report["bundle_status_verdict"] == "pass", report
assert report["bundle_status_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${ROOT_DIR}/planningops/config/plain-python-compat-manifest.json" "${BROKEN_MANIFEST}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["entrypoints"][0]["id"] = doc["entrypoints"][1]["id"]
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --manifest-file "${BROKEN_MANIFEST}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --status-bundle-output "${STATUS_BUNDLE}" \
  --status-bundle-validation-output "${STATUS_BUNDLE_VALIDATION}" \
  --require-pass >"${BROKEN_REPORT}" 2>&1; then
  echo "expected doctor to fail on broken manifest" >&2
  exit 1
fi

grep -q "verdict: fail" "${BROKEN_REPORT}"
grep -q "status validation output path:" "${BROKEN_REPORT}"
grep -q "status bundle output path:" "${BROKEN_REPORT}"
grep -q "status bundle validation output path:" "${BROKEN_REPORT}"
grep -q "duplicate plain-python compat manifest id" "${BROKEN_REPORT}"
grep -q "validation output path:" "${BROKEN_REPORT}"
grep -q "next step: python3 planningops/scripts/validate_plain_python_compat_manifest.py --manifest-file .*broken-manifest.json" "${BROKEN_REPORT}"

echo "doctor plain python compat manifest ok"
