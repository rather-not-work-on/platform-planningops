# Local Outbox Dispatch Handoff Contract

## Purpose
Define the deterministic handoff between monday-owned local outbox delivery artifacts and the next monday-owned dispatch and acknowledgement artifacts that future Slack skill or terminal notifier adapters can consume.

This contract exists so:
- `planningops` can rely on stable monday handoff evidence without owning transport runtime state
- `monday` can turn one local outbox message into one dispatch packet and one acknowledgement checkpoint
- future Slack skill or email notifier adapters can consume monday-owned dispatch artifacts instead of polling raw outbox folders or control-plane reports

## Canonical Boundary
- operator policy contract: `planningops/contracts/operator-channel-adapter-contract.md`
- local target resolution contract: `planningops/contracts/local-operator-target-resolution-contract.md`
- reflection delivery cycle orchestration: `planningops/contracts/reflection-delivery-cycle-contract.md`
- supervisor goal completion orchestration: `planningops/contracts/autonomous-supervisor-loop-contract.md`
- monday local outbox writer: `monday/scripts/operator_channel_local_outbox.py`
- monday status delivery CLI: `monday/scripts/send_operator_message.py`
- monday goal-completion CLI: `monday/scripts/send_goal_completion_notification.py`
- monday reflection delivery CLI: `monday/scripts/send_reflection_decision_update.py`
- monday supervisor completion CLI: `monday/scripts/send_supervisor_goal_completion.py`
- monday dispatch packet exporter: `monday/scripts/export_local_outbox_dispatch_packet.py`
- monday dispatch acknowledgement writer: `monday/scripts/ack_local_outbox_dispatch.py`

## Source Artifact Scope
The handoff begins only after a monday delivery CLI successfully wrote:
- one delivery report with `deliveryVerdict = delivered_local_outbox`
- one deterministic local outbox artifact referenced by `outboxMessageRef`

The handoff applies to:
- `status_update`
- `decision_request`
- `blocked_report`
- `goal_completed`

The handoff does not apply to:
- raw Slack API calls
- SMTP or third-party mail provider calls
- planningops-owned delivery queues
- transport execution receipts from external providers

## Dispatch Packet Artifact
Every monday dispatch packet emitted from a local outbox message must include:
- `dispatch_packet_version`
- `generated_at_utc`
- `source_delivery_report_ref`
- `source_outbox_message_ref`
- `goal_key`
- `message_class`
- `channel_kind`
- `delivery_target`
- `delivery_idempotency_key`
- `target_resolution_mode`
- `target_profile_ref`
- `transport_kind`
- `dispatch_verdict`

Dispatch packet rules:
- `dispatch_packet_version` must be an integer
- `dispatch_verdict` must be one of `ready_for_dispatch`, `already_acknowledged`, or `blocked`
- `source_delivery_report_ref` must point to a monday-owned report emitted by a delivery CLI named in the canonical boundary
- `source_outbox_message_ref` must point to a monday-owned local outbox artifact
- `target_resolution_mode` must remain `local_profile` for the primary autonomous path
- `transport_kind` must remain `local_outbox` in this wave

## Acknowledgement Artifact
Every monday dispatch acknowledgement emitted after a packet was processed must include:
- `dispatch_ack_version`
- `generated_at_utc`
- `dispatch_packet_ref`
- `source_outbox_message_ref`
- `goal_key`
- `delivery_idempotency_key`
- `channel_kind`
- `ack_status`
- `ack_reason`
- `ack_checkpoint_ref`

Acknowledgement rules:
- `ack_status` must be one of `recorded`, `already_recorded`, or `blocked`
- `ack_reason` must remain transport-neutral and must not include concrete Slack channel identifiers or email recipients
- `ack_checkpoint_ref` must point to the monday-owned checkpoint artifact written for the acknowledgement event
- repeated acknowledgement attempts for the same `delivery_idempotency_key` must converge on one deterministic checkpoint apart from timestamps

## Deterministic Export Rules
- monday must derive the dispatch packet only from the delivery report, the referenced local outbox artifact, and monday-owned repo config
- planningops must not mutate local outbox files, dispatch packets, or acknowledgement checkpoints
- monday must export exactly one dispatch packet per `delivery_idempotency_key` unless the packet already exists, in which case it must return the existing packet deterministically
- monday must not require `planningops` to provide an explicit dispatch target for the primary local autonomous path
- monday must fail closed if the delivery report does not indicate `delivered_local_outbox`
- monday must fail closed if `source_outbox_message_ref` or `source_delivery_report_ref` escapes the monday repo runtime-artifacts boundary

## Storage Boundary
- local outbox artifacts must remain under the monday repo `runtime-artifacts/` boundary
- dispatch packets must remain under the monday repo `runtime-artifacts/` boundary
- acknowledgement checkpoints must remain under the monday repo `runtime-artifacts/` boundary
- planningops may reference monday artifact paths as evidence but must not become the storage owner

## Ownership Boundary
### PlanningOps owns
- contract expectations for handoff evidence
- orchestration that invokes monday-owned dispatch or acknowledgement entrypoints
- review artifacts that verify monday remains the runtime owner

### Monday owns
- local outbox persistence
- dispatch packet emission
- dispatch acknowledgement checkpoints
- future Slack skill or email notifier consumption of the dispatch packet

### PlanningOps must not own
- raw outbox payload mutation
- dispatch packet mutation
- acknowledgement checkpoint mutation
- transport credentials or concrete recipients

## Failure Rules
- monday must fail if the source delivery report omits `outboxMessageRef`
- monday must fail if `deliveryVerdict` is not `delivered_local_outbox`
- monday must fail if the dispatch packet would be emitted for an unsupported `transport_kind`
- monday must fail if an acknowledgement is requested for a missing dispatch packet
- planningops must fail review if monday dispatch or acknowledgement logic requires planningops-owned runtime state

## Validation
- `planningops/scripts/test_local_outbox_dispatch_handoff_contract.sh`
- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/local-operator-target-resolution-contract.md`
- `monday/scripts/operator_channel_local_outbox.py`
- `monday/scripts/send_operator_message.py`
- `monday/scripts/send_goal_completion_notification.py`
- `monday/scripts/send_reflection_decision_update.py`
- `monday/scripts/send_supervisor_goal_completion.py`
- `monday/scripts/export_local_outbox_dispatch_packet.py`
- `monday/scripts/ack_local_outbox_dispatch.py`
