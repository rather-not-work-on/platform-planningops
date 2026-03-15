#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/reflection-delivery-cycle-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Reflection Delivery Cycle Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Cycle Scope",
    "## Required Inputs",
    "## Delivery Invocation",
    "## Required Outputs",
    "## Cycle Report",
    "## Deterministic Orchestration Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "planningops/scripts/core/goals/apply_worker_outcome_reflection.py",
    "planningops/scripts/federation/run_reflection_delivery_cycle.py",
    "monday/scripts/run_operator_message_delivery_cycle.py",
    "planningops/contracts/reflection-action-handoff-contract.md",
    "planningops/contracts/operator-channel-adapter-contract.md",
    "planningops/contracts/local-operator-target-resolution-contract.md",
    "`reflection_action_ref`",
    "`monday_delivery_report_ref`",
    "`delivery_verdict`",
    "`delivery_target_resolution_mode`",
    "`delivery_target_profile_ref`",
    "`delivery_transport_kind`",
    "`delivery_outbox_message_ref`",
    "`goal_transition_report_path`",
    "`delivery_skipped = true`",
    "`dry-run` or `apply`",
    "must not call:",
    "concrete Slack or email transport execution",
    "must work without a caller-supplied concrete `delivery-target`",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("reflection delivery cycle contract ok")
PY
