#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/reflection-action-handoff-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Reflection Action Handoff Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Action Artifact",
    "## Action Kind Vocabulary",
    "## Operator Channel Role Vocabulary",
    "## Deterministic Mapping Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py",
    "planningops/scripts/core/goals/apply_worker_outcome_reflection.py",
    "monday/scripts/send_reflection_decision_update.py",
    "`record_continue`",
    "`trigger_replan_review`",
    "`prepare_goal_completion`",
    "`escalate_operator_attention`",
    "`primary_operator_channel`",
    "`terminal_notification_channel`",
    "`operator_channel_kind`",
    "`goal_transition_report_path`",
    "`requested_goal_status = achieved`",
    "## Channel Policy Projection Rules",
    "## Goal Transition Rules",
    "PlanningOps must not own",
    "concrete Slack channel IDs",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("reflection action handoff contract ok")
PY
