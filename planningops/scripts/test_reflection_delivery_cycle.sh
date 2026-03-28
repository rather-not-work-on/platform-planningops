#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
MONDAY_REPO="$WORKSPACE_ROOT/monday"
MONDAY_TEST_OUTBOX_ROOT="$MONDAY_REPO/runtime-artifacts/test-reflection-delivery-cycle/local-outbox"
MONDAY_QUEUE_DB="$MONDAY_REPO/runtime-artifacts/test-reflection-delivery-cycle/runtime-queue.sqlite3"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$MONDAY_REPO/runtime-artifacts/test-reflection-delivery-cycle" "$MONDAY_REPO/runtime-artifacts/messaging/delivery-reports" "$MONDAY_REPO/runtime-artifacts/messaging/delivery-cycles" "$MONDAY_REPO/runtime-artifacts/messaging/dispatch-packets" "$MONDAY_REPO/runtime-artifacts/messaging/dispatch-acks" "$MONDAY_REPO/runtime-artifacts/messaging/dispatch-execution-packets" "$MONDAY_REPO/runtime-artifacts/messaging/dispatch-receipts" "$MONDAY_REPO/runtime-artifacts/messaging/scheduled-delivery-work-items" "$MONDAY_REPO/runtime-artifacts/scheduler-queue"' EXIT

cd "$ROOT_DIR"

if [[ ! -f "$MONDAY_REPO/scripts/enqueue_scheduled_delivery_work_item.py" ]]; then
  echo "reflection delivery cycle test skipped: sibling monday repo unavailable"
  exit 0
fi

python3 - <<'PY'
from pathlib import Path

runner = Path("planningops/scripts/federation/run_reflection_delivery_cycle.py").read_text(encoding="utf-8")
common = Path("planningops/scripts/federation/reflection_cycle_common.py").read_text(encoding="utf-8")

assert "from reflection_cycle_common import (" in runner, runner
assert "def resolve_repo_root(" not in runner, runner
assert "def resolve_workspace_root(" not in runner, runner
assert "def resolve_input_path(" not in runner, runner
assert "def normalize_monday_runtime_ref(" not in runner, runner
assert "def parse_json_doc(" not in runner, runner
assert "def resolve_repo_root(" in common, common
assert "def resolve_workspace_root(" in common, common
assert "def resolve_input_path(" in common, common
assert "def normalize_monday_runtime_ref(" in common, common
assert "def parse_json_doc(" in common, common
PY

cat >"$TMP_DIR/local-operator-channel-profiles.json" <<JSON
{
  "config_version": "1",
  "profiles": {
    "slack_skill_cli": {
      "channel_kind": "slack_skill_cli",
      "transport_kind": "local_outbox",
      "outbox_root": "$MONDAY_TEST_OUTBOX_ROOT/slack",
      "default_target_name": "primary-operator-thread",
      "supports_threads": true
    },
    "email_cli": {
      "channel_kind": "email_cli",
      "transport_kind": "local_outbox",
      "outbox_root": "$MONDAY_TEST_OUTBOX_ROOT/email",
      "default_target_name": "terminal-completion",
      "supports_threads": false
    }
  }
}
JSON

cat >"$TMP_DIR/continue-action.json" <<'JSON'
{
  "handoff_contract_ref": "planningops/contracts/reflection-action-handoff-contract.md",
  "verdict": "pass",
  "active_goal_key": "uap-goal-driven-autonomy-wave10",
  "queue_item_id": "queue-wave10-001",
  "worker_run_id": "wave10-run-001",
  "reflection_decision": "continue",
  "decision_reason": "retry_wait_runtime_outcome",
  "control_plane_action": "none",
  "action_kind": "record_continue",
  "delivery_required": false,
  "message_class_hint": "status_update",
  "operator_channel_role": "none",
  "operator_channel_kind": "-",
  "operator_channel_execution_repo": "-",
  "operator_channel_adapter_contract_ref": "-",
  "goal_transition_required": false,
  "requested_goal_status": "-",
  "goal_transition_report_path": "-",
  "handoff_summary": "Queue item queue-wave10-001 remains in the supervisor flow after reflection decision continue (record_continue).",
  "source_packet_ref": "planningops/artifacts/validation/retry-packet.json",
  "reflection_evaluation_ref": "planningops/artifacts/validation/retry-eval.json"
}
JSON

cat >"$TMP_DIR/replan-action.json" <<'JSON'
{
  "handoff_contract_ref": "planningops/contracts/reflection-action-handoff-contract.md",
  "verdict": "pass",
  "active_goal_key": "uap-goal-driven-autonomy-wave10",
  "queue_item_id": "queue-wave10-002",
  "worker_run_id": "wave10-run-002",
  "reflection_decision": "replan_required",
  "decision_reason": "dead_letter_runtime_outcome",
  "control_plane_action": "replan_backlog",
  "action_kind": "trigger_replan_review",
  "delivery_required": true,
  "message_class_hint": "decision_request",
  "operator_channel_role": "primary_operator_channel",
  "operator_channel_kind": "slack_skill_cli",
  "operator_channel_execution_repo": "rather-not-work-on/monday",
  "operator_channel_adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
  "goal_transition_required": false,
  "requested_goal_status": "-",
  "goal_transition_report_path": "-",
  "handoff_summary": "Queue item queue-wave10-002 exhausted runtime recovery and requires replanning review for goal uap-goal-driven-autonomy-wave10.",
  "source_packet_ref": "planningops/artifacts/validation/dead-letter-packet.json",
  "reflection_evaluation_ref": "planningops/artifacts/validation/dead-letter-eval.json"
}
JSON

cat >"$TMP_DIR/goal-transition-report.json" <<'JSON'
{
  "generated_at_utc": "2026-03-14T08:00:00Z",
  "goal_key": "uap-goal-driven-autonomy-wave10",
  "to_status": "achieved",
  "verdict": "pass"
}
JSON

cat >"$TMP_DIR/goal-completed-action.json" <<JSON
{
  "handoff_contract_ref": "planningops/contracts/reflection-action-handoff-contract.md",
  "verdict": "pass",
  "active_goal_key": "uap-goal-driven-autonomy-wave10",
  "queue_item_id": "queue-wave10-003",
  "worker_run_id": "wave10-run-003",
  "reflection_decision": "goal_achieved",
  "decision_reason": "completed_runtime_outcome",
  "control_plane_action": "evaluate_goal_completion",
  "action_kind": "prepare_goal_completion",
  "delivery_required": true,
  "message_class_hint": "goal_completed",
  "operator_channel_role": "terminal_notification_channel",
  "operator_channel_kind": "email_cli",
  "operator_channel_execution_repo": "rather-not-work-on/monday",
  "operator_channel_adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
  "goal_transition_required": true,
  "requested_goal_status": "achieved",
  "goal_transition_report_path": "$TMP_DIR/goal-transition-report.json",
  "handoff_summary": "Queue item queue-wave10-003 completed successfully and qualifies goal uap-goal-driven-autonomy-wave10 for goal-completion handling.",
  "source_packet_ref": "planningops/artifacts/validation/completed-packet.json",
  "reflection_evaluation_ref": "planningops/artifacts/validation/completed-eval.json"
}
JSON

python3 planningops/scripts/run_reflection_delivery_cycle.py \
  --workspace-root .. \
  --action-file "$TMP_DIR/continue-action.json" \
  --run-id "test-reflection-delivery-continue" \
  --output "$TMP_DIR/continue-report.json" >/dev/null

python3 planningops/scripts/run_reflection_delivery_cycle.py \
  --workspace-root .. \
  --action-file "$TMP_DIR/replan-action.json" \
  --monday-queue-db "$MONDAY_QUEUE_DB" \
  --thread-ref "thread-wave10" \
  --monday-profiles-config "$TMP_DIR/local-operator-channel-profiles.json" \
  --run-id "test-reflection-delivery-replan" \
  --output "$TMP_DIR/replan-report.json" >/dev/null

if python3 planningops/scripts/run_reflection_delivery_cycle.py \
  --workspace-root .. \
  --action-file "$TMP_DIR/goal-completed-action.json" \
  --monday-queue-db "$MONDAY_QUEUE_DB" \
  --monday-profiles-config "$TMP_DIR/local-operator-channel-profiles.json" \
  --run-id "test-reflection-delivery-complete" \
  --output "$TMP_DIR/goal-completed-report.json" >/dev/null; then
  echo "expected goal-completed reflection delivery dry-run to fail closed"
  exit 1
fi

python3 planningops/scripts/run_reflection_delivery_cycle.py \
  --workspace-root .. \
  --action-file "$TMP_DIR/replan-action.json" \
  --monday-queue-db "$MONDAY_QUEUE_DB" \
  --thread-ref "thread-wave10" \
  --monday-profiles-config "$TMP_DIR/local-operator-channel-profiles.json" \
  --mode apply \
  --run-id "test-reflection-delivery-replan-apply-local" \
  --output "$TMP_DIR/replan-apply-local-report.json" >/dev/null

if python3 planningops/scripts/run_reflection_delivery_cycle.py \
  --workspace-root .. \
  --action-file "$TMP_DIR/goal-completed-action.json" \
  --monday-queue-db "$MONDAY_QUEUE_DB" \
  --monday-profiles-config "$TMP_DIR/local-operator-channel-profiles.json" \
  --mode apply \
  --run-id "test-reflection-delivery-complete-apply-local" \
  --output "$TMP_DIR/goal-completed-apply-local-report.json" >/dev/null; then
  echo "expected goal-completed reflection delivery apply to fail closed"
  exit 1
fi

python3 planningops/scripts/run_reflection_delivery_cycle.py \
  --workspace-root .. \
  --action-file "$TMP_DIR/replan-action.json" \
  --monday-queue-db "$MONDAY_QUEUE_DB" \
  --delivery-target "slack://monday/thread-wave10" \
  --monday-profiles-config "$TMP_DIR/local-operator-channel-profiles.json" \
  --mode apply \
  --run-id "test-reflection-delivery-replan-apply" \
  --output "$TMP_DIR/replan-apply-report.json" >/dev/null

python3 - "$MONDAY_QUEUE_DB" "$TMP_DIR/continue-report.json" "$TMP_DIR/replan-report.json" "$TMP_DIR/goal-completed-report.json" "$TMP_DIR/replan-apply-local-report.json" "$TMP_DIR/goal-completed-apply-local-report.json" "$TMP_DIR/replan-apply-report.json" <<'PY'
import json
import sqlite3
import sys
from pathlib import Path

queue_db_path, continue_report_path, replan_report_path, goal_completed_report_path, replan_apply_local_report_path, goal_completed_apply_local_report_path, replan_apply_report_path = sys.argv[1:]
continue_report = json.loads(Path(continue_report_path).read_text(encoding="utf-8"))
replan_report = json.loads(Path(replan_report_path).read_text(encoding="utf-8"))
goal_completed_report = json.loads(Path(goal_completed_report_path).read_text(encoding="utf-8"))
replan_apply_local_report = json.loads(Path(replan_apply_local_report_path).read_text(encoding="utf-8"))
goal_completed_apply_local_report = json.loads(Path(goal_completed_apply_local_report_path).read_text(encoding="utf-8"))
replan_apply_report = json.loads(Path(replan_apply_report_path).read_text(encoding="utf-8"))

assert continue_report["verdict"] == "pass", continue_report
assert continue_report["delivery_required"] is False, continue_report
assert continue_report["delivery_skipped"] is True, continue_report
assert continue_report["delivery_verdict"] == "skipped", continue_report
assert continue_report["monday_delivery_report_ref"] == "-", continue_report

assert replan_report["verdict"] == "pass", replan_report
assert replan_report["delivery_required"] is True, replan_report
assert replan_report["delivery_skipped"] is False, replan_report
assert replan_report["monday_delivery_entrypoint"] == "monday/scripts/enqueue_scheduled_delivery_work_item.py", replan_report
assert replan_report["delivery_verdict"] == "dry_run", replan_report
assert replan_report["queue_admission_verdict"] == "pass", replan_report
assert replan_report["selected_delivery_entrypoint"] == "scripts/run_operator_message_delivery_cycle.py", replan_report
assert replan_report["scheduled_delivery_work_item_ref"].startswith("monday/runtime-artifacts/messaging/scheduled-delivery-work-items/"), replan_report
assert replan_report["scheduled_queue_item_ref"].startswith("monday/runtime-artifacts/scheduler-queue/item-refs/"), replan_report
assert replan_report["scheduled_queue_item_ref"].endswith(f'{replan_report["scheduled_queue_item_id"]}.json'), replan_report
assert replan_report["delivery_outbox_message_ref"] == "-", replan_report
assert replan_report["stage_reports"][0]["stage"] == "queue_admission", replan_report
assert replan_report["stage_reports"][0]["verdict"] == "pass", replan_report

assert goal_completed_report["verdict"] == "fail", goal_completed_report
assert goal_completed_report["message_class_hint"] == "goal_completed", goal_completed_report
assert goal_completed_report["failure_stage"] == "validate_queue_admission_handoff", goal_completed_report
assert goal_completed_report["error_count"] >= 1, goal_completed_report

assert replan_apply_local_report["verdict"] == "pass", replan_apply_local_report
assert replan_apply_local_report["delivery_verdict"] == "queued", replan_apply_local_report
assert replan_apply_local_report["queue_admission_verdict"] == "pass", replan_apply_local_report
assert replan_apply_local_report["selected_delivery_entrypoint"] == "scripts/run_operator_message_delivery_cycle.py", replan_apply_local_report
assert replan_apply_local_report["scheduled_delivery_work_item_ref"].startswith("monday/runtime-artifacts/messaging/scheduled-delivery-work-items/"), replan_apply_local_report
assert replan_apply_local_report["scheduled_queue_item_ref"].startswith("monday/runtime-artifacts/scheduler-queue/item-refs/"), replan_apply_local_report
assert replan_apply_local_report["scheduled_queue_item_ref"].endswith(f'{replan_apply_local_report["scheduled_queue_item_id"]}.json'), replan_apply_local_report

assert goal_completed_apply_local_report["verdict"] == "fail", goal_completed_apply_local_report
assert goal_completed_apply_local_report["failure_stage"] == "validate_queue_admission_handoff", goal_completed_apply_local_report
assert goal_completed_apply_local_report["error_count"] >= 1, goal_completed_apply_local_report

assert replan_apply_report["verdict"] == "pass", replan_apply_report
assert replan_apply_report["delivery_skipped"] is False, replan_apply_report
assert replan_apply_report["delivery_verdict"] == "queued", replan_apply_report
assert replan_apply_report["queue_admission_verdict"] == "pass", replan_apply_report
assert replan_apply_report["selected_delivery_entrypoint"] == "scripts/run_operator_message_delivery_cycle.py", replan_apply_report

conn = sqlite3.connect(queue_db_path)
rows = conn.execute("SELECT queue_item_id, schedule_key, work_payload_ref FROM queue_items ORDER BY queue_item_id").fetchall()
conn.close()
assert len(rows) >= 1, rows
queue_ids = {row[0] for row in rows}
assert replan_apply_local_report["scheduled_queue_item_id"] in queue_ids, rows
assert replan_apply_report["scheduled_queue_item_id"] in queue_ids, rows
assert replan_apply_local_report["scheduled_queue_item_id"] == replan_apply_report["scheduled_queue_item_id"], rows
for row in rows:
    assert row[1] == "recurring-delivery", row
    assert row[2].startswith("runtime-artifacts/messaging/scheduled-delivery-work-items/"), row

print("reflection delivery cycle test passed")
PY
