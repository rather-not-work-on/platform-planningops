#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MANIFEST_VALIDATION="${TMP_DIR}/plain-python-compat-validation.json"
STATUS0="${TMP_DIR}/plain-python-compat-status.json"
STATUS0_VALIDATION="${TMP_DIR}/plain-python-compat-status-validation.json"
BUNDLE0="${TMP_DIR}/plain-python-compat-status-bundle.json"
BUNDLE0_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-validation.json"
STATUS1="${TMP_DIR}/plain-python-compat-status-bundle-status.json"
STATUS1_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-validation.json"
BUNDLE1="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle.json"
BUNDLE1_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-validation.json"
STATUS2="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status.json"
STATUS2_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-validation.json"
BUNDLE2="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle.json"
BUNDLE2_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-validation.json"
STATUS3="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status.json"
STATUS3_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-validation.json"
BUNDLE3="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle.json"
BUNDLE3_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STATUS4="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STATUS4_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
BUNDLE4="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
BUNDLE4_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STATUS5="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STATUS5_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
BUNDLE5="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
BUNDLE5_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STATUS6="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STATUS6_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
BUNDLE6="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
BUNDLE6_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
REPORT_PATH="${TMP_DIR}/doctor-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.txt"
BROKEN_BUNDLE="${TMP_DIR}/broken-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
BROKEN_REPORT="${TMP_DIR}/doctor-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-broken.txt"

resolve_path() {
  python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$1"
}

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --validation-output "${MANIFEST_VALIDATION}" \
  --status-output "${STATUS0}" \
  --status-validation-output "${STATUS0_VALIDATION}" \
  --status-bundle-output "${BUNDLE0}" \
  --status-bundle-validation-output "${BUNDLE0_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py" \
  --artifact-file "${STATUS0}" \
  --bundle-output "${BUNDLE1}" \
  --status-output "${STATUS1}" \
  --status-validation-output "${STATUS1_VALIDATION}" \
  --bundle-validation-output "${BUNDLE1_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS1}" \
  --bundle-output "${BUNDLE2}" \
  --status-output "${STATUS2}" \
  --status-validation-output "${STATUS2_VALIDATION}" \
  --bundle-validation-output "${BUNDLE2_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS2}" \
  --bundle-output "${BUNDLE3}" \
  --status-output "${STATUS3}" \
  --status-validation-output "${STATUS3_VALIDATION}" \
  --bundle-validation-output "${BUNDLE3_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS3}" \
  --bundle-output "${BUNDLE4}" \
  --status-output "${STATUS4}" \
  --status-validation-output "${STATUS4_VALIDATION}" \
  --bundle-validation-output "${BUNDLE4_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS4}" \
  --bundle-output "${BUNDLE5}" \
  --status-output "${STATUS5}" \
  --status-validation-output "${STATUS5_VALIDATION}" \
  --bundle-validation-output "${BUNDLE5_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS5}" \
  --bundle-output "${BUNDLE6}" \
  --status-output "${STATUS6}" \
  --status-validation-output "${STATUS6_VALIDATION}" \
  --bundle-validation-output "${BUNDLE6_VALIDATION}" >"${REPORT_PATH}"

RESOLVED_BUNDLE6="$(resolve_path "${BUNDLE6}")"
RESOLVED_STATUS6="$(resolve_path "${STATUS6}")"
RESOLVED_STATUS6_VALIDATION="$(resolve_path "${STATUS6_VALIDATION}")"
RESOLVED_BUNDLE6_VALIDATION="$(resolve_path "${BUNDLE6_VALIDATION}")"

grep -q "source kind: artifact" "${REPORT_PATH}"
grep -q "bundle path: ${RESOLVED_BUNDLE6}" "${REPORT_PATH}"
grep -q "bundle status output path: ${RESOLVED_STATUS6}" "${REPORT_PATH}"
grep -q "bundle status validation output path: ${RESOLVED_STATUS6_VALIDATION}" "${REPORT_PATH}"
grep -q "bundle validation output path: ${RESOLVED_BUNDLE6_VALIDATION}" "${REPORT_PATH}"
grep -q "status verdict: pass" "${REPORT_PATH}"
grep -q "status validation verdict: pass" "${REPORT_PATH}"
grep -q "bundle status verdict: pass" "${REPORT_PATH}"
grep -q "bundle status validation verdict: pass" "${REPORT_PATH}"
grep -q "bundle validation verdict: pass" "${REPORT_PATH}"
grep -q "ready: True" "${REPORT_PATH}"
grep -q "next step: none" "${REPORT_PATH}"

python3 - <<'PY' "${BUNDLE6}" "${STATUS6}" "${BUNDLE6_VALIDATION}" "${STATUS6_VALIDATION}"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
status = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

assert bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), bundle
assert bundle["ready"] is True, bundle
assert bundle["status_verdict"] == "pass", bundle
assert bundle["status_validation_verdict"] == "pass", bundle
assert bundle["bundle_status_verdict"] == "pass", bundle
assert bundle["bundle_status_validation_verdict"] == "pass", bundle
assert bundle["bundle_validation_verdict"] == "pass", bundle

assert status["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"] == str(Path(sys.argv[2]).resolve()), status
assert status["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"] == str(Path(sys.argv[4]).resolve()), status
assert status["bundle_path"] == str(Path(sys.argv[1]).resolve()), status
assert status["verdict"] == "pass", status

assert validation["bundle_path"] == str(Path(sys.argv[1]).resolve()), validation
assert validation["verdict"] == "pass", validation

assert status_validation["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"] == str(Path(sys.argv[2]).resolve()), status_validation
assert status_validation["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"] == str(Path(sys.argv[4]).resolve()), status_validation
assert status_validation["verdict"] == "pass", status_validation
PY

python3 - <<'PY' "${BUNDLE6}" "${BROKEN_BUNDLE}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["status_validation_verdict"] = "fail"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --bundle-file "${BROKEN_BUNDLE}" \
  --status-output "${STATUS6}" \
  --status-validation-output "${STATUS6_VALIDATION}" \
  --bundle-validation-output "${BUNDLE6_VALIDATION}" \
  --require-pass >"${BROKEN_REPORT}" 2>&1; then
  echo "expected status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle doctor to fail on broken bundle" >&2
  exit 1
fi

grep -q "source kind: bundle" "${BROKEN_REPORT}"
grep -q "status validation verdict: fail" "${BROKEN_REPORT}"
grep -q "bundle validation output path:" "${BROKEN_REPORT}"

echo "doctor plain python compat manifest status bundle status bundle status bundle status bundle status bundle status bundle ok"
