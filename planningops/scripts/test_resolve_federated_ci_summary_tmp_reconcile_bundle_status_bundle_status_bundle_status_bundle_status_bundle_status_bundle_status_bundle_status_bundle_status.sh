#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
RESOLVED_FROM_STATUS="$TMP_DIR/resolved-from-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
RESOLVED_FROM_STATUS_VALIDATION="$TMP_DIR/resolved-from-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
BROKEN_STDERR="$TMP_DIR/broken.stderr"

cat >"$STATUS_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "output_path": "__STATUS_PATH__",
  "status_validation_output_path": "__STATUS_VALIDATION_PATH__",
  "bundle_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json",
  "validation_report_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json",
  "bundle_present": true,
  "validation_present": true,
  "artifact_file": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json",
  "status_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json",
  "status_validation_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json",
  "nested_bundle_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json",
  "nested_bundle_validation_report_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json",
  "run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample",
  "reconcile_status": "healthy",
  "check_name": "loop-guardrails",
  "reconcile_count": 0,
  "reconcile_validation_verdict": "pass",
  "bundle_validation_verdict": "pass",
  "bundle_validation_state": "fresh",
  "ready": true,
  "next_step": "none"
}
JSON

python3 - <<'PY' "$STATUS_PATH" "$STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

status_path = Path(sys.argv[1]).resolve()
status_validation_path = Path(sys.argv[2]).resolve()
doc = json.loads(status_path.read_text(encoding="utf-8"))
doc["output_path"] = str(status_path)
doc["status_validation_output_path"] = str(status_validation_path)
status_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat >"$STATUS_VALIDATION_PATH" <<'JSON'
{
  "status_path": "__STATUS_PATH__",
  "bundle_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json",
  "bundle_validation_report_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json",
  "schema_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json",
  "validation_schema_path": "/tmp/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json",
  "output_path": "__STATUS_VALIDATION_PATH__",
  "generated_at_utc": "2026-03-22T00:01:06+00:00",
  "verdict": "pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "status_generated_at_utc": "2026-03-22T00:01:05+00:00",
  "status_output_path": "__STATUS_PATH__",
  "status_validation_output_path": "__STATUS_VALIDATION_PATH__",
  "status_run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample",
  "status_reconcile_status": "healthy",
  "status_check_name": "loop-guardrails",
  "status_reconcile_count": 0,
  "status_reconcile_validation_verdict": "pass",
  "status_bundle_validation_verdict": "pass",
  "status_bundle_validation_state": "fresh",
  "status_ready": true,
  "status_next_step": "none"
}
JSON

python3 - <<'PY' "$STATUS_PATH" "$STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

status_path = Path(sys.argv[1]).resolve()
status_validation_path = Path(sys.argv[2]).resolve()
doc = json.loads(status_validation_path.read_text(encoding="utf-8"))
doc["status_path"] = str(status_path)
doc["status_output_path"] = str(status_path)
doc["status_validation_output_path"] = str(status_validation_path)
doc["output_path"] = str(status_validation_path)
status_validation_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$STATUS_PATH" \
  --output "$RESOLVED_FROM_STATUS" >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$STATUS_VALIDATION_PATH" \
  --output "$RESOLVED_FROM_STATUS_VALIDATION" >/dev/null

python3 - <<'PY' "$STATUS_PATH" "$STATUS_VALIDATION_PATH" "$RESOLVED_FROM_STATUS" "$RESOLVED_FROM_STATUS_VALIDATION"
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
    assert bundle["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample", bundle
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

python3 - <<'PY' "$STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["status_run_id"] = "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-resolve-sample-stale"
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --artifact-file "$STATUS_VALIDATION_PATH" \
  --output "$TMP_DIR/broken-bundle.json" >"$TMP_DIR/broken.stdout" 2>"$BROKEN_STDERR"; then
  echo "expected stale tmp-summary reconcile outer bundle doctor status-validation resolution to fail" >&2
  exit 1
fi

grep -q "tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status-validation report must match status run_id" "$BROKEN_STDERR"

echo "resolve federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status ok"
