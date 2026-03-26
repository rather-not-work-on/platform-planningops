#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPORT_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile.json"
VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-validation.json"
BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle.json"
BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-validation.json"
CONFLICT_BUNDLE="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-conflict.json"
CONFLICT_VALIDATION="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-conflict-validation.json"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-validator-sample",
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
  "reconcile_run_id": "reconcile-bundle-validator-sample",
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
  --output "$BUNDLE_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \
  --bundle-file "$BUNDLE_PATH" \
  --output "$BUNDLE_VALIDATION_PATH" \
  --strict

python3 - <<'PY' "$BUNDLE_PATH" "$BUNDLE_VALIDATION_PATH"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert report["verdict"] == "pass", report
assert Path(report["bundle_path"]).resolve() == Path(sys.argv[1]).resolve(), report
assert report["artifact_file"] == bundle["artifact_file"], report
assert report["run_id"] == "reconcile-bundle-validator-sample", report
assert report["reconcile_status"] == "healthy", report
assert report["reconcile_check_name"] == "loop-guardrails", report
assert report["reconcile_count"] == 0, report
assert report["reconcile_validation_verdict"] == "pass", report
assert report["error_count"] == 0, report
PY

python3 - <<'PY' "$BUNDLE_PATH" "$CONFLICT_BUNDLE"
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
doc = json.loads(source.read_text(encoding="utf-8"))
doc["reconcile_count"] = 2
target.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \
  --bundle-file "$CONFLICT_BUNDLE" \
  --output "$CONFLICT_VALIDATION" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected tmp-summary reconcile bundle validator to fail on inconsistent reconcile_count"
  exit 1
fi

python3 - <<'PY' "$CONFLICT_VALIDATION"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any(
    "reconcile_count must match reconcile_report.reconcile_count" in error
    or "bundle does not match canonical tmp-summary reconcile resolution" in error
    for error in report["errors"]
), report
PY

echo "validate federated ci summary tmp reconcile bundle ok"
