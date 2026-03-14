#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Autonomous Scheduler Queue Control-Plane Contract",
    "## Purpose",
    "## Ownership Boundary",
    "## Queue State Model",
    "## Scheduling Trigger Model",
    "## Required Queue Policy Fields",
    "## Reflection and Escalation Rules",
    "## Operator Channel Boundary",
    "## Local-First Runtime Rule",
    "## Migration Rule",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "PlanningOps must not own",
    "Monday owns",
    "Platform-Contracts owns",
    "`scheduled`",
    "`dead_letter`",
    "recurring schedule tick",
    "retry-after wake",
    "SQLite in `monday`",
    "Codex recurring automation is a temporary host only.",
    "planningops/contracts/operator-channel-adapter-contract.md",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("autonomous scheduler queue control-plane contract ok")
PY
