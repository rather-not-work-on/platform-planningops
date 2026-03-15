#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/scheduled-delivery-queue-admission-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Scheduled Delivery Queue Admission Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Primary Recurring Path",
    "## Required Inputs",
    "## Required Admission Outputs",
    "## Deterministic Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "planningops/scripts/federation/run_reflection_delivery_cycle.py",
    "planningops/scripts/autonomous_supervisor_loop.py",
    "monday/scripts/enqueue_scheduled_delivery_work_item.py",
    "monday/scripts/scheduler_delivery_cycle_work_items.py",
    "monday/scripts/run_scheduled_queue_cycle.py",
    "`delivery_work_item_kind`",
    "`selected_delivery_entrypoint`",
    "`scheduled_delivery_work_item_ref`",
    "`scheduled_queue_item_ref`",
    "`queue_item_id`",
    "`delivery_idempotency_key`",
    "must not invoke:",
    "`planningops` must not provide monday-owned queue mutation fields",
    "must not bypass scheduled queue execution by directly invoking delivery-cycle entrypoints",
    "review must fail if recurring delivery evidence still shows direct planningops invocation",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("scheduled delivery queue admission contract ok")
PY
