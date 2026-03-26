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
STATUS_VALIDATION_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"

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
  --bundle-validation-output "${BUNDLE6_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "${STATUS6}" \
  --output "${STATUS6_VALIDATION}" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${STATUS6_VALIDATION}" "${STATUS_VALIDATION_SCHEMA_PATH}" "${STATUS6}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])
status_path = Path(sys.argv[4])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["output_path"] == str(report_path.resolve()), report
assert report["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"] == str(status_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["status_ready"] is True, report
assert report["status_next_step"] == "none", report
assert report["status_verdict"] == "pass", report
assert report["status_validation_verdict"] == "pass", report
assert report["bundle_status_verdict"] == "pass", report
assert report["bundle_status_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS6}" "${TMP_DIR}/invalid-status-source.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"] = str(
    Path(sys.argv[2]).with_name("wrong-status-validation.json").resolve()
)
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "${TMP_DIR}/invalid-status-source.json" \
  --output "${TMP_DIR}/invalid-status-validation-report.json" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid plain python compat manifest status bundle status bundle status bundle status bundle status bundle status bundle status validation" >&2
  exit 1
fi

python3 - <<'PY' "${TMP_DIR}/invalid-status-validation-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path must match the validation output path" in item for item in report["errors"]), report
PY

echo "validate plain python compat manifest status bundle status bundle status bundle status bundle status bundle status bundle status validation contract ok"
