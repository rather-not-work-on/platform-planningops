# Local Delivery Cycle Orchestration Contract

## Purpose
Define the deterministic control-plane boundary where `planningops` delegates operator and goal-completion delivery through monday-owned local delivery-cycle entrypoints instead of stitching lower-level delivery and dispatch steps itself.

This contract exists so:
- `planningops` can stay transport-agnostic while still orchestrating delivery outcomes
- `monday` remains the only runtime owner of local delivery, dispatch export, acknowledgement, and receipt mutation
- future Slack skill and terminal notifier adapters can evolve behind monday entrypoints without changing planningops control-plane flow

## Canonical Boundary
- reflection delivery runner: `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- supervisor loop: `planningops/scripts/autonomous_supervisor_loop.py`
- monday operator delivery cycle entrypoint: `monday/scripts/run_operator_message_delivery_cycle.py`
- monday goal completion delivery cycle entrypoint: `monday/scripts/run_goal_completion_delivery_cycle.py`
- monday entrypoint contract: `planningops/contracts/local-delivery-cycle-entrypoint-contract.md`
- operator channel adapter contract: `planningops/contracts/operator-channel-adapter-contract.md`
- goal completion contract: `planningops/contracts/goal-completion-contract.md`

## Primary Local Path
The primary local autonomous path is:
- `planningops reflection action -> monday run_operator_message_delivery_cycle.py -> monday runtime artifacts -> planningops aggregate evidence`
- `planningops goal completion decision -> monday run_goal_completion_delivery_cycle.py -> monday runtime artifacts -> planningops aggregate evidence`

`planningops` must invoke only monday-owned local delivery-cycle entrypoints on the primary local path.

`planningops` must not invoke these lower-level monday scripts directly on the primary local path:
- `monday/scripts/send_operator_message.py`
- `monday/scripts/send_goal_completion_notification.py`
- `monday/scripts/export_local_outbox_dispatch_packet.py`
- `monday/scripts/run_local_dispatch_cycle.py`

## Ownership Boundary
### PlanningOps owns
- orchestration of the delivery-cycle stage
- aggregate control-plane evidence that links to monday runtime artifacts
- validation that the correct monday entrypoint was invoked for the correct action kind

### Monday owns
- payload translation
- local target resolution
- outbox write behavior
- dispatch packet export
- execution packet emission
- acknowledgement checkpoint mutation
- dispatch receipt mutation

### PlanningOps must not own
- concrete Slack or email delivery execution
- monday runtime-artifact mutation
- construction of monday dispatch packets or dispatch receipts
- fallback recreation of lower-level delivery-plus-dispatch logic

## Required Inputs
Reflection-delivery orchestration must accept:
- a reflection action artifact governed by `planningops/contracts/reflection-action-handoff-contract.md`
- optional local profile hints or mode flags

Supervisor goal-completion orchestration must accept:
- a supervisor/operator report path
- a summary path or completion evidence path
- optional local profile hints or mode flags

Input rules:
- `planningops` may forward monday profile/config hints for deterministic local execution
- `planningops` must not resolve concrete Slack channels or email recipients itself
- `planningops` must not require caller-supplied dispatch packet or receipt paths on the primary local path

## Required Outputs
Every planningops orchestration report for this stage must include:
- `monday_delivery_entrypoint`
- `monday_delivery_report_ref`
- `delivery_verdict`
- `delivery_target_resolution_mode`
- `delivery_target_profile_ref`
- `delivery_transport_kind`
- `delivery_outbox_message_ref`

Output rules:
- `monday_delivery_entrypoint` must be one of the two monday local delivery-cycle entrypoints
- `monday_delivery_report_ref` must point at a monday-owned runtime artifact
- planningops may summarize monday delivery evidence, but must not copy concrete recipient data into control-plane-owned fields

## Deterministic Rules
- reflection actions requiring operator delivery must flow through `monday/scripts/run_operator_message_delivery_cycle.py`
- goal completion delivery must flow through `monday/scripts/run_goal_completion_delivery_cycle.py`
- identical dry-run inputs must preserve the same selected monday entrypoint and the same verdict shape apart from timestamps
- planningops must fail closed if monday entrypoint evidence is missing or references lower-level direct delivery instead of the canonical entrypoint

## Failure Rules
- planningops must fail if reflection delivery or goal completion delivery calls a lower-level monday delivery CLI directly on the primary local path
- planningops must fail if monday delivery-cycle evidence points outside the monday repo `runtime-artifacts/` boundary
- planningops must fail if a goal-completion path emits an operator-message entrypoint or vice versa

## Validation
- `planningops/scripts/test_local_delivery_cycle_orchestration_contract.sh`
- `planningops/contracts/local-delivery-cycle-entrypoint-contract.md`
- `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- `planningops/scripts/autonomous_supervisor_loop.py`
- `monday/scripts/run_operator_message_delivery_cycle.py`
- `monday/scripts/run_goal_completion_delivery_cycle.py`
