#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/scheduled-queue-admission-handoff-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Scheduled Queue Admission Handoff Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Handoff Scope",
    "## Required Admission Packet",
    "## Consumer Rules",
    "## Store-Only Scheduled Execution Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py",
    "monday/scripts/admit_scheduled_queue_packet.py",
    "monday/scripts/run_scheduled_queue_cycle.py",
    "monday/scripts/runtime_queue_store.py",
    "platform-contracts/schemas/runtime-scheduler-queue-item.schema.json",
    "`queue_seed_ref`",
    "`seed_item_count`",
    "`admission_contract_ref`",
    "must not forward a direct `--queue` seed input",
    "must use queue admission plus store-only scheduled execution",
    "queue row insertion into monday storage",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("scheduled queue admission handoff contract ok")
PY
