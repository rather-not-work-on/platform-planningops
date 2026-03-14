#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
MONDAY_REPO="$WORKSPACE_ROOT/monday"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"

if [[ ! -f "$MONDAY_REPO/scripts/export_worker_outcome_reflection_packet.py" ]]; then
  echo "worker outcome reflection cycle test skipped: sibling monday repo unavailable"
  exit 0
fi

python3 - "$TMP_DIR/registry.json" <<'PY'
import json
import sys
from pathlib import Path

source = Path("planningops/config/active-goal-registry.json")
doc = json.loads(source.read_text(encoding="utf-8"))
doc["active_goal_key"] = "uap-goal-driven-autonomy-wave6"
for goal in doc["goals"]:
    key = goal["goal_key"]
    if key == "uap-goal-driven-autonomy-wave6":
        goal["status"] = "active"
    elif key == "uap-goal-driven-autonomy-wave7":
        goal["status"] = "draft"
    elif goal.get("status") == "active":
        goal["status"] = "draft"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

for scenario in completed retry-wait dead-letter; do
  SCENARIO_DIR="$TMP_DIR/$scenario"
  mkdir -p "$SCENARIO_DIR"
  python3 planningops/scripts/run_worker_outcome_reflection_cycle.py \
    --workspace-root .. \
    --outcome-json "monday/fixtures/runtime-queue-worker-outcome.${scenario}.sample.json" \
    --active-goal-registry "$TMP_DIR/registry.json" \
    --goal-key uap-goal-driven-autonomy-wave6 \
    --run-id "test-reflection-cycle-${scenario}" \
    --packet-output "$SCENARIO_DIR/packet.json" \
    --evaluation-output "$SCENARIO_DIR/evaluation.json" \
    --action-output "$SCENARIO_DIR/action.json" \
    --output "$SCENARIO_DIR/report.json" >/dev/null
done

python3 - "$TMP_DIR/completed/report.json" "$TMP_DIR/completed/action.json" "$TMP_DIR/retry-wait/report.json" "$TMP_DIR/retry-wait/action.json" "$TMP_DIR/dead-letter/report.json" "$TMP_DIR/dead-letter/action.json" <<'PY'
import json
import sys
from pathlib import Path

completed_report = json.loads(Path(sys.argv[1]).read_text())
completed_action = json.loads(Path(sys.argv[2]).read_text())
retry_report = json.loads(Path(sys.argv[3]).read_text())
retry_action = json.loads(Path(sys.argv[4]).read_text())
dead_letter_report = json.loads(Path(sys.argv[5]).read_text())
dead_letter_action = json.loads(Path(sys.argv[6]).read_text())

for report in [completed_report, retry_report, dead_letter_report]:
    assert report["verdict"] == "pass", report
    assert report["runner_contract_ref"] == "planningops/contracts/reflection-cycle-orchestration-contract.md", report
    assert len(report["stage_reports"]) == 3, report
    assert [row["stage"] for row in report["stage_reports"]] == [
        "packet_export",
        "reflection_evaluation",
        "reflection_action_application",
    ], report
    assert all(row["verdict"] == "pass" for row in report["stage_reports"]), report

assert completed_report["reflection_decision"] == "goal_achieved", completed_report
assert completed_report["action_kind"] == "prepare_goal_completion", completed_report
assert completed_report["delivery_required"] is True, completed_report
assert completed_report["goal_transition_required"] is True, completed_report
assert completed_report["goal_transition_report_path"] == "-", completed_report
assert completed_action["operator_channel_kind"] == "email_cli", completed_action

assert retry_report["reflection_decision"] == "continue", retry_report
assert retry_report["action_kind"] == "record_continue", retry_report
assert retry_report["delivery_required"] is False, retry_report
assert retry_report["goal_transition_required"] is False, retry_report
assert retry_action["operator_channel_kind"] == "-", retry_action

assert dead_letter_report["reflection_decision"] == "replan_required", dead_letter_report
assert dead_letter_report["action_kind"] == "trigger_replan_review", dead_letter_report
assert dead_letter_report["delivery_required"] is True, dead_letter_report
assert dead_letter_report["goal_transition_required"] is False, dead_letter_report
assert dead_letter_action["operator_channel_kind"] == "slack_skill_cli", dead_letter_action

print("worker outcome reflection cycle test passed")
PY
