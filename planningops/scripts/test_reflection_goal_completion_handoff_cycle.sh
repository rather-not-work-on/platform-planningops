#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
MONDAY_REPO="$WORKSPACE_ROOT/monday"
TMP_DIR="$(mktemp -d)"
RUN_ID="test-wave29-memory-goal-completion"
QUEUE_ITEM_ID="memory-consolidation-job-mission-29-job-run-29"
SCHEDULER_REPORT_PATH="$MONDAY_REPO/runtime-artifacts/scheduler-cycle/${RUN_ID}.json"
MEMORY_CYCLE_REPORT_PATH="$MONDAY_REPO/runtime-artifacts/scheduler-cycle/${RUN_ID}-memory-cycle.json"
MEMORY_JOB_REPORT_PATH="$MONDAY_REPO/runtime-artifacts/scheduler-cycle/${RUN_ID}-memory-cycle-job.json"
MEMORY_WORKER_OUTCOME_PATH="$MONDAY_REPO/runtime-artifacts/worker-outcome/${RUN_ID}-${QUEUE_ITEM_ID}.json"
MEMORY_JOB_INPUT_ARTIFACT="$MONDAY_REPO/runtime-artifacts/memory/scheduled-consolidation-job-inputs/$QUEUE_ITEM_ID.json"
MEMORY_WORK_ITEM_ARTIFACT="$MONDAY_REPO/runtime-artifacts/memory/scheduled-consolidation-work-items/$QUEUE_ITEM_ID.json"
MEMORY_QUEUE_REF_ARTIFACT="$MONDAY_REPO/runtime-artifacts/scheduler-queue/item-refs/$QUEUE_ITEM_ID.json"
trap 'rm -rf "$TMP_DIR" "$SCHEDULER_REPORT_PATH" "$MEMORY_CYCLE_REPORT_PATH" "$MEMORY_JOB_REPORT_PATH" "$MEMORY_WORKER_OUTCOME_PATH" "$MEMORY_JOB_INPUT_ARTIFACT" "$MEMORY_WORK_ITEM_ARTIFACT" "$MEMORY_QUEUE_REF_ARTIFACT"' EXIT

cd "$ROOT_DIR"

if [[ ! -f "$MONDAY_REPO/scripts/export_scheduler_worker_outcome_reflection_packet.py" ]]; then
  echo "reflection goal completion handoff cycle test skipped: sibling monday repo unavailable"
  exit 0
fi

python3 - <<'PY'
from pathlib import Path

runner = Path("planningops/scripts/federation/run_reflection_goal_completion_handoff_cycle.py").read_text(encoding="utf-8")
handoff_common = Path("planningops/scripts/supervisor_handoff_common.py").read_text(encoding="utf-8")
reflection_common = Path("planningops/scripts/federation/reflection_cycle_common.py").read_text(encoding="utf-8")

assert "from reflection_cycle_common import (" in runner, runner
assert "from supervisor_handoff_common import (" in runner, runner
assert "from autonomous_supervisor_loop import (" not in runner, runner
assert "def resolve_goal_context(" not in runner, runner
assert "def load_json(" not in runner, runner
assert "def normalize_repo_path(" not in runner, runner
assert "def run_goal_completion_delivery(" in handoff_common, handoff_common
assert "def build_operator_report(" in handoff_common, handoff_common
assert "def build_inbox_payload(" in handoff_common, handoff_common
assert "def resolve_goal_context(" in reflection_common, reflection_common
assert "def load_json(" in reflection_common, reflection_common
assert "def normalize_repo_path(" in reflection_common, reflection_common
PY

DB_PATH="$TMP_DIR/runtime-queue.sqlite3"
IDEMPOTENCY_PATH="$TMP_DIR/idempotency.json"
TRANSITION_LOG="$TMP_DIR/transition.ndjson"
MEMORY_ROOT="$TMP_DIR/memory-root"
JOB_INPUT="$TMP_DIR/memory-consolidation-job-input.json"
QUEUE_ADMISSION_REPORT="$TMP_DIR/memory-consolidation-admission-report.json"
GOAL_REGISTRY="$TMP_DIR/active-goal-registry.json"
TERMINAL_PROFILES="$TMP_DIR/local-operator-channel-profiles.json"
PACKET_OUTPUT="$TMP_DIR/packet.json"
EVALUATION_OUTPUT="$TMP_DIR/evaluation.json"
ACTION_OUTPUT="$TMP_DIR/action.json"
REFLECTION_REPORT="$TMP_DIR/reflection-cycle-report.json"
GOAL_COMPLETION_REPORT="$TMP_DIR/reflection-goal-completion-report.json"
FEDERATED_SUMMARY="$TMP_DIR/federated-ci-summary.json"
FEDERATED_READINESS="$TMP_DIR/federated-ci-summary-readiness.json"

mkdir -p "$MEMORY_ROOT"

cat >"$TERMINAL_PROFILES" <<JSON
{
  "config_version": "1",
  "profiles": {
    "slack_skill_cli": {
      "channel_kind": "slack_skill_cli",
      "transport_kind": "local_outbox",
      "outbox_root": "$TMP_DIR/local-outbox/slack",
      "default_target_name": "primary-operator-thread",
      "supports_threads": true
    },
    "email_cli": {
      "channel_kind": "email_cli",
      "transport_kind": "local_outbox",
      "outbox_root": "$TMP_DIR/local-outbox/email",
      "default_target_name": "terminal-completion",
      "supports_threads": false
    }
  }
}
JSON

cat >"$FEDERATED_SUMMARY" <<JSON
{
  "run_id": "federated-ci-reflection-goal-completion-test",
  "generated_at_utc": "2026-03-26T12:00:00.000000+00:00",
  "verdict": "pass",
  "overall_status": "complete",
  "check_count": 10
}
JSON

cat >"$FEDERATED_READINESS" <<JSON
{
  "generated_at_utc": "2026-03-26T12:00:05.000000+00:00",
  "summary_path": "$FEDERATED_SUMMARY",
  "validation_report_path": "$TMP_DIR/federated-ci-summary-validation.json",
  "summary_present": true,
  "validation_present": true,
  "summary_run_id": "federated-ci-reflection-goal-completion-test",
  "summary_generated_at_utc": "2026-03-26T12:00:00.000000+00:00",
  "summary_verdict": "pass",
  "overall_status": "complete",
  "check_count": 10,
  "failed_checks": [],
  "missing_required_checks": [],
  "validation_verdict": "pass",
  "validation_state": "fresh",
  "ready": true,
  "readiness_status": "ready",
  "blocking_reasons": [],
  "next_step": "none"
}
JSON

cat >"$MEMORY_ROOT/session-memory.json" <<'JSON'
[
  {
    "schemaVersion": 1,
    "id": "seed-turn-1",
    "memoryType": "session_memory",
    "tenantId": "tenant-alpha",
    "userId": "user-primary",
    "projectId": "project-runtime",
    "threadId": "thread-runtime",
    "createdAtUtc": "2026-03-25T06:00:00.000Z",
    "updatedAtUtc": "2026-03-25T06:00:00.000Z",
    "role": "user",
    "content": "Earlier thread context should be compacted later.",
    "tokenCount": 7
  },
  {
    "schemaVersion": 1,
    "id": "seed-turn-2",
    "memoryType": "session_memory",
    "tenantId": "tenant-alpha",
    "userId": "user-primary",
    "projectId": "project-runtime",
    "threadId": "thread-runtime",
    "createdAtUtc": "2026-03-25T06:00:01.000Z",
    "updatedAtUtc": "2026-03-25T06:00:01.000Z",
    "role": "assistant",
    "content": "Acknowledged earlier context.",
    "tokenCount": 4
  },
  {
    "schemaVersion": 1,
    "id": "session-user:job-run-29",
    "memoryType": "session_memory",
    "tenantId": "tenant-alpha",
    "userId": "user-primary",
    "projectId": "project-runtime",
    "threadId": "thread-runtime",
    "runId": "job-run-29",
    "sessionId": "job-run-29:session:primary",
    "createdAtUtc": "2026-03-25T06:00:02.000Z",
    "updatedAtUtc": "2026-03-25T06:00:02.000Z",
    "role": "user",
    "content": "I prefer concise markdown summaries. Please prepare the blocker note.",
    "tokenCount": 11
  },
  {
    "schemaVersion": 1,
    "id": "session-assistant:job-run-29",
    "memoryType": "session_memory",
    "tenantId": "tenant-alpha",
    "userId": "user-primary",
    "projectId": "project-runtime",
    "threadId": "thread-runtime",
    "runId": "job-run-29",
    "sessionId": "job-run-29:session:primary",
    "createdAtUtc": "2026-03-25T06:00:03.000Z",
    "updatedAtUtc": "2026-03-25T06:00:03.000Z",
    "role": "assistant",
    "content": "Still blocked on finance sign-off for the release. Keep the update short.",
    "tokenCount": 12
  }
]
JSON

cat >"$JOB_INPUT" <<JSON
{
  "memoryRootDir": "$MEMORY_ROOT",
  "mission": {
    "missionId": "job-mission-29",
    "objective": "I prefer concise markdown summaries. Please prepare the blocker note.",
    "memoryScope": {
      "tenantId": "tenant-alpha",
      "userId": "user-primary",
      "projectId": "project-runtime",
      "threadId": "thread-runtime"
    }
  },
  "intakeRecord": {
    "schemaVersion": 1,
    "missionId": "job-mission-29",
    "objective": "I prefer concise markdown summaries. Please prepare the blocker note.",
    "runId": "job-run-29",
    "sessionId": "job-run-29:session:primary",
    "startingPhase": "plan",
    "createdAtUtc": "2026-03-25T06:00:02.000Z"
  },
  "handoff": {
    "handoffId": "job-run-29:handoff:task:1",
    "taskId": "job-mission-29:task:1"
  },
  "outcome": {
    "resultType": "complete",
    "outputText": "Still blocked on finance sign-off for the release. Keep the update short.",
    "reasonCode": "reflection_goal_completion_handoff_test"
  },
  "policy": {
    "maxUnsummarizedTurns": 1,
    "promoteExplicitPreferences": true,
    "consolidatedAtUtc": "2026-03-25T06:00:10.000Z"
  },
  "generatedAtUtc": "2026-03-25T06:00:11.000Z"
}
JSON

cat >"$GOAL_REGISTRY" <<'JSON'
{
  "registry_version": 1,
  "active_goal_key": "agent-memory-consolidation:job-mission-29",
  "goals": [
    {
      "goal_key": "agent-memory-consolidation:job-mission-29",
      "title": "MONDAY agent memory scheduled consolidation reflection",
      "status": "active",
      "owner_repo": "rather-not-work-on/platform-planningops",
      "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-25-monday-agent-memory-wave-h-control-plane-reflection-packet.md",
      "execution_contract_file": "planningops/contracts/worker-outcome-reflection-contract.md",
      "completion_contract_refs": [
        "planningops/contracts/goal-completion-contract.md",
        "planningops/contracts/worker-outcome-reflection-contract.md"
      ],
      "operator_channels": {
        "primary_operator_channel": {
          "kind": "slack_skill_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        },
        "terminal_notification_channel": {
          "kind": "email_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        }
      }
    }
  ]
}
JSON

(
  cd "$MONDAY_REPO"
  python3 scripts/enqueue_memory_consolidation_work_item.py \
    --job-input-file "$JOB_INPUT" \
    --schedule-key memory-background \
    --mode apply \
    --queue-db "$DB_PATH" \
    --output "$QUEUE_ADMISSION_REPORT" >/dev/null

  python3 scripts/run_scheduled_queue_cycle.py \
    --queue-db "$DB_PATH" \
    --run-id "$RUN_ID" \
    --idempotency "$IDEMPOTENCY_PATH" \
    --report "$SCHEDULER_REPORT_PATH" \
    --transition-log "$TRANSITION_LOG" >/dev/null
)

python3 planningops/scripts/run_worker_outcome_reflection_cycle.py \
  --workspace-root .. \
  --scheduler-report-json "$SCHEDULER_REPORT_PATH" \
  --active-goal-registry "$GOAL_REGISTRY" \
  --goal-key "agent-memory-consolidation:job-mission-29" \
  --run-id "test-reflection-cycle-memory-goal-completion" \
  --packet-output "$PACKET_OUTPUT" \
  --evaluation-output "$EVALUATION_OUTPUT" \
  --action-output "$ACTION_OUTPUT" \
  --output "$REFLECTION_REPORT" >/dev/null

python3 planningops/scripts/run_reflection_goal_completion_handoff_cycle.py \
  --workspace-root .. \
  --reflection-action-file "$ACTION_OUTPUT" \
  --active-goal-registry "$GOAL_REGISTRY" \
  --goal-key "agent-memory-consolidation:job-mission-29" \
  --federated-ci-summary "$FEDERATED_SUMMARY" \
  --federated-ci-summary-readiness "$FEDERATED_READINESS" \
  --monday-profiles-config "$TERMINAL_PROFILES" \
  --monday-supervisor-queue-db "$DB_PATH" \
  --mode apply \
  --run-id "test-reflection-goal-completion-memory-bridge" \
  --output "$GOAL_COMPLETION_REPORT" >/dev/null

python3 - "$GOAL_COMPLETION_REPORT" "$GOAL_REGISTRY" "$DB_PATH" "$MONDAY_REPO" <<'PY'
import json
import sqlite3
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
registry = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
db_path = sys.argv[3]
monday_repo = Path(sys.argv[4]).resolve()
workspace_root = monday_repo.parent

operator_report = json.loads(Path(report["operator_report_ref"]).read_text(encoding="utf-8"))
inbox_payload = json.loads(Path(report["inbox_payload_ref"]).read_text(encoding="utf-8"))
handoff_validation = json.loads(Path(report["operator_handoff_validation_ref"]).read_text(encoding="utf-8"))
delivery_report_path = Path(report["goal_completion_delivery_report_ref"])
if not delivery_report_path.is_absolute():
    if not delivery_report_path.exists():
        if delivery_report_path.parts and delivery_report_path.parts[0] == "monday":
            delivery_report_path = workspace_root / delivery_report_path
        else:
            delivery_report_path = monday_repo / delivery_report_path
delivery_report = json.loads(delivery_report_path.read_text(encoding="utf-8"))
work_item_path = Path(delivery_report["scheduled_delivery_work_item_ref"])
if not work_item_path.is_absolute():
    if not work_item_path.exists():
        work_item_path = monday_repo / work_item_path
work_item = json.loads(work_item_path.read_text(encoding="utf-8"))

assert report["verdict"] == "pass", report
assert report["reflection_decision"] == "goal_achieved", report
assert report["action_kind"] == "prepare_goal_completion", report
assert report["message_class_hint"] == "goal_completed", report
assert report["goal_completion_delivery_enabled"] is True, report
assert report["goal_completion_delivery_verdict"] == "queued", report
assert report["queue_admission_verdict"] == "pass", report
assert report["selected_delivery_entrypoint"] == "scripts/run_goal_completion_delivery_cycle.py", report
assert report["scheduled_delivery_work_item_ref"].startswith("monday/runtime-artifacts/messaging/scheduled-delivery-work-items/"), report
assert report["scheduled_queue_item_ref"].startswith("monday/runtime-artifacts/scheduler-queue/item-refs/"), report

assert operator_report["status"] == "ok", operator_report
assert operator_report["operator_action"] == "notify_goal_completion", operator_report
assert operator_report["message_class_hint"] == "goal_completed", operator_report
assert operator_report["goal_transition_report_path"] != "-", operator_report
assert operator_report["goal_completion_delivery_report_path"] == report["goal_completion_delivery_report_ref"], operator_report

assert handoff_validation["verdict"] == "pass", handoff_validation
assert report["goal_completion_delivery_report_ref"] in inbox_payload["attachments"], inbox_payload

assert delivery_report["verdict"] == "pass", delivery_report
assert delivery_report["delivery_work_item_kind"] == "goal_completion_delivery", delivery_report
assert delivery_report["selected_delivery_entrypoint"] == "scripts/run_goal_completion_delivery_cycle.py", delivery_report

assert work_item["delivery_work_item_kind"] == "goal_completion_delivery", work_item
assert work_item["message_class"] == "goal_completed", work_item

assert registry["active_goal_key"] == "", registry
goal = registry["goals"][0]
assert goal["status"] == "achieved", goal

conn = sqlite3.connect(db_path)
rows = conn.execute("SELECT queue_item_id, state, schedule_key, work_payload_ref FROM queue_items ORDER BY queue_item_id").fetchall()
conn.close()
assert len(rows) == 2, rows
queued_goal_completion = [row for row in rows if row[0] == report["scheduled_queue_item_id"]]
assert len(queued_goal_completion) == 1, rows
assert queued_goal_completion[0][1] == "ready", queued_goal_completion
assert queued_goal_completion[0][2] == "recurring-delivery", queued_goal_completion
assert queued_goal_completion[0][3].startswith("runtime-artifacts/messaging/scheduled-delivery-work-items/"), queued_goal_completion
PY

echo "reflection goal completion handoff cycle test passed"
