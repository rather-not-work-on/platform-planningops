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
STATUS_BUNDLE_STATUS_BUNDLE_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-validation.schema.json"

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

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle.py" \
  --bundle-file "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
  --output "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_SCHEMA_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])
bundle_path = Path(sys.argv[4])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["output_path"] == str(report_path.resolve()), report
assert report["bundle_path"] == str(bundle_path.resolve()), report
assert len(report["resolved_guardrail_script_paths"]) >= 1, report
assert report["verdict"] == "pass", report
assert report["bundle_ready"] is True, report
assert report["bundle_next_step"] == "none", report
assert report["status_verdict"] == "pass", report
assert report["status_validation_verdict"] == "pass", report
assert report["bundle_status_verdict"] == "pass", report
assert report["bundle_status_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_BUNDLE_PATH}" "${TMP_DIR}/invalid-status-bundle-status-bundle.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "custom remediation"
doc["resolved_guardrail_script_paths"] = []
doc["resolved_status_bundle_path"] = str(Path(sys.argv[2]).with_name("wrong-status-bundle.json").resolve())
doc["resolved_status_bundle_status_bundle_path"] = str(Path(sys.argv[2]).with_name("wrong-status-bundle-status-bundle.json").resolve())
doc["bundle_status_validation_report"]["bundle_status_output_path"] = str(
    Path(sys.argv[2]).with_name("wrong-status-bundle-status.json").resolve()
)
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle.py" \
  --bundle-file "${TMP_DIR}/invalid-status-bundle-status-bundle.json" \
  --output "${TMP_DIR}/invalid-status-bundle-status-bundle-validation.json" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid plain python compat manifest status-bundle-status bundle"
  exit 1
fi

python3 - <<'PY' "${TMP_DIR}/invalid-status-bundle-status-bundle-validation.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("resolved_status_bundle_status_bundle_path must match the validated bundle file path" in item for item in report["errors"]), report
assert any("resolved_guardrail_script_paths must be a non-empty array" in item for item in report["errors"]), report
assert any("ready must match bundle_status_report.ready" in item for item in report["errors"]), report
assert any("next_step must match bundle_status_report.next_step" in item for item in report["errors"]), report
assert any("bundle_status_validation_report.bundle_status_output_path must match bundle_status_path" in item for item in report["errors"]), report
assert any("bundle must match canonical status-bundle-status bundle resolution" in item for item in report["errors"]), report
PY

echo "validate plain python compat manifest status bundle status bundle validation contract ok"
