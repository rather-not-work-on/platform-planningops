#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_PATH="${TMP_DIR}/plain-python-compat-validation.json"
STATUS_PATH="${TMP_DIR}/plain-python-compat-status.json"
STATUS_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-validation.json"
STATUS_BUNDLE_PATH="${TMP_DIR}/plain-python-compat-status-bundle.json"
STATUS_BUNDLE_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-validation.json"
STATUS_BUNDLE_STATUS_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status.json"
STATUS_BUNDLE_STATUS_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-validation.json"
BROKEN_BUNDLE_PATH="${TMP_DIR}/broken-status-bundle-status-bundle.json"

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --validation-output "${VALIDATION_PATH}" \
  --status-output "${STATUS_PATH}" \
  --status-validation-output "${STATUS_VALIDATION_PATH}" \
  --status-bundle-output "${STATUS_BUNDLE_PATH}" \
  --status-bundle-validation-output "${STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py" \
  --artifact-file "${STATUS_PATH}" \
  --bundle-output "${STATUS_BUNDLE_PATH}" \
  --status-output "${STATUS_BUNDLE_STATUS_PATH}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

bash "${ROOT_DIR}/planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh" \
  --artifact-file "${STATUS_BUNDLE_STATUS_PATH}" \
  --bundle-output "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
  --status-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
status = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

assert bundle["resolved_status_bundle_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), bundle
assert bundle["ready"] is True, bundle
assert bundle["status_verdict"] == "pass", bundle
assert bundle["status_validation_verdict"] == "pass", bundle
assert bundle["bundle_status_verdict"] == "pass", bundle
assert bundle["bundle_status_validation_verdict"] == "pass", bundle
assert bundle["bundle_validation_verdict"] == "pass", bundle

assert status["bundle_status_bundle_output_path"] == str(Path(sys.argv[2]).resolve()), status
assert status["bundle_status_bundle_validation_output_path"] == str(Path(sys.argv[4]).resolve()), status
assert len(status["resolved_guardrail_script_paths"]) >= 1, status
assert status["verdict"] == "pass", status
assert validation["bundle_path"] == str(Path(sys.argv[1]).resolve()), validation
assert validation["verdict"] == "pass", validation
assert status_validation["bundle_status_bundle_status_path"] == str(Path(sys.argv[2]).resolve()), status_validation
assert status_validation["bundle_status_bundle_validation_output_path"] == str(Path(sys.argv[4]).resolve()), status_validation
assert status_validation["resolved_guardrail_script_paths"] == status["resolved_guardrail_script_paths"], status_validation
assert status_validation["verdict"] == "pass", status_validation
PY

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" "${BROKEN_BUNDLE_PATH}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "custom remediation"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if bash "${ROOT_DIR}/planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh" \
  --bundle-file "${BROKEN_BUNDLE_PATH}" \
  --status-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null 2>&1; then
  echo "expected status-bundle-status-bundle gate to fail on broken bundle" >&2
  exit 1
fi

echo "gate plain python compat manifest status bundle status bundle ok"
