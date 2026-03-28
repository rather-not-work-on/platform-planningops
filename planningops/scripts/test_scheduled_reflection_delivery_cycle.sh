#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
MONDAY_REPO="$WORKSPACE_ROOT/monday"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path

runner = Path("planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py").read_text(encoding="utf-8")
common = Path("planningops/scripts/federation/reflection_cycle_common.py").read_text(encoding="utf-8")

assert "from reflection_cycle_common import (" in runner, runner
assert "def resolve_repo_root(" not in runner, runner
assert "def resolve_workspace_root(" not in runner, runner
assert "def resolve_goal_context(" not in runner, runner
assert "def derive_single_queue_value(" not in runner, runner
assert "def resolve_repo_root(" in common, common
assert "def resolve_workspace_root(" in common, common
assert "def resolve_goal_context(" in common, common
assert "def derive_single_queue_value(" in common, common
PY

if [[ ! -f "$MONDAY_REPO/scripts/run_scheduled_queue_cycle.py" ]]; then
  echo "scheduled reflection delivery cycle test skipped: sibling monday repo unavailable"
  exit 0
fi

WORKER_OUTCOME_ROOT="$TMP_DIR/monday-runtime-artifacts/worker-outcome"
mkdir -p "$WORKER_OUTCOME_ROOT"

python3 - "$TMP_DIR/registry.json" <<'PY'
import json
import sys
from pathlib import Path

source = Path("planningops/config/active-goal-registry.json")
doc = json.loads(source.read_text(encoding="utf-8"))
doc["active_goal_key"] = "uap-goal-driven-autonomy-wave11"
for goal in doc["goals"]:
    key = goal["goal_key"]
    if key == "uap-goal-driven-autonomy-wave11":
        goal["status"] = "active"
    elif key == "uap-goal-driven-autonomy-wave12":
        goal["status"] = "draft"
    elif goal.get("status") == "active":
        goal["status"] = "draft"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cp "$TMP_DIR/registry.json" "$TMP_DIR/goal-completion-registry.json"

cat >"$TMP_DIR/queue.json" <<'JSON'
{
  "queue_items": [
    {
      "queue_item_id": "queue-wave11-001",
      "goal_key": "uap-goal-driven-autonomy-wave11",
      "schedule_key": "local-tick-5m",
      "state": "ready",
      "idempotency_key": "wave11:queue-wave11-001",
      "priority_class": "standard",
      "retry_budget": {
        "max_attempts": 3,
        "backoff_profile": "exponential"
      },
      "retry_budget_remaining": 2,
      "attempt_count": 1,
      "dependency_keys": [],
      "escalation_policy_ref": "planningops/contracts/escalation-gate-contract.md",
      "completion_policy_ref": "planningops/contracts/goal-completion-contract.md"
    }
  ],
  "completed_queue_item_ids": []
}
JSON

cat >"$WORKER_OUTCOME_ROOT/outcome-retry.json" <<'JSON'
{
  "transition_id": "wave11-outcome-continue",
  "queue_item_id": "queue-wave11-001",
  "goal_key": "uap-goal-driven-autonomy-wave11",
  "schedule_key": "local-tick-5m",
  "lease_owner": "monday-local-worker",
  "worker_run_id": "test-scheduled-reflection-delivery-continue-scheduled",
  "state_from": "leased",
  "state_to": "retry_wait",
  "transition_reason": "worker.retryable_failure",
  "occurred_at_utc": "2026-03-14T09:00:00Z",
  "attempt_count": 1,
  "retry_budget_remaining": 1,
  "retry_after_utc": "2099-03-14T09:10:00Z"
}
JSON

cat >"$WORKER_OUTCOME_ROOT/outcome-retry-inferred.json" <<'JSON'
{
  "transition_id": "wave11-outcome-continue-inferred",
  "queue_item_id": "queue-wave11-001",
  "goal_key": "uap-goal-driven-autonomy-wave11",
  "schedule_key": "local-tick-5m",
  "lease_owner": "monday-local-worker",
  "worker_run_id": "test-scheduled-reflection-delivery-inferred-goal-scheduled",
  "state_from": "leased",
  "state_to": "retry_wait",
  "transition_reason": "worker.retryable_failure",
  "occurred_at_utc": "2026-03-14T09:01:00Z",
  "attempt_count": 1,
  "retry_budget_remaining": 1,
  "retry_after_utc": "2099-03-14T09:11:00Z"
}
JSON

cat >"$WORKER_OUTCOME_ROOT/outcome-dead-letter.json" <<'JSON'
{
  "transition_id": "wave11-outcome-replan",
  "queue_item_id": "queue-wave11-001",
  "goal_key": "uap-goal-driven-autonomy-wave11",
  "schedule_key": "local-tick-5m",
  "lease_owner": "monday-local-worker",
  "worker_run_id": "test-scheduled-reflection-delivery-replan-scheduled",
  "state_from": "leased",
  "state_to": "dead_letter",
  "transition_reason": "worker.retry_exhausted",
  "occurred_at_utc": "2026-03-14T09:05:00Z",
  "attempt_count": 2,
  "retry_budget_remaining": 0,
  "dead_letter_reason": "retry_budget_exhausted"
}
JSON

cat >"$WORKER_OUTCOME_ROOT/outcome-dead-letter-apply.json" <<'JSON'
{
  "transition_id": "wave11-outcome-replan-apply",
  "queue_item_id": "queue-wave11-001",
  "goal_key": "uap-goal-driven-autonomy-wave11",
  "schedule_key": "local-tick-5m",
  "lease_owner": "monday-local-worker",
  "worker_run_id": "test-scheduled-reflection-delivery-replan-apply-scheduled",
  "state_from": "leased",
  "state_to": "dead_letter",
  "transition_reason": "worker.retry_exhausted",
  "occurred_at_utc": "2026-03-14T09:06:00Z",
  "attempt_count": 2,
  "retry_budget_remaining": 0,
  "dead_letter_reason": "retry_budget_exhausted"
}
JSON

cat >"$WORKER_OUTCOME_ROOT/outcome-completed-apply.json" <<'JSON'
{
  "transition_id": "wave11-outcome-completed-apply",
  "queue_item_id": "queue-wave11-001",
  "goal_key": "uap-goal-driven-autonomy-wave11",
  "schedule_key": "local-tick-5m",
  "lease_owner": "monday-local-worker",
  "worker_run_id": "test-scheduled-reflection-delivery-goal-completion-apply-scheduled",
  "state_from": "leased",
  "state_to": "completed",
  "transition_reason": "worker.completed",
  "occurred_at_utc": "2026-03-14T09:07:00Z",
  "attempt_count": 1,
  "retry_budget_remaining": 2,
  "completion_evidence_ref": "runtime-artifacts/worker-outcome/test-scheduled-reflection-delivery-goal-completion-apply-scheduled.json"
}
JSON

python3 planningops/scripts/run_scheduled_reflection_delivery_cycle.py \
  --workspace-root .. \
  --queue "$TMP_DIR/queue.json" \
  --queue-db "$TMP_DIR/continue-runtime-queue.sqlite3" \
  --worker-outcome-root "$WORKER_OUTCOME_ROOT" \
  --idempotency "$TMP_DIR/continue-idempotency.json" \
  --transition-log "$TMP_DIR/continue-transition-log.ndjson" \
  --scheduled-output "$TMP_DIR/continue-scheduled-cycle-report.json" \
  --scheduled-handoff-output "$TMP_DIR/continue-worker-outcome-handoff.json" \
  --active-goal-registry "$TMP_DIR/registry.json" \
  --goal-key uap-goal-driven-autonomy-wave11 \
  --run-id "test-scheduled-reflection-delivery-continue" \
  --output "$TMP_DIR/continue-report.json" >/dev/null

python3 planningops/scripts/run_scheduled_reflection_delivery_cycle.py \
  --workspace-root .. \
  --queue "$TMP_DIR/queue.json" \
  --queue-db "$TMP_DIR/replan-runtime-queue.sqlite3" \
  --worker-outcome-root "$WORKER_OUTCOME_ROOT" \
  --idempotency "$TMP_DIR/replan-idempotency.json" \
  --transition-log "$TMP_DIR/replan-transition-log.ndjson" \
  --scheduled-output "$TMP_DIR/replan-scheduled-cycle-report.json" \
  --scheduled-handoff-output "$TMP_DIR/replan-worker-outcome-handoff.json" \
  --active-goal-registry "$TMP_DIR/registry.json" \
  --goal-key uap-goal-driven-autonomy-wave11 \
  --delivery-target "slack://monday/wave11" \
  --thread-ref "wave11-thread" \
  --run-id "test-scheduled-reflection-delivery-replan" \
  --output "$TMP_DIR/replan-report.json" >/dev/null

python3 planningops/scripts/run_scheduled_reflection_delivery_cycle.py \
  --workspace-root .. \
  --queue "$TMP_DIR/queue.json" \
  --queue-db "$TMP_DIR/replan-apply-runtime-queue.sqlite3" \
  --worker-outcome-root "$WORKER_OUTCOME_ROOT" \
  --idempotency "$TMP_DIR/replan-apply-idempotency.json" \
  --transition-log "$TMP_DIR/replan-apply-transition-log.ndjson" \
  --scheduled-output "$TMP_DIR/replan-apply-scheduled-cycle-report.json" \
  --scheduled-handoff-output "$TMP_DIR/replan-apply-worker-outcome-handoff.json" \
  --active-goal-registry "$TMP_DIR/registry.json" \
  --goal-key uap-goal-driven-autonomy-wave11 \
  --delivery-target "slack://monday/wave11" \
  --thread-ref "wave11-thread" \
  --mode apply \
  --run-id "test-scheduled-reflection-delivery-replan-apply" \
  --output "$TMP_DIR/replan-apply-report.json" >/dev/null

python3 planningops/scripts/run_scheduled_reflection_delivery_cycle.py \
  --workspace-root .. \
  --queue "$TMP_DIR/queue.json" \
  --queue-db "$TMP_DIR/inferred-runtime-queue.sqlite3" \
  --worker-outcome-root "$WORKER_OUTCOME_ROOT" \
  --idempotency "$TMP_DIR/inferred-idempotency.json" \
  --transition-log "$TMP_DIR/inferred-transition-log.ndjson" \
  --scheduled-output "$TMP_DIR/inferred-scheduled-cycle-report.json" \
  --scheduled-handoff-output "$TMP_DIR/inferred-worker-outcome-handoff.json" \
  --active-goal-registry "$TMP_DIR/registry.json" \
  --run-id "test-scheduled-reflection-delivery-inferred-goal" \
  --output "$TMP_DIR/inferred-report.json" >/dev/null

python3 planningops/scripts/run_scheduled_reflection_delivery_cycle.py \
  --workspace-root .. \
  --queue "$TMP_DIR/queue.json" \
  --queue-db "$TMP_DIR/goal-completion-runtime-queue.sqlite3" \
  --worker-outcome-root "$WORKER_OUTCOME_ROOT" \
  --idempotency "$TMP_DIR/goal-completion-idempotency.json" \
  --transition-log "$TMP_DIR/goal-completion-transition-log.ndjson" \
  --scheduled-output "$TMP_DIR/goal-completion-scheduled-cycle-report.json" \
  --scheduled-handoff-output "$TMP_DIR/goal-completion-worker-outcome-handoff.json" \
  --active-goal-registry "$TMP_DIR/goal-completion-registry.json" \
  --goal-key uap-goal-driven-autonomy-wave11 \
  --mode apply \
  --run-id "test-scheduled-reflection-delivery-goal-completion-apply" \
  --output "$TMP_DIR/goal-completion-report.json" >/dev/null

python3 - "$TMP_DIR/no-active-registry.json" <<'PY'
import json
import sys
from pathlib import Path

source = Path("planningops/config/active-goal-registry.json")
doc = json.loads(source.read_text(encoding="utf-8"))
doc["active_goal_key"] = ""
for goal in doc["goals"]:
    if goal.get("status") == "active":
        goal["status"] = "achieved"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 planningops/scripts/run_scheduled_reflection_delivery_cycle.py \
  --workspace-root .. \
  --queue "$TMP_DIR/queue.json" \
  --queue-db "$TMP_DIR/no-active-runtime-queue.sqlite3" \
  --worker-outcome-root "$WORKER_OUTCOME_ROOT" \
  --idempotency "$TMP_DIR/no-active-idempotency.json" \
  --transition-log "$TMP_DIR/no-active-transition-log.ndjson" \
  --scheduled-output "$TMP_DIR/no-active-scheduled-cycle-report.json" \
  --scheduled-handoff-output "$TMP_DIR/no-active-worker-outcome-handoff.json" \
  --active-goal-registry "$TMP_DIR/no-active-registry.json" \
  --run-id "test-scheduled-reflection-delivery-no-active-goal" \
  --output "$TMP_DIR/no-active-report.json" >/dev/null 2>&1 || true

python3 - "$TMP_DIR/continue-report.json" "$TMP_DIR/replan-report.json" "$TMP_DIR/replan-apply-report.json" "$TMP_DIR/no-active-report.json" "$TMP_DIR/inferred-report.json" "$TMP_DIR/goal-completion-report.json" "$TMP_DIR/goal-completion-registry.json" <<'PY'
import json
import sys
from pathlib import Path

continue_report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
replan_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
replan_apply_report = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
no_active_report = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
inferred_report = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))
goal_completion_report = json.loads(Path(sys.argv[6]).read_text(encoding="utf-8"))
goal_completion_registry = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))

for report in [continue_report, replan_report]:
    assert report["verdict"] == "pass", report
    assert report["goal_key"] == "uap-goal-driven-autonomy-wave11", report
    assert report["queue_admission_report_ref"].endswith("queue-admission-report.json"), report
    assert report["scheduled_cycle_report_ref"].endswith("scheduled-cycle-report.json"), report
    assert report["reflection_cycle_report_ref"].endswith("reflection-cycle-report.json"), report
    assert report["delivery_cycle_report_ref"].endswith("delivery-cycle-report.json"), report
    assert report["worker_outcome_ref"].endswith(".json"), report
    assert [row["stage"] for row in report["stage_reports"]] == [
        "queue_admission",
        "scheduled_queue_cycle",
        "reflection_cycle",
        "delivery_cycle",
    ], report
    assert all(row["verdict"] == "pass" for row in report["stage_reports"]), report
    scheduled_report = json.loads(Path(report["scheduled_cycle_report_ref"]).read_text(encoding="utf-8"))
    assert scheduled_report["handoff_required"] is True, scheduled_report
    assert scheduled_report["worker_outcome_handoff_ref"].endswith("worker-outcome-handoff.json"), scheduled_report
    assert (
        scheduled_report["worker_outcome_handoff_contract_ref"]
        == "planningops/contracts/scheduled-worker-outcome-handoff-contract.md"
    ), scheduled_report

assert continue_report["reflection_decision"] == "continue", continue_report
assert continue_report["action_kind"] == "record_continue", continue_report
assert continue_report["delivery_required"] is False, continue_report
assert continue_report["delivery_skipped"] is True, continue_report
assert continue_report["goal_transition_required"] is False, continue_report
assert continue_report["goal_transition_report_path"] == "-", continue_report

assert replan_report["reflection_decision"] == "replan_required", replan_report
assert replan_report["action_kind"] == "trigger_replan_review", replan_report
assert replan_report["delivery_required"] is True, replan_report
assert replan_report["delivery_skipped"] is False, replan_report
assert replan_report["goal_transition_required"] is False, replan_report

assert replan_apply_report["verdict"] == "pass", replan_apply_report
assert replan_apply_report["queue_admission_report_ref"].endswith("queue-admission-report.json"), replan_apply_report
assert [row["stage"] for row in replan_apply_report["stage_reports"]] == [
    "queue_admission",
    "scheduled_queue_cycle",
    "reflection_cycle",
    "delivery_cycle",
], replan_apply_report
assert replan_apply_report["stage_reports"][0]["verdict"] == "pass", replan_apply_report
assert replan_apply_report["stage_reports"][1]["verdict"] == "pass", replan_apply_report
assert replan_apply_report["stage_reports"][2]["verdict"] == "pass", replan_apply_report
assert replan_apply_report["stage_reports"][3]["verdict"] == "pass", replan_apply_report

replan_delivery_report = json.loads(Path(replan_report["delivery_cycle_report_ref"]).read_text(encoding="utf-8"))
assert replan_delivery_report["delivery_verdict"] == "dry_run", replan_delivery_report
assert replan_delivery_report["queue_admission_verdict"] == "pass", replan_delivery_report
assert replan_delivery_report["selected_delivery_entrypoint"] == "scripts/run_operator_message_delivery_cycle.py", replan_delivery_report
assert "--schedule-key" in replan_delivery_report["stage_reports"][0]["command"], replan_delivery_report
assert "local-tick-5m" in replan_delivery_report["stage_reports"][0]["command"], replan_delivery_report

replan_apply_delivery_report = json.loads(Path(replan_apply_report["delivery_cycle_report_ref"]).read_text(encoding="utf-8"))
assert replan_apply_delivery_report["delivery_verdict"] == "queued", replan_apply_delivery_report
assert replan_apply_delivery_report["queue_admission_verdict"] == "pass", replan_apply_delivery_report
assert replan_apply_delivery_report["selected_delivery_entrypoint"] == "scripts/run_operator_message_delivery_cycle.py", replan_apply_delivery_report
assert replan_apply_delivery_report["scheduled_queue_item_ref"].startswith(
    "monday/runtime-artifacts/scheduler-queue/item-refs/"
), replan_apply_delivery_report
assert replan_apply_delivery_report["scheduled_queue_item_ref"].endswith(
    f"{replan_apply_delivery_report['scheduled_queue_item_id']}.json"
), replan_apply_delivery_report
assert "--schedule-key" in replan_apply_delivery_report["stage_reports"][0]["command"], replan_apply_delivery_report
assert "local-tick-5m" in replan_apply_delivery_report["stage_reports"][0]["command"], replan_apply_delivery_report

assert inferred_report["verdict"] == "pass", inferred_report
assert inferred_report["goal_key"] == "uap-goal-driven-autonomy-wave11", inferred_report
assert "--goal-key" in inferred_report["stage_reports"][2]["command"], inferred_report
assert "uap-goal-driven-autonomy-wave11" in inferred_report["stage_reports"][2]["command"], inferred_report

assert goal_completion_report["verdict"] == "pass", goal_completion_report
assert goal_completion_report["reflection_decision"] == "goal_achieved", goal_completion_report
assert goal_completion_report["action_kind"] == "prepare_goal_completion", goal_completion_report
assert goal_completion_report["delivery_required"] is True, goal_completion_report
assert goal_completion_report["delivery_skipped"] is False, goal_completion_report
assert goal_completion_report["goal_transition_required"] is True, goal_completion_report
assert goal_completion_report["goal_transition_report_path"] != "-", goal_completion_report
assert [row["stage"] for row in goal_completion_report["stage_reports"]] == [
    "queue_admission",
    "scheduled_queue_cycle",
    "reflection_cycle",
    "delivery_cycle",
], goal_completion_report
assert all(row["verdict"] == "pass" for row in goal_completion_report["stage_reports"]), goal_completion_report
goal_completion_delivery_report = json.loads(Path(goal_completion_report["delivery_cycle_report_ref"]).read_text(encoding="utf-8"))
assert goal_completion_delivery_report["verdict"] == "pass", goal_completion_delivery_report
assert goal_completion_delivery_report["goal_completion_delivery_verdict"] == "queued", goal_completion_delivery_report
assert goal_completion_delivery_report["queue_admission_verdict"] == "pass", goal_completion_delivery_report
assert goal_completion_delivery_report["selected_delivery_entrypoint"] == "scripts/run_goal_completion_delivery_cycle.py", goal_completion_delivery_report
assert "run_reflection_goal_completion_handoff_cycle.py" in goal_completion_report["stage_reports"][3]["command"][1], goal_completion_report
assert goal_completion_registry["active_goal_key"] == "", goal_completion_registry
goal_completion_goal = next(goal for goal in goal_completion_registry["goals"] if goal["goal_key"] == "uap-goal-driven-autonomy-wave11")
assert goal_completion_goal["status"] == "achieved", goal_completion_goal

assert no_active_report["verdict"] == "fail", no_active_report
assert no_active_report["failure_stage"] == "resolve_goal_context", no_active_report
assert no_active_report["stage_reports"] == [], no_active_report
assert "no active goal configured" in no_active_report["errors"], no_active_report

print("scheduled reflection delivery cycle test passed")
PY
