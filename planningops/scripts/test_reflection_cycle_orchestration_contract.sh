#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/reflection-cycle-orchestration-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Reflection Cycle Orchestration Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Cycle Scope",
    "## Required Inputs",
    "## Required Outputs",
    "## Cycle Report",
    "## Deterministic Orchestration Rules",
    "## Failure Rules",
    "## Ownership Boundary",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/export_worker_outcome_reflection_packet.py",
    "planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py",
    "planningops/scripts/core/goals/apply_worker_outcome_reflection.py",
    "planningops/scripts/federation/run_worker_outcome_reflection_cycle.py",
    "monday/scripts/send_reflection_decision_update.py",
    "`generated_at_utc`",
    "`reflection_packet_ref`",
    "`reflection_evaluation_ref`",
    "`reflection_action_ref`",
    "`goal_transition_report_path`",
    "`dry-run` or `apply`",
    "must call the monday exporter instead of recreating packet logic inside planningops",
    "must not own",
    "concrete Slack or email transport execution",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("reflection cycle orchestration contract ok")
PY
