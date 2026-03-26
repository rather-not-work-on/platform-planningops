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
STATUS_BUNDLE_STATUS_BUNDLE_FROM_VALIDATION_PATH="${TMP_DIR}/plain-python-compat-status-bundle-status-bundle-from-validation.json"
BUNDLE_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle.schema.json"
BROKEN_STATUS_PATH="${TMP_DIR}/broken-status-bundle-status.json"
BROKEN_STATUS_VALIDATION_PATH="${TMP_DIR}/broken-status-bundle-status-validation.json"

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

python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py" \
  --artifact-file "${STATUS_BUNDLE_STATUS_PATH}" \
  --output "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py" \
  --status-validation-file "${STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
  --output "${STATUS_BUNDLE_STATUS_BUNDLE_FROM_VALIDATION_PATH}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_FROM_VALIDATION_PATH}" "${BUNDLE_SCHEMA_PATH}" "${STATUS_BUNDLE_STATUS_PATH}" "${STATUS_BUNDLE_STATUS_VALIDATION_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
bundle_path = Path(sys.argv[2])
validation_bundle_path = Path(sys.argv[3])
schema_path = Path(sys.argv[4])
status_path = Path(sys.argv[5])
status_validation_path = Path(sys.argv[6])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
validation_bundle = json.loads(validation_bundle_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))

errors = mod.validate_schema(bundle, schema)
assert not errors, errors
errors = mod.validate_schema(validation_bundle, schema)
assert not errors, errors

assert bundle["bundle_status_path"] == str(status_path.resolve()), bundle
assert bundle["bundle_status_validation_path"] == str(status_validation_path.resolve()), bundle
assert bundle["status_verdict"] == "pass", bundle
assert bundle["status_validation_verdict"] == "pass", bundle
assert bundle["ready"] is True, bundle
assert bundle["next_step"] == "none", bundle
assert bundle["resolved_guardrail_script_paths"] == bundle["bundle_status_report"]["resolved_guardrail_script_paths"], bundle
assert bundle["resolved_guardrail_script_paths"] == bundle["bundle_status_validation_report"]["resolved_guardrail_script_paths"], bundle
assert bundle["resolved_status_bundle_status_bundle_path"] == str(bundle_path.resolve()), bundle
assert bundle["bundle_status_report"]["bundle_status_validation_output_path"] == str(status_validation_path.resolve()), bundle
assert bundle["bundle_status_validation_report"]["bundle_status_output_path"] == str(status_path.resolve()), bundle
assert validation_bundle["resolved_status_bundle_status_bundle_path"] == str(validation_bundle_path.resolve()), validation_bundle

bundle_without_output = dict(bundle)
bundle_without_output.pop("resolved_status_bundle_status_bundle_path")
validation_bundle_without_output = dict(validation_bundle)
validation_bundle_without_output.pop("resolved_status_bundle_status_bundle_path")
assert bundle_without_output == validation_bundle_without_output, (bundle_without_output, validation_bundle_without_output)
PY

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_PATH}" "${BROKEN_STATUS_PATH}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["bundle_status_validation_output_path"] = str(Path(sys.argv[2]).with_name("missing-status-bundle-status-validation.json").resolve())
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py" \
  --artifact-file "${BROKEN_STATUS_PATH}" >/dev/null 2>&1; then
  echo "expected status-bundle-status resolver to fail on mismatched bundle_status_validation_output_path" >&2
  exit 1
fi

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_VALIDATION_PATH}" "${BROKEN_STATUS_VALIDATION_PATH}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["resolved_guardrail_script_paths"] = []
doc["bundle_status_output_path"] = str(Path(sys.argv[2]).with_name("missing-status-bundle-status.json").resolve())
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py" \
  --status-validation-file "${BROKEN_STATUS_VALIDATION_PATH}" >/dev/null 2>&1; then
  echo "expected status-bundle-status resolver to fail on mismatched bundle_status_output_path" >&2
  exit 1
fi

echo "resolve plain python compat manifest status bundle status ok"
