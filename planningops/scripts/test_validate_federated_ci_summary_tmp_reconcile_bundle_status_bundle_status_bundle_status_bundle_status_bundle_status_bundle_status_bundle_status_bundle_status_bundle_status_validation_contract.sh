#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPORT_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile.json"
VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-validation.json"
BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle.json"
BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-validation.json"
STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status.json"
STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-validation.json"
STATUS_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json"
STATUS_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-validation.json"
STATUS_BUNDLE_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json"
STATUS_BUNDLE_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"
DOCTOR_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"
DOCTOR_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
OUTER_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
OUTER_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
OUTER_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
OUTER_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
SCHEMA_PATH="$ROOT_DIR/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validator-sample",
  "check_name": "loop-guardrails",
  "checkpoint_check_count": 7,
  "summary_check_count": 7,
  "restored": false,
  "status": "healthy",
  "reasons": [],
  "reconcile_count": 0,
  "restored_check_names": []
}
JSON

python3 - <<'PY' "$REPORT_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["output_path"] = str(path)
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat >"$VALIDATION_PATH" <<'JSON'
{
  "reconcile_report_path": "__REPORT_PATH__",
  "schema_path": "/tmp/federated-ci-summary-tmp-reconcile.schema.json",
  "output_path": "__VALIDATION_PATH__",
  "generated_at_utc": "2026-03-22T00:01:06+00:00",
  "verdict": "pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "reconcile_generated_at_utc": "2026-03-22T00:01:05+00:00",
  "reconcile_run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validator-sample",
  "reconcile_status": "healthy",
  "reconcile_restored": false,
  "reconcile_check_name": "loop-guardrails",
  "reconcile_checkpoint_check_count": 7,
  "reconcile_summary_check_count": 7,
  "reconcile_count": 0,
  "reconcile_restored_check_names": []
}
JSON

python3 - <<'PY' "$VALIDATION_PATH" "$REPORT_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["reconcile_report_path"] = str(Path(sys.argv[2]).resolve())
doc["output_path"] = str(path)
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile.py" --artifact-file "$REPORT_PATH" --output "$BUNDLE_PATH" >/dev/null
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" --bundle-file "$BUNDLE_PATH" --output "$BUNDLE_VALIDATION_PATH" --strict >/dev/null
python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" --bundle-file "$BUNDLE_PATH" --validation-report "$BUNDLE_VALIDATION_PATH" --status-output "$STATUS_PATH" --status-validation-output "$STATUS_VALIDATION_PATH" --require-pass >/dev/null
python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py" --artifact-file "$STATUS_PATH" --output "$STATUS_BUNDLE_PATH" >/dev/null
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" --bundle-file "$STATUS_BUNDLE_PATH" --output "$STATUS_BUNDLE_VALIDATION_PATH" --strict >/dev/null
python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" --artifact-file "$STATUS_PATH" --bundle-output "$STATUS_BUNDLE_PATH" --bundle-validation-output "$STATUS_BUNDLE_VALIDATION_PATH" --status-output "$STATUS_BUNDLE_STATUS_PATH" --status-validation-output "$STATUS_BUNDLE_STATUS_VALIDATION_PATH" --require-pass >/dev/null
python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py" --artifact-file "$STATUS_BUNDLE_STATUS_PATH" --output "$STATUS_BUNDLE_STATUS_BUNDLE_PATH" >/dev/null
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" --bundle-file "$STATUS_BUNDLE_STATUS_BUNDLE_PATH" --output "$STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" --strict >/dev/null
python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" --artifact-file "$STATUS_BUNDLE_STATUS_PATH" --bundle-output "$STATUS_BUNDLE_STATUS_BUNDLE_PATH" --bundle-validation-output "$STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" --status-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH" --status-validation-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH" --require-pass >/dev/null
python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py" --artifact-file "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH" --output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" >/dev/null
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" --bundle-file "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" --output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" --strict >/dev/null
python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" --artifact-file "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH" --bundle-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" --bundle-validation-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" --status-output "$DOCTOR_STATUS_PATH" --status-validation-output "$DOCTOR_STATUS_VALIDATION_PATH" --require-pass >/dev/null
python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py" --artifact-file "$DOCTOR_STATUS_PATH" --output "$OUTER_BUNDLE_PATH" >/dev/null
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" --bundle-file "$OUTER_BUNDLE_PATH" --output "$OUTER_BUNDLE_VALIDATION_PATH" --strict >/dev/null
python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "$DOCTOR_STATUS_PATH" \
  --bundle-output "$OUTER_BUNDLE_PATH" \
  --bundle-validation-output "$OUTER_BUNDLE_VALIDATION_PATH" \
  --status-output "$OUTER_STATUS_PATH" \
  --status-validation-output "$OUTER_STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "$OUTER_STATUS_PATH" \
  --bundle-file "$OUTER_BUNDLE_PATH" \
  --bundle-validation-report "$OUTER_BUNDLE_VALIDATION_PATH" \
  --output "$OUTER_STATUS_VALIDATION_PATH" \
  --strict >/dev/null

python3 - <<'PY2' "$ROOT_DIR" "$OUTER_STATUS_VALIDATION_PATH" "$SCHEMA_PATH"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2]).resolve()
schema_path = Path(sys.argv[3]).resolve()

sys.path.insert(0, str(root_dir / "scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
PY2

python3 - <<'PY2' "$OUTER_STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["status_validation_output_path"] = ""
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY2

set +e
python3 - <<'PY2' "$ROOT_DIR" "$OUTER_STATUS_VALIDATION_PATH" "$SCHEMA_PATH"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2]).resolve()
schema_path = Path(sys.argv[3]).resolve()

sys.path.insert(0, str(root_dir / "scripts"))
import validate_plain_python_compat_manifest as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
if not errors:
    raise SystemExit(1)
PY2
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "expected broken outer tmp-summary reconcile bundle status validation report to fail schema validation"
  exit 1
fi

echo "validate federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle status bundle status validation contract ok"
