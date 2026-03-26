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
DOCTOR_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json"
DOCTOR_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json"
DOCTOR_STATUS_BUNDLE_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json"
DOCTOR_STATUS_BUNDLE_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"
NEXT_DOCTOR_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"
NEXT_DOCTOR_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
RESOLVED_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
RESOLVED_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
OUTER_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
OUTER_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
OUTER_RESOLVED_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
OUTER_RESOLVED_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
CONFLICT_BUNDLE="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-conflict.json"
CONFLICT_VALIDATION="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-conflict-validation.json"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validator-sample",
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
  "reconcile_run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validator-sample",
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

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \
  --artifact-file "$REPORT_PATH" \
  --output "$BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \
  --bundle-file "$BUNDLE_PATH" \
  --output "$BUNDLE_VALIDATION_PATH" \
  --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" \
  --bundle-file "$BUNDLE_PATH" \
  --validation-report "$BUNDLE_VALIDATION_PATH" \
  --status-output "$STATUS_PATH" \
  --status-validation-output "$STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py" \
  --artifact-file "$STATUS_PATH" \
  --output "$STATUS_BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \
  --bundle-file "$STATUS_BUNDLE_PATH" \
  --output "$STATUS_BUNDLE_VALIDATION_PATH" \
  --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \
  --artifact-file "$STATUS_PATH" \
  --bundle-output "$STATUS_BUNDLE_PATH" \
  --bundle-validation-output "$STATUS_BUNDLE_VALIDATION_PATH" \
  --status-output "$DOCTOR_STATUS_PATH" \
  --status-validation-output "$DOCTOR_STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py" \
  --artifact-file "$DOCTOR_STATUS_PATH" \
  --output "$STATUS_BUNDLE_STATUS_BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \
  --bundle-file "$STATUS_BUNDLE_STATUS_BUNDLE_PATH" \
  --output "$STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" \
  --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \
  --artifact-file "$DOCTOR_STATUS_PATH" \
  --bundle-output "$STATUS_BUNDLE_STATUS_BUNDLE_PATH" \
  --bundle-validation-output "$STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" \
  --status-output "$DOCTOR_STATUS_BUNDLE_STATUS_PATH" \
  --status-validation-output "$DOCTOR_STATUS_BUNDLE_STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$DOCTOR_STATUS_BUNDLE_STATUS_PATH" \
  --output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
  --bundle-file "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" \
  --output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" \
  --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "$DOCTOR_STATUS_BUNDLE_STATUS_PATH" \
  --bundle-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" \
  --bundle-validation-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" \
  --status-output "$NEXT_DOCTOR_STATUS_PATH" \
  --status-validation-output "$NEXT_DOCTOR_STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$NEXT_DOCTOR_STATUS_PATH" \
  --output "$RESOLVED_BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --bundle-file "$RESOLVED_BUNDLE_PATH" \
  --output "$RESOLVED_BUNDLE_VALIDATION_PATH" \
  --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "$NEXT_DOCTOR_STATUS_PATH" \
  --bundle-output "$RESOLVED_BUNDLE_PATH" \
  --bundle-validation-output "$RESOLVED_BUNDLE_VALIDATION_PATH" \
  --status-output "$OUTER_STATUS_PATH" \
  --status-validation-output "$OUTER_STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$OUTER_STATUS_PATH" \
  --output "$OUTER_RESOLVED_BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --bundle-file "$OUTER_RESOLVED_BUNDLE_PATH" \
  --output "$OUTER_RESOLVED_BUNDLE_VALIDATION_PATH" \
  --strict

python3 - <<'PY' "$OUTER_RESOLVED_BUNDLE_PATH" "$OUTER_RESOLVED_BUNDLE_VALIDATION_PATH"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert report["verdict"] == "pass", report
assert Path(report["bundle_path"]).resolve() == Path(sys.argv[1]).resolve(), report
assert report["artifact_file"] == bundle["artifact_file"], report
assert report["status_path"] == bundle["status_path"], report
assert report["status_validation_path"] == bundle["status_validation_path"], report
assert report["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validator-sample", report
assert report["reconcile_status"] == "healthy", report
assert report["check_name"] == "loop-guardrails", report
assert report["reconcile_count"] == 0, report
assert report["reconcile_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
assert report["bundle_validation_state"] == "fresh", report
assert report["ready"] is True, report
assert report["next_step"] == "none", report
assert report["error_count"] == 0, report
PY

python3 - <<'PY' "$OUTER_RESOLVED_BUNDLE_PATH" "$CONFLICT_BUNDLE"
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
doc = json.loads(source.read_text(encoding="utf-8"))
doc["bundle_validation_state"] = "stale"
target.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --bundle-file "$CONFLICT_BUNDLE" \
  --output "$CONFLICT_VALIDATION" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validator to fail on drifted bundle_validation_state"
  exit 1
fi

python3 - <<'PY' "$CONFLICT_VALIDATION"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any(
    "bundle_validation_state must match status_report.bundle_validation_state" in error
    or "bundle does not match canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle resolution" in error
    for error in report["errors"]
), report
PY

echo "validate federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle ok"
