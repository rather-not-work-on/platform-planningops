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
STATUS_BUNDLE_STATUS_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-bundle-status.schema.json"

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
  --bundle-validation-output "${STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE_STATUS_PATH}" "${STATUS_BUNDLE_STATUS_SCHEMA_PATH}" "${STATUS_BUNDLE_PATH}" "${STATUS_BUNDLE_VALIDATION_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
status_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])
bundle_path = Path(sys.argv[4])
bundle_validation_path = Path(sys.argv[5])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(status_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["bundle_status_output_path"] == str(status_path.resolve()), report
assert report["bundle_status_validation_output_path"], report
assert report["bundle_path"] == str(bundle_path.resolve()), report
assert report["resolved_status_bundle_path"] == str(bundle_path.resolve()), report
assert report["bundle_validation_output_path"] == str(bundle_validation_path.resolve()), report
assert len(report["resolved_guardrail_script_paths"]) >= 1, report
assert report["verdict"] == "pass", report
assert report["ready"] is True, report
assert report["next_step"] == "none", report
assert report["bundle_status_verdict"] == "pass", report
assert report["bundle_status_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_PATH}" "${TMP_DIR}/invalid-status-bundle-status.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = "yes"
doc["next_step"] = 3
doc["bundle_validation_verdict"] = "maybe"
doc.pop("resolved_guardrail_script_paths")
doc.pop("bundle_status_output_path")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "${ROOT_DIR}" "${TMP_DIR}/invalid-status-bundle-status.json" "${STATUS_BUNDLE_STATUS_SCHEMA_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
status_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(status_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert errors, report
assert any("$.ready expected type boolean" in item for item in errors), errors
assert any("$.next_step expected type string" in item for item in errors), errors
assert any("$.bundle_validation_verdict invalid enum value: maybe" in item for item in errors), errors
assert any("$.resolved_guardrail_script_paths is required" in item for item in errors), errors
assert any("$.bundle_status_output_path is required" in item for item in errors), errors
PY

echo "validate plain python compat manifest status bundle status contract ok"
