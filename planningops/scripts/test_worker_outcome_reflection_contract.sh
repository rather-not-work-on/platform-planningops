#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/worker-outcome-reflection-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Worker Outcome Reflection Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Reflection Packet Envelope",
    "## Decision Vocabulary",
    "## Deterministic Mapping Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "platform-contracts/schemas/runtime-queue-worker-outcome.schema.json",
    "monday/scripts/export_worker_outcome_reflection_packet.py",
    "planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py",
    "`packet_version`",
    "`reflection_hints`",
    "`continue`",
    "`replan_required`",
    "`goal_achieved`",
    "`operator_notify`",
    "PlanningOps must not own",
    "queue lease updates",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("worker outcome reflection contract ok")
PY
