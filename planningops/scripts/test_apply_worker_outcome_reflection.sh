#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"

python3 - "$TMP_DIR/registry-wave7-active.json" "$TMP_DIR/registry-wave7-active-apply.json" <<'PY'
import json
import sys
from pathlib import Path

source = Path("planningops/config/active-goal-registry.json")
doc = json.loads(source.read_text(encoding="utf-8"))
doc["active_goal_key"] = "uap-goal-driven-autonomy-wave7"
for goal in doc["goals"]:
    key = goal["goal_key"]
    if key == "uap-goal-driven-autonomy-wave7":
        goal["status"] = "active"
    elif key == "uap-goal-driven-autonomy-wave8":
        goal["status"] = "draft"
    elif key == "uap-goal-driven-autonomy-wave6":
        goal["status"] = "achieved"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.completed.sample.json \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/completed-eval.json" >/dev/null

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.retry.sample.json \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/retry-eval.json" >/dev/null

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.dead-letter.sample.json \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/dead-letter-eval.json" >/dev/null

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.goal-mismatch.sample.json \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/goal-mismatch-eval.json" >/dev/null

python3 planningops/scripts/core/goals/apply_worker_outcome_reflection.py \
  --evaluation-json "$TMP_DIR/completed-eval.json" \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/completed-action-dry.json" >/dev/null

python3 planningops/scripts/core/goals/apply_worker_outcome_reflection.py \
  --evaluation-json "$TMP_DIR/retry-eval.json" \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/retry-action.json" >/dev/null

python3 planningops/scripts/core/goals/apply_worker_outcome_reflection.py \
  --evaluation-json "$TMP_DIR/dead-letter-eval.json" \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/dead-letter-action.json" >/dev/null

python3 planningops/scripts/core/goals/apply_worker_outcome_reflection.py \
  --evaluation-json "$TMP_DIR/goal-mismatch-eval.json" \
  --active-goal-registry "$TMP_DIR/registry-wave7-active.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/goal-mismatch-action.json" >/dev/null

python3 planningops/scripts/core/goals/apply_worker_outcome_reflection.py \
  --evaluation-json "$TMP_DIR/completed-eval.json" \
  --active-goal-registry "$TMP_DIR/registry-wave7-active-apply.json" \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --mode apply \
  --output "$TMP_DIR/completed-action-apply.json" >/dev/null

python3 - "$TMP_DIR/completed-action-dry.json" "$TMP_DIR/retry-action.json" "$TMP_DIR/dead-letter-action.json" "$TMP_DIR/goal-mismatch-action.json" "$TMP_DIR/completed-action-apply.json" "$TMP_DIR/registry-wave7-active-apply.json" <<'PY'
import json
import sys
from pathlib import Path

completed_dry = json.loads(Path(sys.argv[1]).read_text())
retry = json.loads(Path(sys.argv[2]).read_text())
dead_letter = json.loads(Path(sys.argv[3]).read_text())
goal_mismatch = json.loads(Path(sys.argv[4]).read_text())
completed_apply = json.loads(Path(sys.argv[5]).read_text())
apply_registry = json.loads(Path(sys.argv[6]).read_text())

assert completed_dry["verdict"] == "pass", completed_dry
assert completed_dry["action_kind"] == "prepare_goal_completion", completed_dry
assert completed_dry["message_class_hint"] == "goal_completed", completed_dry
assert completed_dry["operator_channel_role"] == "terminal_notification_channel", completed_dry
assert completed_dry["operator_channel_kind"] == "email_cli", completed_dry
assert completed_dry["goal_transition_required"] is True, completed_dry
assert completed_dry["requested_goal_status"] == "achieved", completed_dry
assert completed_dry["goal_transition_report_path"] == "-", completed_dry

assert retry["verdict"] == "pass", retry
assert retry["action_kind"] == "record_continue", retry
assert retry["delivery_required"] is False, retry
assert retry["operator_channel_role"] == "none", retry
assert retry["operator_channel_kind"] == "-", retry
assert retry["message_class_hint"] == "status_update", retry

assert dead_letter["verdict"] == "pass", dead_letter
assert dead_letter["action_kind"] == "trigger_replan_review", dead_letter
assert dead_letter["message_class_hint"] == "decision_request", dead_letter
assert dead_letter["operator_channel_role"] == "primary_operator_channel", dead_letter
assert dead_letter["operator_channel_kind"] == "slack_skill_cli", dead_letter

assert goal_mismatch["verdict"] == "pass", goal_mismatch
assert goal_mismatch["action_kind"] == "escalate_operator_attention", goal_mismatch
assert goal_mismatch["message_class_hint"] == "blocked_report", goal_mismatch
assert goal_mismatch["operator_channel_role"] == "primary_operator_channel", goal_mismatch

assert completed_apply["verdict"] == "pass", completed_apply
assert completed_apply["goal_transition_report_path"] != "-", completed_apply
transition_report = Path(completed_apply["goal_transition_report_path"])
assert transition_report.exists(), transition_report
transition = json.loads(transition_report.read_text())
assert transition["verdict"] == "pass", transition
assert apply_registry["active_goal_key"] == "", apply_registry
wave7 = next(goal for goal in apply_registry["goals"] if goal["goal_key"] == "uap-goal-driven-autonomy-wave7")
assert wave7["status"] == "achieved", wave7

print("apply worker outcome reflection test passed")
PY
