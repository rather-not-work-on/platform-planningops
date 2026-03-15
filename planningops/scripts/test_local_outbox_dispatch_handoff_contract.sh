#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/local-outbox-dispatch-handoff-contract.md")
text = contract.read_text(encoding="utf-8")

required_sections = [
    "# Local Outbox Dispatch Handoff Contract",
    "## Purpose",
    "## Canonical Boundary",
    "## Source Artifact Scope",
    "## Dispatch Packet Artifact",
    "## Acknowledgement Artifact",
    "## Deterministic Export Rules",
    "## Storage Boundary",
    "## Ownership Boundary",
    "## Failure Rules",
    "## Validation",
]
for section in required_sections:
    assert section in text, section

required_fragments = [
    "monday/scripts/export_local_outbox_dispatch_packet.py",
    "monday/scripts/ack_local_outbox_dispatch.py",
    "monday/scripts/operator_channel_local_outbox.py",
    "`dispatch_packet_version`",
    "`source_outbox_message_ref`",
    "`delivery_idempotency_key`",
    "`dispatch_verdict` must be one of `ready_for_dispatch`, `already_acknowledged`, or `blocked`",
    "`ack_status` must be one of `recorded`, `already_recorded`, or `blocked`",
    "must not require `planningops` to provide an explicit dispatch target",
    "must remain under the monday repo `runtime-artifacts/` boundary",
    "future Slack skill or email notifier consumption of the dispatch packet",
]
for fragment in required_fragments:
    assert fragment in text, fragment

print("local outbox dispatch handoff contract ok")
PY
