#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/local-dispatch-cycle-handoff-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Local Dispatch Cycle Handoff Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Source Artifact Scope",
    "## Execution Packet Artifact",
    "## Local Dispatch Receipt Artifact",
    "## Deterministic Cycle Rules",
    "## Storage Boundary",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/export_local_dispatch_execution_packet.py",
    "monday/scripts/run_local_dispatch_cycle.py",
    "`execution_packet_version`",
    "`bridge_adapter_kind`",
    "`execution_verdict` must be one of `ready_for_local_bridge`, `already_dispatched`, or `blocked`",
    "`receipt_status` must be one of `recorded`, `already_recorded`, or `blocked`",
    "must derive the execution packet only from the dispatch packet",
    "must remain under the monday repo `runtime-artifacts/` boundary",
    "future Slack skill or terminal notifier bridge execution",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("local dispatch cycle handoff contract ok")
PY
