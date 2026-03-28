#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
MONDAY_REPO="$WORKSPACE_ROOT/monday"
TMP_DIR="$(mktemp -d)"
RUN_ID="test-wave28-memory-reflection-cycle"
QUEUE_ITEM_ID="memory-consolidation-job-mission-28-job-run-28"
REPORT_PATH="$MONDAY_REPO/runtime-artifacts/scheduler-cycle/${RUN_ID}.json"
CYCLE_REPORT_PATH="$MONDAY_REPO/runtime-artifacts/scheduler-cycle/${RUN_ID}-memory-cycle.json"
JOB_REPORT_PATH="$MONDAY_REPO/runtime-artifacts/scheduler-cycle/${RUN_ID}-memory-cycle-job.json"
WORKER_OUTCOME_ARTIFACT="$MONDAY_REPO/runtime-artifacts/worker-outcome/${RUN_ID}-${QUEUE_ITEM_ID}.json"
JOB_INPUT_ARTIFACT="$MONDAY_REPO/runtime-artifacts/memory/scheduled-consolidation-job-inputs/$QUEUE_ITEM_ID.json"
WORK_ITEM_ARTIFACT="$MONDAY_REPO/runtime-artifacts/memory/scheduled-consolidation-work-items/$QUEUE_ITEM_ID.json"
QUEUE_REF_ARTIFACT="$MONDAY_REPO/runtime-artifacts/scheduler-queue/item-refs/$QUEUE_ITEM_ID.json"
trap 'rm -rf "$TMP_DIR" "$REPORT_PATH" "$CYCLE_REPORT_PATH" "$JOB_REPORT_PATH" "$WORKER_OUTCOME_ARTIFACT" "$JOB_INPUT_ARTIFACT" "$WORK_ITEM_ARTIFACT" "$QUEUE_REF_ARTIFACT"' EXIT

cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path

runner = Path("planningops/scripts/federation/run_worker_outcome_reflection_cycle.py").read_text(encoding="utf-8")
common = Path("planningops/scripts/federation/reflection_cycle_common.py").read_text(encoding="utf-8")

assert "from reflection_cycle_common import (" in runner, runner
assert "def resolve_repo_root(" not in runner, runner
assert "def resolve_workspace_root(" not in runner, runner
assert "def resolve_goal_context(" not in runner, runner
assert "def resolve_repo_root(" in common, common
assert "def resolve_workspace_root(" in common, common
assert "def resolve_goal_context(" in common, common
PY

if [[ ! -f "$MONDAY_REPO/scripts/export_scheduler_worker_outcome_reflection_packet.py" ]]; then
  echo "worker outcome reflection cycle scheduler-report test skipped: sibling monday repo unavailable"
  exit 0
fi

DB_PATH="$TMP_DIR/runtime-queue.sqlite3"
IDEMPOTENCY_PATH="$TMP_DIR/idempotency.json"
TRANSITION_LOG="$TMP_DIR/transition.ndjson"
MEMORY_ROOT="$TMP_DIR/memory-root"
JOB_INPUT="$TMP_DIR/memory-consolidation-job-input.json"
QUEUE_ADMISSION_REPORT="$TMP_DIR/memory-consolidation-admission-report.json"
GOAL_REGISTRY="$TMP_DIR/active-goal-registry.json"
PACKET_OUTPUT="$TMP_DIR/packet.json"
EVALUATION_OUTPUT="$TMP_DIR/evaluation.json"
ACTION_OUTPUT="$TMP_DIR/action.json"
REFLECTION_REPORT="$TMP_DIR/reflection-cycle-report.json"

mkdir -p "$MEMORY_ROOT"

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
    "id": "session-user:job-run-28",
    "memoryType": "session_memory",
    "tenantId": "tenant-alpha",
    "userId": "user-primary",
    "projectId": "project-runtime",
    "threadId": "thread-runtime",
    "runId": "job-run-28",
    "sessionId": "job-run-28:session:primary",
    "createdAtUtc": "2026-03-25T06:00:02.000Z",
    "updatedAtUtc": "2026-03-25T06:00:02.000Z",
    "role": "user",
    "content": "I prefer concise markdown summaries. Please prepare the blocker note.",
    "tokenCount": 11
  },
  {
    "schemaVersion": 1,
    "id": "session-assistant:job-run-28",
    "memoryType": "session_memory",
    "tenantId": "tenant-alpha",
    "userId": "user-primary",
    "projectId": "project-runtime",
    "threadId": "thread-runtime",
    "runId": "job-run-28",
    "sessionId": "job-run-28:session:primary",
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
    "missionId": "job-mission-28",
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
    "missionId": "job-mission-28",
    "objective": "I prefer concise markdown summaries. Please prepare the blocker note.",
    "runId": "job-run-28",
    "sessionId": "job-run-28:session:primary",
    "startingPhase": "plan",
    "createdAtUtc": "2026-03-25T06:00:02.000Z"
  },
  "handoff": {
    "handoffId": "job-run-28:handoff:task:1",
    "taskId": "job-mission-28:task:1"
  },
  "outcome": {
    "resultType": "complete",
    "outputText": "Still blocked on finance sign-off for the release. Keep the update short.",
    "reasonCode": "reflection_cycle_scheduler_report_test"
  },
  "policy": {
    "maxUnsummarizedTurns": 1,
    "promoteExplicitPreferences": true,
    "consolidatedAtUtc": "2026-03-25T06:00:10.000Z"
  },
  "generatedAtUtc": "2026-03-25T06:00:11.000Z"
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
    --report "$REPORT_PATH" \
    --transition-log "$TRANSITION_LOG" >/dev/null
)

cat >"$GOAL_REGISTRY" <<'JSON'
{
  "registry_version": 1,
  "active_goal_key": "agent-memory-consolidation:job-mission-28",
  "goals": [
    {
      "goal_key": "agent-memory-consolidation:job-mission-28",
      "title": "MONDAY agent memory scheduled consolidation reflection",
      "status": "active",
      "owner_repo": "rather-not-work-on/platform-planningops",
      "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-25-monday-agent-memory-wave-g-reflection-packet.md",
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

python3 planningops/scripts/run_worker_outcome_reflection_cycle.py \
  --workspace-root .. \
  --scheduler-report-json "$REPORT_PATH" \
  --active-goal-registry "$GOAL_REGISTRY" \
  --goal-key "agent-memory-consolidation:job-mission-28" \
  --run-id "test-reflection-cycle-memory-scheduler-report" \
  --packet-output "$PACKET_OUTPUT" \
  --evaluation-output "$EVALUATION_OUTPUT" \
  --action-output "$ACTION_OUTPUT" \
  --output "$REFLECTION_REPORT" >/dev/null

python3 - "$REPORT_PATH" "$PACKET_OUTPUT" "$EVALUATION_OUTPUT" "$ACTION_OUTPUT" "$REFLECTION_REPORT" <<'PY'
import json
import sys
from pathlib import Path

scheduler_report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
packet = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
evaluation = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
action = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))

expected_source_outcome_ref = (
    "runtime-artifacts/worker-outcome/"
    "test-wave28-memory-reflection-cycle-memory-consolidation-job-mission-28-job-run-28.json"
)

assert scheduler_report["worker_outcome_ref"] == expected_source_outcome_ref, scheduler_report
assert report["verdict"] == "pass", report
assert report["source_outcome_ref"] == expected_source_outcome_ref, report
assert report["reflection_decision"] == "goal_achieved", report
assert report["control_plane_action"] == "evaluate_goal_completion", report
assert report["action_kind"] == "prepare_goal_completion", report
assert report["delivery_required"] is True, report
assert report["goal_transition_required"] is True, report
assert report["goal_transition_report_path"] == "-", report
assert [row["stage"] for row in report["stage_reports"]] == [
    "packet_export",
    "reflection_evaluation",
    "reflection_action_application",
], report
assert all(row["verdict"] == "pass" for row in report["stage_reports"]), report
assert report["stage_reports"][0]["command"][1] == "scripts/export_scheduler_worker_outcome_reflection_packet.py", report

assert packet["source_outcome_ref"] == expected_source_outcome_ref, packet
assert packet["reflection_hints"]["outcome_class"] == "completion", packet
assert evaluation["verdict"] == "pass", evaluation
assert evaluation["reflection_decision"] == "goal_achieved", evaluation
assert evaluation["control_plane_action"] == "evaluate_goal_completion", evaluation
assert action["reflection_decision"] == "goal_achieved", action
assert action["action_kind"] == "prepare_goal_completion", action
PY

echo "worker outcome reflection cycle scheduler report test passed"
