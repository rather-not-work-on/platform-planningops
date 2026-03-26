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
RESOLVED_FROM_STATUS="$TMP_DIR/resolved-from-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
RESOLVED_FROM_STATUS_VALIDATION="$TMP_DIR/resolved-from-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
BROKEN_STDERR="$TMP_DIR/broken.stderr"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample",
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
  "reconcile_run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample",
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

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$NEXT_DOCTOR_STATUS_PATH" \
  --output "$RESOLVED_FROM_STATUS" >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$NEXT_DOCTOR_STATUS_VALIDATION_PATH" \
  --output "$RESOLVED_FROM_STATUS_VALIDATION" >/dev/null

python3 - <<'PY' "$NEXT_DOCTOR_STATUS_PATH" "$NEXT_DOCTOR_STATUS_VALIDATION_PATH" "$RESOLVED_FROM_STATUS" "$RESOLVED_FROM_STATUS_VALIDATION"
import json
import sys
from pathlib import Path

status_path = Path(sys.argv[1]).resolve()
status_validation_path = Path(sys.argv[2]).resolve()
bundle_from_status = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
bundle_from_status_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
status = json.loads(status_path.read_text(encoding="utf-8"))
status_validation = json.loads(status_validation_path.read_text(encoding="utf-8"))

for bundle, artifact_path in (
    (bundle_from_status, status_path),
    (bundle_from_status_validation, status_validation_path),
):
    assert Path(bundle["artifact_file"]).resolve() == artifact_path, bundle
    assert Path(bundle["status_path"]).resolve() == status_path, bundle
    assert Path(bundle["status_validation_path"]).resolve() == status_validation_path, bundle
    assert bundle["bundle_path"] == status["bundle_path"], bundle
    assert bundle["bundle_validation_report_path"] == status["validation_report_path"], bundle
    assert bundle["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample", bundle
    assert bundle["reconcile_status"] == "healthy", bundle
    assert bundle["check_name"] == "loop-guardrails", bundle
    assert bundle["reconcile_count"] == 0, bundle
    assert bundle["reconcile_validation_verdict"] == "pass", bundle
    assert bundle["bundle_validation_verdict"] == "pass", bundle
    assert bundle["bundle_validation_state"] == "fresh", bundle
    assert bundle["ready"] is True, bundle
    assert bundle["next_step"] == "none", bundle
    assert bundle["status_report"] == status, bundle
    assert bundle["status_validation_report"] == status_validation, bundle
PY

python3 - <<'PY' "$NEXT_DOCTOR_STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["status_run_id"] = "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample-stale"
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$NEXT_DOCTOR_STATUS_VALIDATION_PATH" \
  --output "$TMP_DIR/broken-bundle.json" >"$TMP_DIR/broken.stdout" 2>"$BROKEN_STDERR"; then
  echo "expected stale tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status-validation resolution to fail" >&2
  exit 1
fi

grep -q "tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status-validation report must match status run_id" "$BROKEN_STDERR"

echo "resolve federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle status ok"
