#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

run_id="supervisor-handoff-contract"
summary_path="$tmpdir/summary.json"
artifacts_root="$tmpdir/artifacts"

python3 planningops/scripts/autonomous_supervisor_loop.py \
  --mode dry-run \
  --max-cycles 1 \
  --items-file planningops/fixtures/backlog-stock-items-sample.json \
  --offline \
  --active-goal-registry planningops/config/active-goal-registry.json \
  --loop-result-sequence-file planningops/fixtures/supervisor-loop-sequence-sample.json \
  --run-id "$run_id" \
  --artifacts-root "$artifacts_root" \
  --output "$summary_path" >/dev/null 2>&1 || true

operator_report="$artifacts_root/$run_id/operator-report.json"
operator_summary="$artifacts_root/$run_id/operator-summary.md"
inbox_payload="$artifacts_root/$run_id/inbox-payload.json"

python3 - <<'PY' "$summary_path" "$operator_report" "$operator_summary" "$inbox_payload"
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1])
operator_report_path = Path(sys.argv[2])
operator_summary_path = Path(sys.argv[3])
inbox_payload_path = Path(sys.argv[4])

summary = json.loads(summary_path.read_text(encoding="utf-8"))
operator_report = json.loads(operator_report_path.read_text(encoding="utf-8"))
inbox_payload = json.loads(inbox_payload_path.read_text(encoding="utf-8"))
operator_summary = operator_summary_path.read_text(encoding="utf-8")

assert Path("planningops/contracts/supervisor-operator-handoff-contract.md").exists()
assert operator_report["run_id"] == summary["run_id"], operator_report
assert operator_report["handoff_contract_ref"] == "planningops/contracts/supervisor-operator-handoff-contract.md", operator_report
assert operator_report["message_class_hint"] in {"status_update", "decision_request", "blocked_report", "goal_completed"}, operator_report
assert operator_report["goal_key"], operator_report
assert operator_report["primary_operator_channel"]["kind"].startswith("slack_skill"), operator_report
assert operator_report["terminal_notification_channel"]["kind"].startswith("email"), operator_report

assert inbox_payload["handoff_contract_ref"] == operator_report["handoff_contract_ref"], inbox_payload
assert inbox_payload["goal_key"] == operator_report["goal_key"], inbox_payload
assert inbox_payload["message_class_hint"] == operator_report["message_class_hint"], inbox_payload
assert any(str(attachment).endswith("summary-operator-summary.md") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary.json") for attachment in inbox_payload["attachments"]), inbox_payload

assert "# Supervisor Operator Summary" in operator_summary, operator_summary
assert "Headline:" in operator_summary, operator_summary
PY

echo "supervisor operator handoff contract ok"
