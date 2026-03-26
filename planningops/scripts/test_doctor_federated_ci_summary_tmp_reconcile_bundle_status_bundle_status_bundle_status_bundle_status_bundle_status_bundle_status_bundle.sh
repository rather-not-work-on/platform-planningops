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
NEXT_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
NEXT_BUNDLE_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
NEXT_DOCTOR_STATUS_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
NEXT_DOCTOR_STATUS_VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
BROKEN_BUNDLE_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-broken.json"
REPORT_OUTPUT="$TMP_DIR/doctor-status-bundle-status-bundle-status-bundle-status-bundle.txt"
BROKEN_REPORT_OUTPUT="$TMP_DIR/doctor-status-bundle-status-bundle-status-bundle-status-bundle-broken.txt"
NEXT_BUNDLE_REAL="$(python3 - <<'PY' "$NEXT_BUNDLE_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
NEXT_BUNDLE_VALIDATION_REAL="$(python3 - <<'PY' "$NEXT_BUNDLE_VALIDATION_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_REAL="$(python3 - <<'PY' "$NEXT_DOCTOR_STATUS_PATH"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_VALIDATION_REAL="$(python3 - <<'PY' "$NEXT_DOCTOR_STATUS_VALIDATION_PATH"
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
  "run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample",
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
  "reconcile_run_id": "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample",
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

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH" \
  --bundle-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH" \
  --bundle-validation-output "$STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH" \
  --status-output "$DOCTOR_STATUS_PATH" \
  --status-validation-output "$DOCTOR_STATUS_VALIDATION_PATH" \
  --require-pass >/dev/null

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py" --artifact-file "$DOCTOR_STATUS_PATH" --output "$NEXT_BUNDLE_PATH" >/dev/null
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" --bundle-file "$NEXT_BUNDLE_PATH" --output "$NEXT_BUNDLE_VALIDATION_PATH" --strict >/dev/null

python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "$DOCTOR_STATUS_PATH" \
  --bundle-output "$NEXT_BUNDLE_PATH" \
  --bundle-validation-output "$NEXT_BUNDLE_VALIDATION_PATH" \
  --status-output "$NEXT_DOCTOR_STATUS_PATH" \
  --status-validation-output "$NEXT_DOCTOR_STATUS_VALIDATION_PATH" \
  --require-pass >"$REPORT_OUTPUT"

grep -q "source kind: artifact" "$REPORT_OUTPUT"
grep -q "bundle path: ${NEXT_BUNDLE_REAL}" "$REPORT_OUTPUT"
grep -q "bundle validation output path: ${NEXT_BUNDLE_VALIDATION_REAL}" "$REPORT_OUTPUT"
grep -q "status output path: ${DOCTOR_STATUS_REAL}" "$REPORT_OUTPUT"
grep -q "status validation output path: ${DOCTOR_STATUS_VALIDATION_REAL}" "$REPORT_OUTPUT"
grep -q "status validation verdict: pass" "$REPORT_OUTPUT"
grep -q "run_id: reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample" "$REPORT_OUTPUT"
grep -q "reconcile status: healthy" "$REPORT_OUTPUT"
grep -q "check name: loop-guardrails" "$REPORT_OUTPUT"
grep -q "reconcile count: 0" "$REPORT_OUTPUT"
grep -q "reconcile validation verdict: pass" "$REPORT_OUTPUT"
grep -q "bundle validation verdict: pass" "$REPORT_OUTPUT"
grep -q "bundle validation state: fresh" "$REPORT_OUTPUT"
grep -q "ready: True" "$REPORT_OUTPUT"
grep -q "next step: none" "$REPORT_OUTPUT"
grep -q "validation verdict: pass" "$REPORT_OUTPUT"
grep -q "error count: 0" "$REPORT_OUTPUT"

python3 - <<'PY' "$NEXT_BUNDLE_PATH" "$NEXT_BUNDLE_VALIDATION_PATH" "$NEXT_DOCTOR_STATUS_PATH" "$NEXT_DOCTOR_STATUS_VALIDATION_PATH"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
status = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

assert bundle["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample", bundle
assert bundle["reconcile_status"] == "healthy", bundle
assert bundle["check_name"] == "loop-guardrails", bundle
assert bundle["reconcile_count"] == 0, bundle
assert bundle["reconcile_validation_verdict"] == "pass", bundle
assert bundle["bundle_validation_verdict"] == "pass", bundle
assert bundle["bundle_validation_state"] == "fresh", bundle
assert bundle["ready"] is True, bundle
assert bundle["next_step"] == "none", bundle

assert validation["bundle_path"] == str(Path(sys.argv[1]).resolve()), validation
assert validation["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample", validation
assert validation["reconcile_status"] == "healthy", validation
assert validation["check_name"] == "loop-guardrails", validation
assert validation["reconcile_count"] == 0, validation
assert validation["reconcile_validation_verdict"] == "pass", validation
assert validation["bundle_validation_verdict"] == "pass", validation
assert validation["bundle_validation_state"] == "fresh", validation
assert validation["ready"] is True, validation
assert validation["next_step"] == "none", validation
assert validation["verdict"] == "pass", validation

assert status["output_path"] == str(Path(sys.argv[3]).resolve()), status
assert status["status_validation_output_path"] == str(Path(sys.argv[4]).resolve()), status
assert status["run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample", status
assert status["reconcile_status"] == "healthy", status
assert status["check_name"] == "loop-guardrails", status
assert status["reconcile_count"] == 0, status
assert status["reconcile_validation_verdict"] == "pass", status
assert status["bundle_validation_verdict"] == "pass", status
assert status["bundle_validation_state"] == "fresh", status
assert status["ready"] is True, status
assert status["next_step"] == "none", status

assert status_validation["status_path"] == str(Path(sys.argv[3]).resolve()), status_validation
assert status_validation["output_path"] == str(Path(sys.argv[4]).resolve()), status_validation
assert status_validation["status_output_path"] == str(Path(sys.argv[3]).resolve()), status_validation
assert status_validation["status_validation_output_path"] == str(Path(sys.argv[4]).resolve()), status_validation
assert status_validation["status_run_id"] == "reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-doctor-sample", status_validation
assert status_validation["status_reconcile_status"] == "healthy", status_validation
assert status_validation["status_check_name"] == "loop-guardrails", status_validation
assert status_validation["status_reconcile_count"] == 0, status_validation
assert status_validation["status_reconcile_validation_verdict"] == "pass", status_validation
assert status_validation["status_bundle_validation_verdict"] == "pass", status_validation
assert status_validation["status_bundle_validation_state"] == "fresh", status_validation
assert status_validation["status_ready"] is True, status_validation
assert status_validation["status_next_step"] == "none", status_validation
assert status_validation["verdict"] == "pass", status_validation
PY

python3 - <<'PY' "$NEXT_BUNDLE_PATH" "$BROKEN_BUNDLE_PATH"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["bundle_validation_state"] = "stale"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --bundle-file "$BROKEN_BUNDLE_PATH" \
  --bundle-validation-output "$NEXT_BUNDLE_VALIDATION_PATH" \
  --status-output "$NEXT_DOCTOR_STATUS_PATH" \
  --status-validation-output "$NEXT_DOCTOR_STATUS_VALIDATION_PATH" \
  --require-pass >"$BROKEN_REPORT_OUTPUT" 2>&1; then
  echo "expected tmp-summary reconcile bundle status-bundle-status-bundle-status-bundle-status-bundle doctor to fail on broken bundle"
  exit 1
fi

grep -q "source kind: bundle" "$BROKEN_REPORT_OUTPUT"
grep -q "bundle validation state: stale" "$BROKEN_REPORT_OUTPUT"
grep -q "validation verdict: fail" "$BROKEN_REPORT_OUTPUT"

echo "doctor federated ci summary tmp reconcile bundle status bundle status bundle status bundle status bundle ok"
