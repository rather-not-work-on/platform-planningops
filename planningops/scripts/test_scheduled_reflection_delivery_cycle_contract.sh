#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/scheduled-reflection-delivery-cycle-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Scheduled Reflection Delivery Cycle Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Cycle Scope",
    "## Required Inputs",
    "## Required Outputs",
    "## Stage Reports",
    "## Deterministic Orchestration Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/admit_scheduled_queue_packet.py",
    "planningops/contracts/scheduled-queue-admission-handoff-contract.md",
    "monday/scripts/run_scheduled_queue_cycle.py",
    "planningops/contracts/scheduler-native-worker-outcome-selection-contract.md",
    "planningops/contracts/scheduled-worker-outcome-handoff-contract.md",
    "monday/scripts/export_worker_outcome_reflection_packet.py",
    "planningops/scripts/federation/run_worker_outcome_reflection_cycle.py",
    "planningops/scripts/federation/run_reflection_delivery_cycle.py",
    "planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py",
    "planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md",
    "planningops/contracts/reflection-cycle-orchestration-contract.md",
    "planningops/contracts/reflection-delivery-cycle-contract.md",
    "`--queue`",
    "`--worker-outcome-root`",
    "`queue_admission_report_ref`",
    "`scheduled_cycle_report_ref`",
    "`worker_outcome_ref`",
    "`worker_outcome_handoff_ref`",
    "`reflection_cycle_report_ref`",
    "`delivery_cycle_report_ref`",
    "`goal_transition_report_path`",
    "`queue_admission`",
    "`scheduled_queue_cycle`",
    "`reflection_cycle`",
    "`delivery_cycle`",
    "must invoke `monday/scripts/admit_scheduled_queue_packet.py` before `monday/scripts/run_scheduled_queue_cycle.py`",
    "queue row mutation or lease heartbeat logic",
    "must not supply a canonical worker outcome file path",
    "must not forward a direct `--queue` seed input into monday scheduled execution",
    "must not require `--worker-outcome-json` for the primary path",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("scheduled reflection delivery cycle contract ok")
PY
