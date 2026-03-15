#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/scheduled-delivery-cycle-handoff-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Scheduled Delivery Cycle Handoff Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Primary Recurring Path",
    "## Delivery Work Item Shape",
    "## Required Outputs",
    "## Deterministic Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/run_scheduled_queue_cycle.py",
    "monday/scripts/scheduler_delivery_cycle_work_items.py",
    "monday/scripts/run_operator_message_delivery_cycle.py",
    "monday/scripts/run_goal_completion_delivery_cycle.py",
    "planningops/contracts/local-delivery-cycle-orchestration-contract.md",
    "planningops/contracts/local-delivery-cycle-entrypoint-contract.md",
    "`delivery_work_item_kind` must be one of `operator_message_delivery` or `goal_completion_delivery`",
    "`operator_message_delivery` items must not invoke `monday/scripts/run_goal_completion_delivery_cycle.py`",
    "`goal_completion_delivery` items must not invoke `monday/scripts/run_operator_message_delivery_cycle.py`",
    "planningops review must fail if recurring delivery evidence shows direct one-shot invocation from planningops",
    "`queue_item_id`",
    "`selected_delivery_entrypoint`",
    "`delivery_cycle_report_ref`",
    "`delivery_cycle_verdict`",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("scheduled delivery cycle handoff contract ok")
PY
