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
STATUS_BUNDLE_REAL="$(python3 - <<'PY' "$STATUS_BUNDLE_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
STATUS_BUNDLE_VALIDATION_REAL="$(python3 - <<'PY' "$STATUS_BUNDLE_VALIDATION_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_REAL="$(python3 - <<'PY' "$DOCTOR_STATUS_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_VALIDATION_REAL="$(python3 - <<'PY' "$DOCTOR_STATUS_VALIDATION_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"

cat >"$REPORT_PATH" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-status-bundle-gate-sample",
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
  "reconcile_run_id": "reconcile-bundle-status-bundle-gate-sample",
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
  --status-validation-output "$STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

output="$("$ROOT_DIR/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh" \
  --artifact-file "$STATUS_PATH" \
  --bundle-output "$STATUS_BUNDLE_PATH" \
  --bundle-validation-output "$STATUS_BUNDLE_VALIDATION_PATH" \
  --status-output "$DOCTOR_STATUS_PATH" \
  --status-validation-output "$DOCTOR_STATUS_VALIDATION_PATH")"
printf '%s\n' "$output" | rg -q "bundle path: ${STATUS_BUNDLE_REAL}"
printf '%s\n' "$output" | rg -q "bundle validation output path: ${STATUS_BUNDLE_VALIDATION_REAL}"
printf '%s\n' "$output" | rg -q "status output path: ${DOCTOR_STATUS_REAL}"
printf '%s\n' "$output" | rg -q "status validation output path: ${DOCTOR_STATUS_VALIDATION_REAL}"
printf '%s\n' "$output" | rg -q "status validation verdict: pass"
printf '%s\n' "$output" | rg -q "run_id: reconcile-bundle-status-bundle-gate-sample"
printf '%s\n' "$output" | rg -q "reconcile status: healthy"
printf '%s\n' "$output" | rg -q "bundle validation verdict: pass"
printf '%s\n' "$output" | rg -q "bundle validation state: fresh"
printf '%s\n' "$output" | rg -q "ready: True"
printf '%s\n' "$output" | rg -q "next step: none"
printf '%s\n' "$output" | rg -q "validation verdict: pass"

python3 - <<'PY' "$STATUS_BUNDLE_PATH"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["bundle_validation_state"] = "stale"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh" \
  --bundle-file "$STATUS_BUNDLE_PATH" \
  --bundle-validation-output "$STATUS_BUNDLE_VALIDATION_PATH" \
  --status-output "$DOCTOR_STATUS_PATH" \
  --status-validation-output "$DOCTOR_STATUS_VALIDATION_PATH" 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected tmp-summary reconcile bundle status-bundle gate to fail on stale bundle validation state"
  exit 1
fi

printf '%s\n' "$output" | rg -q "bundle validation state: stale"
printf '%s\n' "$output" | rg -q "validation verdict: fail"

echo "gate federated ci summary tmp reconcile bundle status bundle ok"
