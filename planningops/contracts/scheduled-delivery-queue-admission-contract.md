# Scheduled Delivery Queue Admission Contract

## Purpose
Define the deterministic control-plane boundary where `planningops` hands recurring operator and goal-completion delivery into monday-owned scheduled queue admission instead of calling monday delivery-cycle entrypoints directly.

This contract exists so:
- `planningops` can remain policy, review, and evidence control plane only
- `monday` stays the only owner of queue insertion, dequeue, lease, retry, dead-letter, delivery execution, acknowledgement, and receipt mutation
- recurring delivery can converge on one scheduler-owned runtime path before real Slack or email transports are introduced

## Canonical Boundary
- planningops reflection delivery runner: `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- planningops autonomous supervisor: `planningops/scripts/autonomous_supervisor_loop.py`
- monday scheduled delivery queue admission entrypoint: `monday/scripts/enqueue_scheduled_delivery_work_item.py`
- monday scheduler work-item mapper: `monday/scripts/scheduler_delivery_cycle_work_items.py`
- monday scheduled queue runtime: `monday/scripts/run_scheduled_queue_cycle.py`
- monday operator delivery cycle entrypoint: `monday/scripts/run_operator_message_delivery_cycle.py`
- monday goal completion delivery cycle entrypoint: `monday/scripts/run_goal_completion_delivery_cycle.py`
- planningops operator channel adapter contract: `planningops/contracts/operator-channel-adapter-contract.md`
- planningops goal completion contract: `planningops/contracts/goal-completion-contract.md`
- planningops scheduled delivery cycle handoff contract: `planningops/contracts/scheduled-delivery-cycle-handoff-contract.md`

## Primary Recurring Path
The primary recurring local autonomy path becomes:
- `planningops reflection action -> monday/scripts/enqueue_scheduled_delivery_work_item.py -> monday/scripts/run_scheduled_queue_cycle.py -> monday local delivery-cycle entrypoint -> monday runtime artifacts`
- `planningops goal completion decision -> monday/scripts/enqueue_scheduled_delivery_work_item.py -> monday/scripts/run_scheduled_queue_cycle.py -> monday local delivery-cycle entrypoint -> monday runtime artifacts`

`planningops` must not invoke:
- `monday/scripts/run_operator_message_delivery_cycle.py`
- `monday/scripts/run_goal_completion_delivery_cycle.py`

directly on the primary recurring path once scheduled queue admission is in scope.

## Required Inputs
Queue admission must accept one of these high-level handoff sources:
- a reflection action artifact governed by `planningops/contracts/reflection-action-handoff-contract.md`
- a supervisor goal-completion handoff governed by `planningops/contracts/supervisor-operator-handoff-contract.md`

Admission input rules:
- monday must derive one scheduled delivery work item from the supplied handoff
- monday must derive one queue item reference or queue item record for that work item
- monday may accept optional `dry-run` or profile hints
- `planningops` must not provide monday-owned queue mutation fields such as lease timestamps, retry counters, or completion mutation records

## Required Admission Outputs
Every successful queue-admission report must include:
- `delivery_work_item_kind`
- `selected_delivery_entrypoint`
- `scheduled_delivery_work_item_ref`
- `scheduled_queue_item_ref`
- `queue_item_id`
- `delivery_idempotency_key`
- `goal_key`
- `verdict`

Output rules:
- `selected_delivery_entrypoint` must be one of the two monday local delivery-cycle entrypoints
- `scheduled_delivery_work_item_ref` must point at a monday-owned runtime artifact
- `scheduled_queue_item_ref` must point at a monday-owned runtime artifact or monday-owned queue store record descriptor
- queue admission may summarize planningops source artifacts, but monday runtime-owned refs remain the source of truth for recurring delivery execution

## Deterministic Rules
- identical `dry-run` inputs must preserve the same `delivery_work_item_kind`, `selected_delivery_entrypoint`, and queue-item identity shape apart from timestamps
- a reflection action requiring operator delivery must materialize an `operator_message_delivery` work item
- a goal-completion handoff must materialize a `goal_completion_delivery` work item
- monday queue admission must not bypass scheduled queue execution by directly invoking delivery-cycle entrypoints
- planningops review must fail if recurring delivery evidence still shows direct planningops invocation of monday delivery-cycle entrypoints instead of monday queue admission

## Ownership Boundary
### PlanningOps owns
- high-level delivery intent and policy
- control-plane review evidence
- completion policy and operator-channel policy

### Monday owns
- queue admission translation
- scheduled delivery work-item creation
- queue-item insertion or queue store mutation
- recurring dequeue, retry, dead-letter, acknowledgement, and receipt mutation
- delivery-cycle execution and runtime evidence

### PlanningOps must not own
- monday queue insertion mutation
- monday work-item persistence
- monday retry or dead-letter mutation
- concrete Slack or email transport execution
- recreation of monday runtime delivery evidence from control-plane-only state

## Failure Rules
- monday must fail if queue admission cannot resolve exactly one valid `delivery_work_item_kind`
- monday must fail if queue admission cannot resolve exactly one valid local delivery-cycle entrypoint
- monday must fail if queue admission writes refs outside the monday repo `runtime-artifacts/` boundary for runtime-owned evidence
- planningops must fail review if recurring delivery still depends on direct delivery-cycle invocation rather than monday queue admission

## Validation
- `planningops/scripts/test_scheduled_delivery_queue_admission_contract.sh`
- `planningops/contracts/scheduled-delivery-cycle-handoff-contract.md`
- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/goal-completion-contract.md`
- `monday/scripts/enqueue_scheduled_delivery_work_item.py`
- `monday/scripts/scheduler_delivery_cycle_work_items.py`
- `monday/scripts/run_scheduled_queue_cycle.py`
