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
STATUS_VALIDATION_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/plain-python-compat-manifest-status-validation.schema.json"

python3 "${ROOT_DIR}/planningops/scripts/doctor_plain_python_compat_manifest.py" \
  --validation-output "${VALIDATION_PATH}" \
  --status-output "${STATUS_PATH}" \
  --status-validation-output "${STATUS_VALIDATION_PATH}" \
  --status-bundle-output "${STATUS_BUNDLE_PATH}" \
  --status-bundle-validation-output "${STATUS_BUNDLE_VALIDATION_PATH}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status.py" \
  --status-file "${STATUS_PATH}" \
  --output "${STATUS_VALIDATION_PATH}" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_VALIDATION_PATH}" "${STATUS_VALIDATION_SCHEMA_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["output_path"] == str(report_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["status_validation_output_path"] == str(report_path.resolve()), report
assert report["status_verdict"] == "pass", report
assert report["status_ready"] is True, report
assert report["status_next_step"] == "none", report
assert report["status_loop_guardrails_step_count"] == report["canonical_loop_guardrails_step_count"], report
assert len(report["resolved_guardrail_script_paths"]) >= 1, report
PY

python3 - <<'PY' "${STATUS_PATH}" "${TMP_DIR}/invalid-status.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "none"
doc["resolved_loop_guardrails_chain"] = doc["resolved_loop_guardrails_chain"][:-1]
doc.pop("resolved_guardrail_script_paths")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest_status.py" \
  --status-file "${TMP_DIR}/invalid-status.json" \
  --output "${TMP_DIR}/invalid-status-validation.json" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid plain python compat manifest status"
  exit 1
fi

python3 - <<'PY' "${TMP_DIR}/invalid-status-validation.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("status_output_path must match the validated status file path" in item for item in report["errors"]), report
assert any("status_validation_output_path must match the validation output path" in item for item in report["errors"]), report
assert any("ready must be true when verdict=pass" in item for item in report["errors"]), report
assert any("next_step must be a non-empty remediation step when ready=false" in item for item in report["errors"]), report
assert any("resolved_guardrail_script_paths must be a non-empty array" in item for item in report["errors"]), report
assert any("resolved_loop_guardrails_chain ids must preserve loop_guardrails_chain order" in item for item in report["errors"]), report
assert any("resolved_loop_guardrails_chain ids must match canonical manifest resolution" in item for item in report["errors"]), report
PY

echo "validate plain python compat manifest status validation contract ok"
