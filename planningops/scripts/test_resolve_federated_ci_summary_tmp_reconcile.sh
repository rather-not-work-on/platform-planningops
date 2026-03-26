#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPORT_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile.json"
VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-validation.json"
BUNDLE_FROM_REPORT="$TMP_DIR/bundle-from-report.json"
BUNDLE_FROM_VALIDATION="$TMP_DIR/bundle-from-validation.json"
BROKEN_STDERR="$TMP_DIR/broken.stderr"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-resolve-sample",
  "check_name": "loop-guardrails",
  "checkpoint_check_count": 6,
  "summary_check_count": 6,
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
  "reconcile_run_id": "reconcile-resolve-sample",
  "reconcile_status": "healthy",
  "reconcile_restored": false,
  "reconcile_check_name": "loop-guardrails",
  "reconcile_checkpoint_check_count": 6,
  "reconcile_summary_check_count": 6,
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
  --output "$BUNDLE_FROM_REPORT" >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \
  --artifact-file "$VALIDATION_PATH" \
  --output "$BUNDLE_FROM_VALIDATION" >/dev/null

python3 - <<'PY' "$REPORT_PATH" "$VALIDATION_PATH" "$BUNDLE_FROM_REPORT" "$BUNDLE_FROM_VALIDATION"
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1]).resolve()
validation_path = Path(sys.argv[2]).resolve()
bundle_from_report = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
bundle_from_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
report = json.loads(report_path.read_text(encoding="utf-8"))
validation = json.loads(validation_path.read_text(encoding="utf-8"))

for bundle, artifact_path in (
    (bundle_from_report, report_path),
    (bundle_from_validation, validation_path),
):
    assert Path(bundle["artifact_file"]).resolve() == artifact_path, bundle
    assert Path(bundle["reconcile_report_path"]).resolve() == report_path, bundle
    assert Path(bundle["reconcile_validation_report_path"]).resolve() == validation_path, bundle
    assert bundle["run_id"] == "reconcile-resolve-sample", bundle
    assert bundle["reconcile_status"] == "healthy", bundle
    assert bundle["reconcile_check_name"] == "loop-guardrails", bundle
    assert bundle["reconcile_count"] == 0, bundle
    assert bundle["reconcile_report"] == report, bundle
    assert bundle["reconcile_validation_report"] == validation, bundle
PY

python3 - <<'PY' "$VALIDATION_PATH"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["reconcile_run_id"] = "reconcile-resolve-sample-stale"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \
  --artifact-file "$VALIDATION_PATH" \
  --output "$TMP_DIR/broken-bundle.json" >"$TMP_DIR/broken.stdout" 2>"$BROKEN_STDERR"; then
  echo "expected stale reconcile validation bundle resolution to fail" >&2
  exit 1
fi

grep -q "tmp-summary reconcile validation report does not match resolved tmp-summary reconcile report" "$BROKEN_STDERR"

echo "resolve federated ci summary tmp reconcile ok"
