#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/local-operator-target-resolution-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Local Operator Target Resolution Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Resolution Scope",
    "## Required Local Profile Document",
    "## Required Delivery Evidence",
    "## Deterministic Resolution Rules",
    "## Local Outbox Rules",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/operator_channel_local_outbox.py",
    "monday/scripts/send_operator_message.py",
    "monday/scripts/send_goal_completion_notification.py",
    "monday/scripts/send_reflection_decision_update.py",
    "monday/scripts/send_supervisor_goal_completion.py",
    "monday/config/local-operator-channel-profiles.json",
    "`target_resolution_mode`",
    "`target_profile_ref`",
    "`local_outbox`",
    "planningops must never resolve a concrete `delivery_target`",
    "must fail closed when `channel_kind` has no matching local profile",
    "must remain inside the monday repo runtime-artifacts boundary",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("local operator target resolution contract ok")
PY
