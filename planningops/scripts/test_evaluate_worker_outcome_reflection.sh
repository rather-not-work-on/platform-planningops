#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.completed.sample.json \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/completed-eval.json" >/dev/null

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.retry.sample.json \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/retry-eval.json" >/dev/null

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.dead-letter.sample.json \
  --goal-key uap-goal-driven-autonomy-wave7 \
  --output "$TMP_DIR/dead-letter-eval.json" >/dev/null

python3 planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py \
  --packet-json planningops/fixtures/worker-outcome-reflection-packet.goal-mismatch.sample.json \
  --output "$TMP_DIR/goal-mismatch-eval.json" >/dev/null

python3 - "$TMP_DIR/completed-eval.json" "$TMP_DIR/retry-eval.json" "$TMP_DIR/dead-letter-eval.json" "$TMP_DIR/goal-mismatch-eval.json" <<'PY'
import json
import sys
from pathlib import Path

completed = json.loads(Path(sys.argv[1]).read_text())
retry = json.loads(Path(sys.argv[2]).read_text())
dead_letter = json.loads(Path(sys.argv[3]).read_text())
goal_mismatch = json.loads(Path(sys.argv[4]).read_text())

assert completed["verdict"] == "pass", completed
assert completed["reflection_decision"] == "goal_achieved", completed
assert completed["control_plane_action"] == "evaluate_goal_completion", completed

assert retry["verdict"] == "pass", retry
assert retry["reflection_decision"] == "continue", retry
assert retry["control_plane_action"] == "none", retry

assert dead_letter["verdict"] == "pass", dead_letter
assert dead_letter["reflection_decision"] == "replan_required", dead_letter
assert dead_letter["control_plane_action"] == "replan_backlog", dead_letter

assert goal_mismatch["verdict"] == "pass", goal_mismatch
assert goal_mismatch["reflection_decision"] == "operator_notify", goal_mismatch
assert goal_mismatch["control_plane_action"] == "notify_operator", goal_mismatch

print("evaluate worker outcome reflection test passed")
PY
