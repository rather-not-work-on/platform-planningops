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
STATUS_VALIDATION_SCHEMA_PATH="$ROOT_DIR/schemas/federated-ci-summary-tmp-reconcile-bundle-status-validation.schema.json"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-status-sample",
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
  "reconcile_run_id": "reconcile-bundle-status-sample",
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
  --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" \
  --bundle-file "$BUNDLE_PATH" \
  --validation-report "$BUNDLE_VALIDATION_PATH" \
  --status-output "$STATUS_PATH" \
  --status-validation-output "$STATUS_VALIDATION_PATH" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py" \
  --status-file "$STATUS_PATH" \
  --bundle-file "$BUNDLE_PATH" \
  --bundle-validation-report "$BUNDLE_VALIDATION_PATH" \
  --output "$STATUS_VALIDATION_PATH" \
  --strict

python3 - <<'PY' "$ROOT_DIR" "$STATUS_PATH" "$STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
status_path = Path(sys.argv[2]).resolve()
report_path = Path(sys.argv[3]).resolve()

sys.path.insert(0, str(root_dir / "scripts"))
import validate_plain_python_compat_manifest as mod

status = json.loads(status_path.read_text(encoding="utf-8"))
schema = json.loads((root_dir / "schemas/federated-ci-summary-tmp-reconcile-bundle-status.schema.json").read_text(encoding="utf-8"))
assert not mod.validate_schema(status, schema), status

report = json.loads(report_path.read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["status_path"] == str(status_path), report
assert report["validation_schema_path"] == str((root_dir / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-validation.schema.json").resolve()), report
assert report["status_output_path"] == str(status_path), report
assert report["status_validation_output_path"] == str(report_path), report
assert report["status_check_name"] == "loop-guardrails", report
assert report["status_reconcile_validation_verdict"] == "pass", report
assert report["status_run_id"] == "reconcile-bundle-status-sample", report
assert report["status_reconcile_status"] == "healthy", report
assert report["status_reconcile_count"] == 0, report
assert report["status_bundle_validation_verdict"] == "pass", report
assert report["status_bundle_validation_state"] == "fresh", report
assert report["status_ready"] is True, report
assert report["status_next_step"] == "none", report
PY

python3 - <<'PY' "$ROOT_DIR" "$STATUS_VALIDATION_PATH" "$STATUS_VALIDATION_SCHEMA_PATH"
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
PY

python3 - <<'PY' "$STATUS_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "manual remediation"
doc["output_path"] = str(path.with_name("wrong-status.json"))
doc["bundle_validation_state"] = "stale"
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py" \
  --status-file "$STATUS_PATH" \
  --bundle-file "$BUNDLE_PATH" \
  --bundle-validation-report "$BUNDLE_VALIDATION_PATH" \
  --output "$TMP_DIR/invalid-status-validation.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid tmp-summary reconcile bundle status"
  exit 1
fi

python3 - <<'PY' "$TMP_DIR/invalid-status-validation.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("output_path must match the validated status path" in item for item in report["errors"]), report
assert any("ready must match canonical bundle doctor status" in item for item in report["errors"]), report
assert any("next_step must match canonical bundle doctor status" in item for item in report["errors"]), report
assert any("bundle_validation_state must match canonical bundle doctor status" in item for item in report["errors"]), report
PY

echo "validate federated ci summary tmp reconcile bundle status contract ok"
