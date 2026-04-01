#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_federated_summary_ci_check.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

bash "$SCRIPT_PATH" \
  --run-id ci-pass \
  --contract-conformance-result success \
  --runtime-handoff-result success \
  --monday-harness-projection-result success \
  --o11y-replay-result success \
  --provider-profile-result success \
  --federated-conformance-result success \
  --loop-guardrails-result success \
  --summary-tmp "$tmp_dir/ci-pass.tmp.json" \
  --stamped-path "$tmp_dir/ci-pass.json" \
  --latest-path "$tmp_dir/federated-ci-summary.json" \
  --stamped-validation-path "$tmp_dir/ci-pass-summary-validation.json" \
  --latest-validation-path "$tmp_dir/federated-ci-summary-validation.json" \
  --stamped-readiness-path "$tmp_dir/ci-pass-summary-readiness.json" \
  --latest-readiness-path "$tmp_dir/federated-ci-summary-readiness.json" \
  --stamped-readiness-validation-path "$tmp_dir/ci-pass-summary-readiness-validation.json" \
  --latest-readiness-validation-path "$tmp_dir/federated-ci-summary-readiness-validation.json"

python3 - <<'PY' "$tmp_dir/ci-pass.json" "$tmp_dir/federated-ci-summary-readiness.json" "$tmp_dir/ci-pass.tmp.json" "$tmp_dir/ci-pass-summary-validation.json" "$tmp_dir/federated-ci-summary-validation.json"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
readiness = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
tmp_summary_path = Path(sys.argv[3])
stamped_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
latest_validation = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))

assert summary["run_id"] == "ci-pass", summary
assert isinstance(summary["started_at_utc"], str) and summary["started_at_utc"], summary
assert summary["verdict"] == "pass", summary
assert summary["overall_status"] == "complete", summary
assert summary["check_count"] == 7, summary
assert stamped_validation["verdict"] == "pass", stamped_validation
assert stamped_validation["summary_run_id"] == "ci-pass", stamped_validation
assert latest_validation["verdict"] == "pass", latest_validation
assert latest_validation["summary_run_id"] == "ci-pass", latest_validation
assert readiness["summary_run_id"] == "ci-pass", readiness
assert readiness["readiness_status"] == "ready", readiness
assert readiness["ready"] is True, readiness
assert readiness["next_step"] == "none", readiness
assert not tmp_summary_path.exists(), tmp_summary_path
PY

set +e
bash "$SCRIPT_PATH" \
  --run-id ci-fail \
  --contract-conformance-result success \
  --runtime-handoff-result success \
  --monday-harness-projection-result success \
  --o11y-replay-result success \
  --provider-profile-result failure \
  --federated-conformance-result success \
  --loop-guardrails-result success \
  --summary-tmp "$tmp_dir/ci-fail.tmp.json" \
  --stamped-path "$tmp_dir/ci-fail.json" \
  --latest-path "$tmp_dir/federated-ci-summary-fail.json" \
  --stamped-validation-path "$tmp_dir/ci-fail-summary-validation.json" \
  --latest-validation-path "$tmp_dir/federated-ci-summary-fail-validation.json" \
  --stamped-readiness-path "$tmp_dir/ci-fail-summary-readiness.json" \
  --latest-readiness-path "$tmp_dir/federated-ci-summary-fail-readiness.json" \
  --stamped-readiness-validation-path "$tmp_dir/ci-fail-summary-readiness-validation.json" \
  --latest-readiness-validation-path "$tmp_dir/federated-ci-summary-fail-readiness-validation.json"
rc=$?
set -e

test "$rc" -eq 1

python3 - <<'PY' "$tmp_dir/ci-fail.json" "$tmp_dir/federated-ci-summary-fail-readiness.json" "$tmp_dir/ci-fail-summary-validation.json" "$tmp_dir/federated-ci-summary-fail-validation.json"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
readiness = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
stamped_validation = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
latest_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

assert summary["run_id"] == "ci-fail", summary
assert summary["verdict"] == "fail", summary
assert summary["overall_status"] == "complete", summary
assert summary["failure_classification"]["count"] == 1, summary
assert stamped_validation["verdict"] == "pass", stamped_validation
assert stamped_validation["summary_run_id"] == "ci-fail", stamped_validation
assert latest_validation["verdict"] == "pass", latest_validation
assert latest_validation["summary_run_id"] == "ci-fail", latest_validation
assert readiness["summary_run_id"] == "ci-fail", readiness
assert readiness["readiness_status"] == "blocked", readiness
assert readiness["ready"] is False, readiness
assert readiness["next_step"] != "none", readiness
PY

echo "federated summary ci check smoke ok"
