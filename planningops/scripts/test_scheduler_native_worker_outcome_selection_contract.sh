#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/scheduler-native-worker-outcome-selection-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Scheduler-Native Worker-Outcome Selection Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Selection Scope",
    "## Required Selector Inputs",
    "## Required Selector Output",
    "## Handoff Integration Rules",
    "## PlanningOps Consumer Expectations",
    "## Deterministic Mapping Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/run_scheduled_queue_cycle.py",
    "monday/scripts/select_scheduled_worker_outcome.py",
    "monday/contracts/runtime-scheduler-evidence.schema.json",
    "platform-contracts/schemas/runtime-queue-worker-outcome.schema.json",
    "planningops/contracts/scheduled-worker-outcome-handoff-contract.md",
    "planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py",
    "`scheduled_run_id`",
    "`source_worker_outcome_ref`",
    "`selector_contract_ref`",
    "must not require `--worker-outcome-json` for the primary path",
    "worker outcome candidate search logic",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("scheduler-native worker outcome selection contract ok")
PY
