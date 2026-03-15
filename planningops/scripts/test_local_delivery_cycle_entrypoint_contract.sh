#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/local-delivery-cycle-entrypoint-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Local Delivery Cycle Entrypoint Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Source Artifact Scope",
    "## Aggregate Delivery Cycle Report",
    "## Deterministic Entrypoint Rules",
    "## Storage Boundary",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/run_operator_message_delivery_cycle.py",
    "monday/scripts/run_goal_completion_delivery_cycle.py",
    "`delivery_cycle_report_version`",
    "`delivery_report_ref`",
    "`dispatch_packet_ref`",
    "`execution_packet_ref`",
    "`ack_checkpoint_ref`",
    "`dispatch_receipt_ref`",
    "`cycle_status` must be one of `recorded`, `already_recorded`, `dry_run`, `blocked`, or `no_ready_dispatch_packet`",
    "must run delivery CLI -> dispatch packet export -> dispatch cycle in-order",
    "must remain under the monday repo `runtime-artifacts/` boundary",
    "aggregate delivery cycle report emission",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("local delivery cycle entrypoint contract ok")
PY
