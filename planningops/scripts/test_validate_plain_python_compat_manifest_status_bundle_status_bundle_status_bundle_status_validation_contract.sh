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
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-validation.json"
STATUS_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-validation.schema.json"

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

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS_BUNDLE_STATUS_PATH}" \
  --bundle-output "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
  --status-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
  --bundle-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
  --status-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --bundle-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
  --output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" "${STATUS_SCHEMA_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])
status_path = Path(sys.argv[4])
bundle_validation_path = Path(sys.argv[5])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["output_path"] == str(report_path.resolve()), report
assert report["bundle_status_bundle_status_bundle_status_path"] == str(status_path.resolve()), report
assert report["bundle_status_bundle_status_bundle_output_path"] == str(status_path.resolve()), report
assert report["bundle_status_bundle_status_bundle_validation_output_path"] == str(report_path.resolve()), report
assert report["bundle_validation_output_path"] == str(bundle_validation_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["status_verdict"] == "pass", report
assert report["status_ready"] is True, report
assert report["status_next_step"] == "none", report
assert report["status_validation_verdict"] == "pass", report
assert report["bundle_status_verdict"] == "pass", report
assert report["bundle_status_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" "${TMP_DIR}/invalid-status-bundle-status-bundle-status-bundle-status.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "none"
doc["bundle_validation_output_path"] = str(Path(sys.argv[2]).with_name("missing-validation.json"))
doc["bundle_status_bundle_status_bundle_output_path"] = str(Path(sys.argv[2]).with_name("wrong-status.json"))
doc.pop("bundle_status_bundle_status_bundle_validation_output_path")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "${TMP_DIR}/invalid-status-bundle-status-bundle-status-bundle-status.json" \
  --output "${TMP_DIR}/invalid-status-bundle-status-bundle-status-bundle-status-validation.json" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid plain python compat manifest status bundle status bundle status bundle status"
  exit 1
fi

python3 - <<'PY' "${TMP_DIR}/invalid-status-bundle-status-bundle-status-bundle-status-validation.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("bundle_status_bundle_status_bundle_output_path must match the validated status file path" in item for item in report["errors"]), report
assert any("bundle_status_bundle_status_bundle_validation_output_path must match the validation output path" in item for item in report["errors"]), report
assert any("ready must be true when verdict=pass" in item for item in report["errors"]), report
assert any("next_step must be a non-empty remediation step when ready=false" in item for item in report["errors"]), report
assert any("bundle_validation_output_path must point at an existing bundle-validation report" in item for item in report["errors"]), report
PY

echo "validate plain python compat manifest status bundle status bundle status bundle status validation contract ok"
