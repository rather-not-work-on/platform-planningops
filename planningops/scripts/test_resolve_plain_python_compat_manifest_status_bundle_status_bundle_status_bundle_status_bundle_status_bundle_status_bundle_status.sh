#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_PATH="${TMP_DIR}/plain-python-compat-validation.json"
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
BUNDLE7="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
BUNDLE7_FROM_VALIDATION="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-from-validation.json"
BUNDLE7_SCHEMA="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json"
BROKEN_STATUS6="${TMP_DIR}/broken-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
BROKEN_STATUS6_VALIDATION="${TMP_DIR}/broken-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --validation-output "${VALIDATION_PATH}" \
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

python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "${STATUS6}" \
  --output "${BUNDLE7}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-validation-file "${STATUS6_VALIDATION}" \
  --output "${BUNDLE7_FROM_VALIDATION}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${BUNDLE7}" "${BUNDLE7_FROM_VALIDATION}" "${BUNDLE7_SCHEMA}" "${STATUS6}" "${STATUS6_VALIDATION}" "${BUNDLE6}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
bundle_path = Path(sys.argv[2])
validation_bundle_path = Path(sys.argv[3])
schema_path = Path(sys.argv[4])
status_path = Path(sys.argv[5])
status_validation_path = Path(sys.argv[6])
outer_bundle_path = Path(sys.argv[7])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
validation_bundle = json.loads(validation_bundle_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))

errors = mod.validate_schema(bundle, schema)
assert not errors, errors
errors = mod.validate_schema(validation_bundle, schema)
assert not errors, errors

assert bundle["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"] == str(status_path.resolve()), bundle
assert bundle["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path"] == str(status_validation_path.resolve()), bundle
assert bundle["bundle_path"] == str(outer_bundle_path.resolve()), bundle
assert bundle["status_verdict"] == "pass", bundle
assert bundle["status_validation_verdict"] == "pass", bundle
assert bundle["ready"] is True, bundle
assert bundle["next_step"] == "none", bundle
assert bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] == str(status_path.resolve()), bundle
assert bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] == str(bundle_path.resolve()), bundle
assert bundle["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report"]["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"] == str(status_validation_path.resolve()), bundle
assert bundle["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report"]["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"] == str(status_path.resolve()), bundle
assert validation_bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] == str(validation_bundle_path.resolve()), validation_bundle

bundle_without_output = dict(bundle)
bundle_without_output.pop("resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path")
validation_bundle_without_output = dict(validation_bundle)
validation_bundle_without_output.pop("resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path")
assert bundle_without_output == validation_bundle_without_output, (bundle_without_output, validation_bundle_without_output)
PY

python3 - <<'PY' "${STATUS6}" "${BROKEN_STATUS6}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"] = str(
    Path(sys.argv[2]).with_name("missing-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json").resolve()
)
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "${BROKEN_STATUS6}" >/dev/null 2>&1; then
  echo "expected latest resolved outermost-doctor bundle-status resolver to fail on mismatched bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path" >&2
  exit 1
fi

python3 - <<'PY' "${STATUS6_VALIDATION}" "${BROKEN_STATUS6_VALIDATION}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"] = str(
    Path(sys.argv[2]).with_name("missing-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json").resolve()
)
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-validation-file "${BROKEN_STATUS6_VALIDATION}" >/dev/null 2>&1; then
  echo "expected latest resolved outermost-doctor bundle-status resolver to fail on mismatched bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path" >&2
  exit 1
fi

echo "resolve plain python compat manifest status bundle status bundle status bundle status bundle status bundle status bundle status ok"
