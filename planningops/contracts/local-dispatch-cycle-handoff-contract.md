# Local Dispatch Cycle Handoff Contract

## Purpose
Define the deterministic handoff between monday-owned dispatch packets and the next monday-owned local dispatch cycle artifacts that future Slack skill and terminal notifier adapters can consume.

This contract exists so:
- `planningops` can orchestrate and review dispatch behavior without owning runtime dispatch mutation
- `monday` can turn one ready dispatch packet into one execution packet and one local dispatch receipt
- future Slack skill or email notifier adapters can consume monday-owned execution packets instead of polling raw dispatch directories or control-plane artifacts

## Canonical Boundary
- operator policy contract: `planningops/contracts/operator-channel-adapter-contract.md`
- outbox dispatch handoff contract: `planningops/contracts/local-outbox-dispatch-handoff-contract.md`
- monday dispatch packet exporter: `monday/scripts/export_local_outbox_dispatch_packet.py`
- monday dispatch acknowledgement writer: `monday/scripts/ack_local_outbox_dispatch.py`
- monday execution packet exporter: `monday/scripts/export_local_dispatch_execution_packet.py`
- monday local dispatch runner: `monday/scripts/run_local_dispatch_cycle.py`

## Source Artifact Scope
The local dispatch cycle begins only after monday has:
- one dispatch packet with `dispatch_verdict = ready_for_dispatch`
- no blocking acknowledgement checkpoint for the same `delivery_idempotency_key`

The local dispatch cycle applies to:
- `status_update`
- `decision_request`
- `blocked_report`
- `goal_completed`

The local dispatch cycle does not apply to:
- real Slack API calls
- SMTP or third-party mail provider calls
- planningops-owned dispatch workers
- long-running background daemons outside monday

## Execution Packet Artifact
Every monday local dispatch execution packet emitted from a dispatch packet must include:
- `execution_packet_version`
- `generated_at_utc`
- `source_dispatch_packet_ref`
- `source_outbox_message_ref`
- `goal_key`
- `message_class`
- `channel_kind`
- `delivery_target`
- `delivery_idempotency_key`
- `payload_body`
- `thread_ref`
- `transport_kind`
- `bridge_adapter_kind`
- `execution_verdict`

Execution packet rules:
- `execution_verdict` must be one of `ready_for_local_bridge`, `already_dispatched`, or `blocked`
- `bridge_adapter_kind` must stay transport-neutral and must describe the monday-owned bridge surface, not a vendor SDK
- `payload_body` must be derived from monday-owned outbox payload content, not from planningops recomputation
- `source_dispatch_packet_ref` and `source_outbox_message_ref` must point to monday-owned runtime artifacts

## Local Dispatch Receipt Artifact
Every monday local dispatch cycle receipt emitted after one execution packet was processed must include:
- `dispatch_receipt_version`
- `generated_at_utc`
- `source_execution_packet_ref`
- `dispatch_packet_ref`
- `ack_checkpoint_ref`
- `goal_key`
- `delivery_idempotency_key`
- `channel_kind`
- `receipt_status`
- `receipt_reason`
- `receipt_checkpoint_ref`

Receipt rules:
- `receipt_status` must be one of `recorded`, `already_recorded`, or `blocked`
- `receipt_reason` must remain transport-neutral and must not include concrete Slack channel identifiers or email recipients
- `ack_checkpoint_ref` must point to the monday-owned acknowledgement checkpoint written for the consumed packet
- repeated dispatch-cycle attempts for the same `delivery_idempotency_key` must converge on one deterministic receipt checkpoint apart from timestamps

## Deterministic Cycle Rules
- monday must derive the execution packet only from the dispatch packet, the referenced outbox artifact, and monday-owned repo config
- planningops must not mutate dispatch packets, execution packets, acknowledgement checkpoints, or receipt checkpoints
- monday must emit exactly one execution packet per ready dispatch packet unless a receipt already exists, in which case it must return the existing state deterministically
- monday must fail closed if the dispatch packet is not `ready_for_dispatch`
- monday must fail closed if the execution packet or receipt path escapes the monday repo runtime-artifacts boundary

## Storage Boundary
- dispatch packets must remain under the monday repo `runtime-artifacts/` boundary
- execution packets must remain under the monday repo `runtime-artifacts/` boundary
- acknowledgement checkpoints must remain under the monday repo `runtime-artifacts/` boundary
- local dispatch receipts must remain under the monday repo `runtime-artifacts/` boundary
- planningops may reference monday artifact paths as evidence but must not become the storage owner

## Ownership Boundary
### PlanningOps owns
- contract expectations for dispatch execution and receipt evidence
- orchestration that invokes monday-owned dispatch-cycle entrypoints
- review artifacts that verify monday remains the runtime owner

### Monday owns
- dispatch packet selection
- execution packet emission
- local dispatch receipt checkpoints
- acknowledgement checkpoints for consumed packets
- future Slack skill or terminal notifier bridge execution

### PlanningOps must not own
- dispatch packet mutation
- execution packet mutation
- receipt checkpoint mutation
- transport credentials or concrete recipients

## Failure Rules
- monday must fail if the dispatch packet omits `source_outbox_message_ref`
- monday must fail if the execution packet would be emitted for an unsupported `transport_kind`
- monday must fail if a local dispatch receipt is requested for a missing execution packet
- planningops must fail review if monday local dispatch cycle logic requires planningops-owned runtime state

## Validation
- `planningops/scripts/test_local_dispatch_cycle_handoff_contract.sh`
- `planningops/contracts/local-outbox-dispatch-handoff-contract.md`
- `monday/scripts/export_local_outbox_dispatch_packet.py`
- `monday/scripts/ack_local_outbox_dispatch.py`
- `monday/scripts/export_local_dispatch_execution_packet.py`
- `monday/scripts/run_local_dispatch_cycle.py`
