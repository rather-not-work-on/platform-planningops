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
INVALID_REPORT="$TMP_DIR/invalid-status-validation.json"

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
  --strict

python3 - <<'PY2' "$OUTER_STATUS_PATH" "$OUTER_STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

def canonical(path_str: str) -> str:
    return str(Path(path_str).resolve())

status = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert canonical(status["output_path"]) == canonical(sys.argv[1]), status
assert canonical(status["status_validation_output_path"]) == canonical(sys.argv[2]), status
assert status["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validator-sample", status
assert status["reconcile_status"] == "healthy", status
assert status["check_name"] == "loop-guardrails", status
assert status["reconcile_count"] == 0, status
assert status["reconcile_validation_verdict"] == "pass", status
assert status["bundle_validation_verdict"] == "pass", status
assert status["bundle_validation_state"] == "fresh", status
assert status["ready"] is True, status
assert status["next_step"] == "none", status

assert report["verdict"] == "pass", report
assert canonical(report["status_path"]) == canonical(sys.argv[1]), report
assert canonical(report["status_output_path"]) == canonical(sys.argv[1]), report
assert canonical(report["status_validation_output_path"]) == canonical(sys.argv[2]), report
assert report["status_run_id"] == status["run_id"], report
assert report["status_reconcile_status"] == "healthy", report
assert report["status_check_name"] == "loop-guardrails", report
assert report["status_reconcile_count"] == 0, report
assert report["status_reconcile_validation_verdict"] == "pass", report
assert report["status_bundle_validation_verdict"] == "pass", report
assert report["status_bundle_validation_state"] == "fresh", report
assert report["status_ready"] is True, report
assert report["status_next_step"] == "none", report
PY2

python3 - <<'PY2' "$OUTER_STATUS_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "manual remediation"
doc["output_path"] = str(path.with_name("wrong-status.json"))
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY2

set +e
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "$OUTER_STATUS_PATH" \
  --bundle-file "$OUTER_BUNDLE_PATH" \
  --bundle-validation-report "$OUTER_BUNDLE_VALIDATION_PATH" \
  --output "$INVALID_REPORT" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid outer tmp-summary reconcile bundle doctor status"
  exit 1
fi

python3 - <<'PY2' "$INVALID_REPORT"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("output_path must match the validated status path" in item for item in report["errors"]), report
assert any("ready must match canonical status-bundle-status bundle status bundle status bundle status doctor status" in item for item in report["errors"]), report
assert any("next_step must match canonical status-bundle-status bundle status bundle status bundle status doctor status" in item for item in report["errors"]), report
PY2

echo "validate federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle status bundle status contract ok"
