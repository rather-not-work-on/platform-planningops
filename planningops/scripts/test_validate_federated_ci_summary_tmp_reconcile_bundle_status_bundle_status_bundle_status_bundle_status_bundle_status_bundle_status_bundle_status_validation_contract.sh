#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
SCHEMA_PATH="$ROOT_DIR/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"

cat >"$STATUS_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:12:00+00:00",
  "output_path": "__STATUS_PATH__",
  "status_validation_output_path": "__VALIDATION_PATH__",
  "bundle_path": "/tmp/bundle.json",
  "validation_report_path": "/tmp/bundle-validation.json",
  "bundle_present": true,
  "validation_present": true,
  "artifact_file": "/tmp/status-bundle-status-bundle-status.json",
  "status_path": "/tmp/status-bundle-status-bundle-status.json",
  "status_validation_path": "/tmp/status-bundle-status-bundle-status-validation.json",
  "nested_bundle_path": "/tmp/resolved-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json",
  "nested_bundle_validation_report_path": "/tmp/resolved-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json",
  "run_id": "bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation-sample",
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

python3 - <<'PY' "$STATUS_PATH" "$VALIDATION_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["output_path"] = str(path)
doc["status_validation_output_path"] = str(Path(sys.argv[2]).resolve())
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat >"$VALIDATION_PATH" <<'JSON'
{
  "status_path": "__STATUS_PATH__",
  "bundle_path": "/tmp/bundle.json",
  "bundle_validation_report_path": "/tmp/bundle-validation.json",
  "schema_path": "/tmp/status-schema.json",
  "validation_schema_path": "__SCHEMA_PATH__",
  "output_path": "__VALIDATION_PATH__",
  "generated_at_utc": "2026-03-22T00:12:01+00:00",
  "verdict": "pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "status_generated_at_utc": "2026-03-22T00:12:00+00:00",
  "status_output_path": "__STATUS_PATH__",
  "status_validation_output_path": "__VALIDATION_PATH__",
  "status_run_id": "bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation-sample",
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

python3 - <<'PY' "$VALIDATION_PATH" "$STATUS_PATH" "$SCHEMA_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["status_path"] = str(Path(sys.argv[2]).resolve())
doc["status_output_path"] = str(Path(sys.argv[2]).resolve())
doc["validation_schema_path"] = str(Path(sys.argv[3]).resolve())
doc["output_path"] = str(path)
doc["status_validation_output_path"] = str(path)
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "$ROOT_DIR" "$VALIDATION_PATH" "$SCHEMA_PATH"
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

python3 - <<'PY' "$VALIDATION_PATH"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["status_validation_output_path"] = ""
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 - <<'PY' "$ROOT_DIR" "$VALIDATION_PATH" "$SCHEMA_PATH"
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
PY
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "expected broken status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status validation report to fail schema validation"
  exit 1
fi

echo "validate federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle status validation contract ok"
