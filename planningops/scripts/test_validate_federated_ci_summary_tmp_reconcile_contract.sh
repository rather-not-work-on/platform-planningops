#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER_PATH="$ROOT_DIR/scripts/federation/reconcile_federated_ci_summary_tmp.py"
VALIDATOR_PATH="$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile.py"
SCHEMA_PATH="$ROOT_DIR/schemas/federated-ci-summary-tmp-reconcile.schema.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CHECKPOINT_PATH="$TMP_DIR/federated-ci-checkpoint.json"
SUMMARY_PATH="$TMP_DIR/federated-ci-summary.json"
REPORT_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile.json"
VALIDATION_PATH="$TMP_DIR/federated-ci-summary-tmp-reconcile-validation.json"

cat >"$CHECKPOINT_PATH" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-reconcile-validator-test",
  "started_at_utc": "2026-03-22T00:00:00+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log"
    }
  ],
  "required_checks": [
    "contract-conformance",
    "loop-guardrails"
  ]
}
JSON

cp "$CHECKPOINT_PATH" "$SUMMARY_PATH"

python3 "$HELPER_PATH" \
  --summary "$SUMMARY_PATH" \
  --checkpoint "$CHECKPOINT_PATH" \
  --output "$REPORT_PATH" \
  --check-name "contract-conformance" \
  --restore-in-place

python3 "$VALIDATOR_PATH" \
  --report-file "$REPORT_PATH" \
  --schema-file "$SCHEMA_PATH" \
  --output "$VALIDATION_PATH" \
  --strict

python3 - <<'PY' "$REPORT_PATH" "$VALIDATION_PATH"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert report["status"] == "healthy", report
assert report["restored"] is False, report
assert report["check_name"] == "contract-conformance", report
assert report["reconcile_count"] == 0, report
assert report["restored_check_names"] == [], report
assert report["output_path"] == str(Path(sys.argv[1]).resolve()), report
assert validation["verdict"] == "pass", validation
assert validation["reconcile_status"] == "healthy", validation
assert validation["reconcile_restored"] is False, validation
assert validation["reconcile_count"] == 0, validation
PY

cat >"$SUMMARY_PATH" <<'JSON'
{
  "checks": []
}
JSON

python3 "$HELPER_PATH" \
  --summary "$SUMMARY_PATH" \
  --checkpoint "$CHECKPOINT_PATH" \
  --output "$REPORT_PATH" \
  --previous-report "$REPORT_PATH" \
  --check-name "loop-guardrails" \
  --restore-in-place

python3 "$VALIDATOR_PATH" \
  --report-file "$REPORT_PATH" \
  --schema-file "$SCHEMA_PATH" \
  --output "$VALIDATION_PATH" \
  --strict

python3 - <<'PY' "$REPORT_PATH" "$VALIDATION_PATH"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert report["status"] == "restored", report
assert report["restored"] is True, report
assert report["check_name"] == "loop-guardrails", report
assert report["summary_check_count"] == report["checkpoint_check_count"], report
assert report["reasons"], report
assert report["reconcile_count"] == 1, report
assert report["restored_check_names"] == ["loop-guardrails"], report
assert validation["verdict"] == "pass", validation
assert validation["reconcile_status"] == "restored", validation
assert validation["reconcile_restored"] is True, validation
assert validation["reconcile_count"] == 1, validation
PY

python3 - <<'PY' "$REPORT_PATH"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report["reconcile_count"] = 2
Path(sys.argv[1]).write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$VALIDATOR_PATH" \
  --report-file "$REPORT_PATH" \
  --schema-file "$SCHEMA_PATH" \
  --output "$VALIDATION_PATH" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict reconcile validation failure for inconsistent reconcile count"
  exit 1
fi

python3 - <<'PY' "$VALIDATION_PATH"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert validation["verdict"] == "fail", validation
assert any("reconcile_count must equal len(restored_check_names)" in err for err in validation["errors"]), validation
PY

echo "validate federated ci summary tmp reconcile contract ok"
