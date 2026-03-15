# Scheduled Delivery Cycle Handoff Contract

## Purpose
Define the deterministic queue-native boundary where monday scheduled queue execution hands one delivery work item to the correct monday local delivery-cycle entrypoint.

This contract exists so:
- `planningops` can review and reason about recurring delivery execution without owning monday queue mutation
- `monday` remains the only owner of queue dequeue, delivery-cycle execution, acknowledgement mutation, and receipt mutation
- future Slack skill and terminal notifier adapters can stay behind monday-owned delivery-cycle entrypoints even when recurring execution becomes queue-native

## Canonical Boundary
- monday scheduled queue runtime: `monday/scripts/run_scheduled_queue_cycle.py`
- monday scheduler delivery work-item mapper: `monday/scripts/scheduler_delivery_cycle_work_items.py`
- monday operator delivery cycle entrypoint: `monday/scripts/run_operator_message_delivery_cycle.py`
- monday goal completion delivery cycle entrypoint: `monday/scripts/run_goal_completion_delivery_cycle.py`
- planningops local delivery-cycle orchestration contract: `planningops/contracts/local-delivery-cycle-orchestration-contract.md`
- planningops local delivery-cycle entrypoint contract: `planningops/contracts/local-delivery-cycle-entrypoint-contract.md`
- planningops goal completion contract: `planningops/contracts/goal-completion-contract.md`
- planningops operator channel adapter contract: `planningops/contracts/operator-channel-adapter-contract.md`

## Primary Recurring Path
The primary recurring local autonomy path for delivery is:
- `monday scheduled queue item -> monday/scripts/run_scheduled_queue_cycle.py -> monday local delivery-cycle entrypoint -> monday runtime artifacts`

Queue-native delivery must select exactly one monday entrypoint per work item:
- operator-message delivery work items must flow through `monday/scripts/run_operator_message_delivery_cycle.py`
- goal-completion delivery work items must flow through `monday/scripts/run_goal_completion_delivery_cycle.py`

`planningops` must not invoke monday one-shot delivery-cycle entrypoints directly for the recurring scheduler-owned path once scheduled delivery work items are in scope.

## Delivery Work Item Shape
Each monday scheduled delivery work item must carry enough information to select one local delivery-cycle entrypoint deterministically.

Required fields:
- `queue_item_id`
- `goal_key`
- `delivery_work_item_kind`
- `message_class`
- `source_artifact_ref`
- `delivery_idempotency_key`

Optional fields:
- `delivery_target`
- `channel_kind`
- `thread_ref`
- `goal_transition_report_ref`

Field rules:
- `delivery_work_item_kind` must be one of `operator_message_delivery` or `goal_completion_delivery`
- `message_class` must align with the chosen work-item kind
- `source_artifact_ref` must point at a monday-owned runtime artifact or a planningops-owned control-plane artifact explicitly allowed by the referenced monday entrypoint contract
- `goal_transition_report_ref` is allowed only for goal-completion delivery work items

## Required Outputs
Every successful queue-native delivery execution must emit evidence that includes:
- `queue_item_id`
- `delivery_work_item_kind`
- `selected_delivery_entrypoint`
- `delivery_cycle_report_ref`
- `delivery_cycle_verdict`

Output rules:
- `selected_delivery_entrypoint` must be one of the two monday local delivery-cycle entrypoints
- `delivery_cycle_report_ref` must point at a monday-owned runtime artifact
- monday queue execution may summarize delivery results, but planningops must treat monday runtime artifacts as the source of truth for delivery mutation

## Deterministic Rules
- identical `dry-run` inputs must preserve the same `selected_delivery_entrypoint` and the same verdict shape apart from timestamps
- `operator_message_delivery` items must not invoke `monday/scripts/run_goal_completion_delivery_cycle.py`
- `goal_completion_delivery` items must not invoke `monday/scripts/run_operator_message_delivery_cycle.py`
- monday scheduled queue execution must not bypass local delivery-cycle entrypoints by calling lower-level delivery or dispatch scripts directly for queue-native delivery work
- planningops review must fail if recurring delivery evidence shows direct one-shot invocation from planningops instead of monday scheduled queue ownership

## Ownership Boundary
### PlanningOps owns
- contract expectations for queue-native delivery handoff
- review evidence that confirms monday owns recurring delivery execution
- goal completion policy and operator-channel policy

### Monday owns
- queue-item construction and persistence
- queue dequeue, lease, retry, and dead-letter mutation
- local delivery-cycle entrypoint selection
- delivery execution and runtime artifact mutation

### PlanningOps must not own
- monday delivery work-item mutation
- monday queue-item dequeue or completion mutation
- concrete Slack or email transport execution
- reconstruction of monday delivery-cycle evidence from control-plane-only state

## Failure Rules
- monday must fail if a delivery work item cannot resolve one valid local delivery-cycle entrypoint
- monday must fail if a goal-completion delivery work item omits goal-completion evidence required by the monday goal completion entrypoint
- monday must fail if queue-native delivery execution points outside the monday repo `runtime-artifacts/` boundary
- planningops must fail review if recurring delivery paths still depend on direct one-shot invocation from `planningops`

## Validation
- `planningops/scripts/test_scheduled_delivery_cycle_handoff_contract.sh`
- `planningops/contracts/local-delivery-cycle-orchestration-contract.md`
- `planningops/contracts/local-delivery-cycle-entrypoint-contract.md`
- `monday/scripts/run_scheduled_queue_cycle.py`
- `monday/scripts/scheduler_delivery_cycle_work_items.py`
- `monday/scripts/run_operator_message_delivery_cycle.py`
- `monday/scripts/run_goal_completion_delivery_cycle.py`
