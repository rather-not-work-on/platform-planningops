# Local Delivery Cycle Entrypoint Contract

## Purpose
Define the deterministic monday-owned entrypoints that collapse local outbox delivery, dispatch packet export, execution packet export, acknowledgement, and receipt creation behind one runtime command surface.

This contract exists so:
- `planningops` can orchestrate one-shot local delivery cycles without owning transport-facing runtime mutation
- `monday` can expose one entrypoint for operator updates and one entrypoint for goal completion delivery
- future Slack skill or terminal notifier adapters can attach behind monday entrypoints without changing planningops orchestration contracts

## Canonical Boundary
- operator policy contract: `planningops/contracts/operator-channel-adapter-contract.md`
- goal completion contract: `planningops/contracts/goal-completion-contract.md`
- outbox dispatch handoff contract: `planningops/contracts/local-outbox-dispatch-handoff-contract.md`
- dispatch cycle handoff contract: `planningops/contracts/local-dispatch-cycle-handoff-contract.md`
- monday operator delivery CLI: `monday/scripts/send_operator_message.py`
- monday goal completion CLI: `monday/scripts/send_goal_completion_notification.py`
- monday dispatch packet exporter: `monday/scripts/export_local_outbox_dispatch_packet.py`
- monday dispatch cycle runner: `monday/scripts/run_local_dispatch_cycle.py`
- monday operator delivery cycle entrypoint: `monday/scripts/run_operator_message_delivery_cycle.py`
- monday goal completion delivery cycle entrypoint: `monday/scripts/run_goal_completion_delivery_cycle.py`

## Source Artifact Scope
The local delivery cycle entrypoint begins only after monday receives:
- one operator payload for `status_update`, `decision_request`, or `blocked_report`
- or one goal completion payload for `goal_completed`

The entrypoint applies only to local-profile autonomous delivery where:
- `target_resolution_mode = local_profile`
- `transport_kind = local_outbox`

The entrypoint does not apply to:
- real Slack API calls
- SMTP or third-party mail provider calls
- planningops-owned delivery daemons
- long-running workers outside monday

## Aggregate Delivery Cycle Report
Every monday local delivery cycle entrypoint report must include:
- `delivery_cycle_report_version`
- `generated_at_utc`
- `entrypoint_script`
- `source_payload_ref`
- `delivery_report_ref`
- `dispatch_packet_ref`
- `execution_packet_ref`
- `ack_checkpoint_ref`
- `dispatch_receipt_ref`
- `goal_key`
- `message_class`
- `channel_kind`
- `delivery_idempotency_key`
- `cycle_status`
- `verdict`

Aggregate report rules:
- `cycle_status` must be one of `recorded`, `already_recorded`, `dry_run`, `blocked`, or `no_ready_dispatch_packet`
- `verdict` must be `pass` or `fail`
- `source_payload_ref` may point outside `runtime-artifacts/` only when the caller supplied an explicit payload file
- every other `*_ref` field must point to monday-owned runtime artifacts
- one report must correspond to one payload and one delivery idempotency key

## Deterministic Entrypoint Rules
- monday must derive the aggregate report only from the payload, monday-owned config, and monday-owned runtime artifacts
- monday may accept high-level reflection-action or supervisor-handoff inputs and translate them into canonical payloads before the delivery CLI stage
- monday must run delivery CLI -> dispatch packet export -> dispatch cycle in-order for apply-mode local delivery
- monday must stop after delivery evidence and emit `cycle_status = dry_run` when dry-run mode is requested
- monday must not require `planningops` to provide explicit dispatch packet paths on the primary local autonomous path
- monday must return the already-recorded state deterministically when receipt or acknowledgement checkpoints already exist
- monday must fail closed if local delivery did not produce `delivered_local_outbox`
- monday must fail closed if any execution packet, acknowledgement checkpoint, or receipt path escapes the monday repo `runtime-artifacts/` boundary

## Storage Boundary
- aggregate delivery cycle reports must remain under the monday repo `runtime-artifacts/` boundary
- delivery reports must remain under the monday repo `runtime-artifacts/` boundary
- dispatch packets must remain under the monday repo `runtime-artifacts/` boundary
- execution packets must remain under the monday repo `runtime-artifacts/` boundary
- acknowledgement checkpoints must remain under the monday repo `runtime-artifacts/` boundary
- dispatch receipts must remain under the monday repo `runtime-artifacts/` boundary
- planningops may reference monday artifact paths as evidence but must not become the storage owner

## Ownership Boundary
### PlanningOps owns
- contract expectations for monday entrypoint reports
- orchestration that invokes monday-owned entrypoints
- review artifacts that verify monday remains the runtime owner

### Monday owns
- payload delivery through local profile resolution
- local outbox persistence
- dispatch packet emission
- execution packet emission
- acknowledgement checkpoint mutation
- dispatch receipt mutation
- aggregate delivery cycle report emission

### PlanningOps must not own
- payload mutation
- local outbox mutation
- dispatch packet mutation
- execution packet mutation
- acknowledgement or receipt mutation
- transport credentials or concrete recipients

## Failure Rules
- monday must fail if an operator entrypoint receives `goal_completed`
- monday must fail if a goal completion entrypoint receives a non-`goal_completed` message
- monday must fail if local delivery remains blocked or dry-run when apply-mode entrypoints are requested
- monday must fail if aggregate report evidence points to non-monday runtime artifact ownership
- planningops must fail review if monday entrypoints require planningops-owned runtime state

## Validation
- `planningops/scripts/test_local_delivery_cycle_entrypoint_contract.sh`
- `planningops/contracts/local-outbox-dispatch-handoff-contract.md`
- `planningops/contracts/local-dispatch-cycle-handoff-contract.md`
- `monday/scripts/send_operator_message.py`
- `monday/scripts/send_goal_completion_notification.py`
- `monday/scripts/export_local_outbox_dispatch_packet.py`
- `monday/scripts/run_local_dispatch_cycle.py`
- `monday/scripts/run_operator_message_delivery_cycle.py`
- `monday/scripts/run_goal_completion_delivery_cycle.py`
