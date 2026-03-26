#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

summary_tmp="$tmp_dir/federated-ci.tmp.json"
stamped="$tmp_dir/federated-ci-stamped.json"
latest="$tmp_dir/federated-ci-latest.json"
stamped_validation="$tmp_dir/federated-ci-stamped-validation.json"
latest_validation="$tmp_dir/federated-ci-latest-validation.json"

python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" init \
  --summary "$summary_tmp" \
  --run-id "contract-summary-complete" \
  --required-check contract-conformance \
  --required-check provider-profile

python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" append-check \
  --summary "$summary_tmp" \
  --name contract-conformance \
  --domain contract \
  --exit-code 0 \
  --result success \
  --stdout-log "$tmp_dir/contract.stdout.log" \
  --stderr-log "$tmp_dir/contract.stderr.log"

python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" append-check \
  --summary "$summary_tmp" \
  --name provider-profile \
  --domain infra \
  --exit-code 0 \
  --stdout-log "$tmp_dir/provider.stdout.log" \
  --stderr-log "$tmp_dir/provider.stderr.log"

python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" finalize \
  --summary "$summary_tmp" \
  --stamped-path "$stamped" \
  --latest-path "$latest" \
  --status complete \
  --stamped-validation-output "$stamped_validation" \
  --latest-validation-output "$latest_validation" \
  --shell-exit-code 0

python3 - <<'PY' "$stamped" "$latest" "$summary_tmp" "$stamped_validation" "$latest_validation"
import json
import sys
from pathlib import Path

stamped = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
latest = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
tmp_path = Path(sys.argv[3])
stamped_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
latest_validation = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))

assert stamped["run_id"] == "contract-summary-complete", stamped
assert stamped["overall_status"] == "complete", stamped
assert stamped["verdict"] == "pass", stamped
assert stamped["check_count"] == 2, stamped
assert stamped["missing_required_checks"] == [], stamped
assert stamped["failure_classification"]["count"] == 0, stamped
assert stamped["failure_classification"]["deterministic_rule"].count("federated-conformance->federation") == 1, stamped
assert stamped["checks"][0]["result"] == "success", stamped
assert "started_at_utc" in stamped and "finished_at_utc" in stamped, stamped
assert stamped_validation["verdict"] == "pass", stamped_validation
assert latest_validation["verdict"] == "pass", latest_validation
assert stamped_validation["summary_path"].endswith("federated-ci-stamped.json"), stamped_validation
assert latest_validation["summary_path"].endswith("federated-ci-latest.json"), latest_validation
assert latest == stamped, (latest, stamped)
assert not tmp_path.exists(), tmp_path
PY

summary_tmp="$tmp_dir/federated-ci-incomplete.tmp.json"
stamped="$tmp_dir/federated-ci-incomplete-stamped.json"
latest="$tmp_dir/federated-ci-incomplete-latest.json"
stamped_validation="$tmp_dir/federated-ci-incomplete-stamped-validation.json"
latest_validation="$tmp_dir/federated-ci-incomplete-latest-validation.json"

python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" init \
  --summary "$summary_tmp" \
  --run-id "contract-summary-interrupted" \
  --required-check contract-conformance \
  --required-check loop-guardrails

python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" append-check \
  --summary "$summary_tmp" \
  --name contract-conformance \
  --domain contract \
  --exit-code 0 \
  --stdout-log "$tmp_dir/incomplete.stdout.log" \
  --stderr-log "$tmp_dir/incomplete.stderr.log"

if python3 "$ROOT_DIR/scripts/federation/federated_ci_summary.py" finalize \
  --summary "$summary_tmp" \
  --stamped-path "$stamped" \
  --latest-path "$latest" \
  --status interrupted \
  --stamped-validation-output "$stamped_validation" \
  --latest-validation-output "$latest_validation" \
  --shell-exit-code 1; then
  echo "expected interrupted summary finalization to fail"
  exit 1
fi

python3 - <<'PY' "$stamped" "$latest" "$summary_tmp" "$stamped_validation" "$latest_validation"
import json
import sys
from pathlib import Path

stamped = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
latest = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
tmp_path = Path(sys.argv[3])
stamped_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
latest_validation = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))

assert stamped["run_id"] == "contract-summary-interrupted", stamped
assert stamped["overall_status"] == "interrupted", stamped
assert stamped["verdict"] == "fail", stamped
assert stamped["shell_exit_code"] == 1, stamped
assert stamped["check_count"] == 1, stamped
assert stamped["missing_required_checks"] == ["loop-guardrails"], stamped
assert stamped_validation["verdict"] == "pass", stamped_validation
assert latest_validation["verdict"] == "pass", latest_validation
assert stamped_validation["summary_path"].endswith("federated-ci-incomplete-stamped.json"), stamped_validation
assert latest_validation["summary_path"].endswith("federated-ci-incomplete-latest.json"), latest_validation
assert latest == stamped, (latest, stamped)
assert not tmp_path.exists(), tmp_path
PY

echo "federated ci summary contract ok"
