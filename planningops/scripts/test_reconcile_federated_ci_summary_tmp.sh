#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER_PATH="$ROOT_DIR/scripts/federation/reconcile_federated_ci_summary_tmp.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CHECKPOINT_PATH="$TMP_DIR/federated-ci-checkpoint.json"
SUMMARY_PATH="$TMP_DIR/federated-ci-summary.json"
REPORT_PATH="$TMP_DIR/reconcile-report.json"

cat >"$CHECKPOINT_PATH" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-reconcile-test",
  "started_at_utc": "2026-03-22T00:00:00+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log"
    },
    {
      "name": "provider-profile",
      "domain": "infra",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/provider.stdout.log",
      "stderr_log": "/tmp/provider.stderr.log"
    }
  ],
  "required_checks": [
    "contract-conformance",
    "provider-profile",
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

python3 - <<'PY' "$SUMMARY_PATH" "$CHECKPOINT_PATH" "$REPORT_PATH"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
checkpoint = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

assert summary == checkpoint, (summary, checkpoint)
assert report["status"] == "healthy", report
assert report["restored"] is False, report
assert report["check_name"] == "contract-conformance", report
assert report["reasons"] == [], report
assert report["summary_check_count"] == 2, report
assert report["checkpoint_check_count"] == 2, report
assert report["reconcile_count"] == 0, report
assert report["restored_check_names"] == [], report
PY

cat >"$SUMMARY_PATH" <<'JSON'
{
  "checks": [
    {
      "name": "loop-guardrails",
      "domain": "policy",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/loop.stdout.log",
      "stderr_log": "/tmp/loop.stderr.log"
    }
  ]
}
JSON

python3 "$HELPER_PATH" \
  --summary "$SUMMARY_PATH" \
  --checkpoint "$CHECKPOINT_PATH" \
  --output "$REPORT_PATH" \
  --previous-report "$REPORT_PATH" \
  --check-name "loop-guardrails" \
  --restore-in-place

python3 - <<'PY' "$SUMMARY_PATH" "$CHECKPOINT_PATH" "$REPORT_PATH"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
checkpoint = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

assert summary == checkpoint, (summary, checkpoint)
assert report["status"] == "restored", report
assert report["restored"] is True, report
assert report["check_name"] == "loop-guardrails", report
assert "summary_missing_run_id" in report["reasons"], report
assert "summary_missing_started_at_utc" in report["reasons"], report
assert "summary_missing_required_checks" in report["reasons"], report
assert report["summary_check_count"] == 2, report
assert report["checkpoint_check_count"] == 2, report
assert report["reconcile_count"] == 1, report
assert report["restored_check_names"] == ["loop-guardrails"], report
PY

cp "$CHECKPOINT_PATH" "$SUMMARY_PATH"

python3 "$HELPER_PATH" \
  --summary "$SUMMARY_PATH" \
  --checkpoint "$CHECKPOINT_PATH" \
  --output "$REPORT_PATH" \
  --previous-report "$REPORT_PATH" \
  --check-name "runtime-handoff" \
  --restore-in-place

python3 - <<'PY' "$REPORT_PATH"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["status"] == "healthy", report
assert report["restored"] is False, report
assert report["check_name"] == "runtime-handoff", report
assert report["reconcile_count"] == 1, report
assert report["restored_check_names"] == ["loop-guardrails"], report
PY

echo "reconcile federated ci summary tmp ok"
