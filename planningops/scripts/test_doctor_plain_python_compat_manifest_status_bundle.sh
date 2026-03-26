#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_PATH="${TMP_DIR}/plain-python-compat-validation.json"
STATUS_PATH="${TMP_DIR}/plain-python-compat-status.json"
STATUS_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-validation.json"
BASE_BUNDLE_PATH="${TMP_DIR}/plain-python-compat-status-bundle-base.json"
BASE_BUNDLE_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-base-validation.json"
DOCTOR_BUNDLE_PATH="${TMP_DIR}/plain-python-compat-status-bundle.json"
DOCTOR_BUNDLE_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-validation.json"
DOCTOR_STATUS_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status.json"
DOCTOR_STATUS_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-validation.json"
REPORT_PATH="${TMP_DIR}/doctor-status-bundle.txt"
BROKEN_BUNDLE_PATH="${TMP_DIR}/broken-status-bundle.json"
BROKEN_REPORT_PATH="${TMP_DIR}/doctor-status-bundle-broken.txt"
DOCTOR_BUNDLE_REAL="$(python3 - <<'PY' "${DOCTOR_BUNDLE_PATH}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_BUNDLE_VALIDATION_REAL="$(python3 - <<'PY' "${DOCTOR_BUNDLE_VALIDATION_PATH}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_REAL="$(python3 - <<'PY' "${DOCTOR_STATUS_PATH}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_VALIDATION_REAL="$(python3 - <<'PY' "${DOCTOR_STATUS_VALIDATION_PATH}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --validation-output "${VALIDATION_PATH}" \
  --status-output "${STATUS_PATH}" \
  --status-validation-output "${STATUS_VALIDATION_PATH}" \
  --status-bundle-output "${BASE_BUNDLE_PATH}" \
  --status-bundle-validation-output "${BASE_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py" \
  --artifact-file "${STATUS_PATH}" \
  --bundle-output "${DOCTOR_BUNDLE_PATH}" \
  --status-output "${DOCTOR_STATUS_PATH}" \
  --status-validation-output "${DOCTOR_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${DOCTOR_BUNDLE_VALIDATION_PATH}" >"${REPORT_PATH}"

grep -q "source kind: artifact" "${REPORT_PATH}"
grep -q "bundle path: ${DOCTOR_BUNDLE_REAL}" "${REPORT_PATH}"
grep -q "bundle status output path: ${DOCTOR_STATUS_REAL}" "${REPORT_PATH}"
grep -q "bundle status validation output path: ${DOCTOR_STATUS_VALIDATION_REAL}" "${REPORT_PATH}"
grep -q "bundle validation output path: ${DOCTOR_BUNDLE_VALIDATION_REAL}" "${REPORT_PATH}"
grep -q "bundle verdict: pass" "${REPORT_PATH}"
grep -q "bundle status validation verdict: pass" "${REPORT_PATH}"
grep -q "bundle validation verdict: pass" "${REPORT_PATH}"
grep -q "ready: True" "${REPORT_PATH}"
grep -q "next step: none" "${REPORT_PATH}"

python3 - <<'PY' "${DOCTOR_BUNDLE_PATH}" "${DOCTOR_BUNDLE_VALIDATION_PATH}" "${DOCTOR_STATUS_PATH}" "${DOCTOR_STATUS_VALIDATION_PATH}" "${STATUS_PATH}" "${STATUS_VALIDATION_PATH}"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
status = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

assert bundle["resolved_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), bundle
assert bundle["status_path"] == str(Path(sys.argv[5]).resolve()), bundle
assert bundle["status_validation_path"] == str(Path(sys.argv[6]).resolve()), bundle
assert bundle["status_verdict"] == "pass", bundle
assert bundle["status_validation_verdict"] == "pass", bundle

assert validation["output_path"] == str(Path(sys.argv[2]).resolve()), validation
assert validation["bundle_path"] == str(Path(sys.argv[1]).resolve()), validation
assert validation["verdict"] == "pass", validation

assert status["bundle_status_output_path"] == str(Path(sys.argv[3]).resolve()), status
assert status["bundle_path"] == str(Path(sys.argv[1]).resolve()), status
assert status["resolved_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), status
assert status["bundle_validation_output_path"] == str(Path(sys.argv[2]).resolve()), status
assert len(status["resolved_guardrail_script_paths"]) >= 1, status
assert status["verdict"] == "pass", status

assert status_validation["bundle_status_path"] == str(Path(sys.argv[3]).resolve()), status_validation
assert status_validation["bundle_status_output_path"] == str(Path(sys.argv[3]).resolve()), status_validation
assert status_validation["output_path"] == str(Path(sys.argv[4]).resolve()), status_validation
assert status_validation["bundle_validation_output_path"] == str(Path(sys.argv[2]).resolve()), status_validation
assert status_validation["resolved_guardrail_script_paths"] == status["resolved_guardrail_script_paths"], status_validation
assert status_validation["verdict"] == "pass", status_validation
PY

python3 - <<'PY' "${DOCTOR_BUNDLE_PATH}" "${BROKEN_BUNDLE_PATH}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["status_validation_verdict"] = "fail"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py" \
  --bundle-file "${BROKEN_BUNDLE_PATH}" \
  --status-output "${DOCTOR_STATUS_PATH}" \
  --status-validation-output "${DOCTOR_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${DOCTOR_BUNDLE_VALIDATION_PATH}" \
  --require-pass >"${BROKEN_REPORT_PATH}" 2>&1; then
  echo "expected status bundle doctor to fail on broken bundle" >&2
  exit 1
fi

grep -q "source kind: bundle" "${BROKEN_REPORT_PATH}"
grep -q "bundle status validation output path:" "${BROKEN_REPORT_PATH}"
grep -q "bundle status validation verdict: fail" "${BROKEN_REPORT_PATH}"

echo "doctor plain python compat manifest status bundle ok"
