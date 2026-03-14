#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/scheduled-worker-outcome-handoff-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Scheduled Worker-Outcome Handoff Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Handoff Scope",
    "## Required Handoff Artifact",
    "## Scheduled Evidence Integration",
    "## Consumer Rules",
    "## Deterministic Mapping Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/run_scheduled_queue_cycle.py",
    "platform-contracts/schemas/runtime-queue-worker-outcome.schema.json",
    "monday/scripts/export_worker_outcome_reflection_packet.py",
    "planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py",
    "planningops/contracts/scheduled-reflection-delivery-cycle-contract.md",
    "planningops/contracts/worker-outcome-reflection-contract.md",
    "`worker_outcome_handoff_ref`",
    "`worker_outcome_handoff_contract_ref`",
    "`handoff_required`",
    "`source_worker_outcome_ref`",
    "`scheduled_run_id`",
    "must not require an explicit `--worker-outcome-json` input",
    "queue lease heartbeat logic",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("scheduled worker outcome handoff contract ok")
PY
