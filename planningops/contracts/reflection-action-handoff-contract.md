# Reflection Action Handoff Contract

## Purpose
Define the deterministic boundary between planningops-owned reflection evaluation outputs and the next action artifacts consumed by supervisor policy and monday-owned operator delivery entrypoints.

This contract exists so:
- `planningops` can turn reflection decisions into explicit control-plane action intent without mutating monday queue state
- `monday` can consume one stable action artifact instead of re-deriving delivery intent from raw reflection packets
- goal completion, replanning, and operator escalation stay policy-driven and auditable

## Canonical Boundary
- reflection evaluator: `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py`
- action applier: `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- monday operator delivery entrypoint: `monday/scripts/run_operator_message_delivery_cycle.py`
- operator channel policy: `planningops/contracts/operator-channel-adapter-contract.md`
- goal completion policy: `planningops/contracts/goal-completion-contract.md`

## Action Artifact
Every reflection action artifact emitted by `planningops` must include:
- `action_version`
- `generated_at_utc`
- `active_goal_key`
- `packet_goal_key`
- `queue_item_id`
- `worker_run_id`
- `source_packet_ref`
- `reflection_evaluation_ref`
- `reflection_decision`
- `decision_reason`
- `control_plane_action`
- `action_kind`
- `delivery_required`
- `message_class_hint`
- `operator_channel_role`
- `operator_channel_kind`
- `operator_channel_execution_repo`
- `operator_channel_adapter_contract_ref`
- `goal_transition_required`
- `requested_goal_status`
- `goal_transition_report_path`
- `handoff_summary`
- `handoff_contract_ref`
- `verdict`

## Action Kind Vocabulary
PlanningOps may emit only these `action_kind` values:
- `record_continue`
- `trigger_replan_review`
- `prepare_goal_completion`
- `escalate_operator_attention`

## Operator Channel Role Vocabulary
PlanningOps may emit only these `operator_channel_role` values:
- `none`
- `primary_operator_channel`
- `terminal_notification_channel`

## Deterministic Mapping Rules
- `reflection_decision = continue` must map to:
  - `action_kind = record_continue`
  - `delivery_required = false`
  - `message_class_hint = status_update`
  - `operator_channel_role = none`
  - `operator_channel_kind = -`
  - `operator_channel_execution_repo = -`
  - `operator_channel_adapter_contract_ref = -`
  - `goal_transition_required = false`
  - `requested_goal_status = -`
  - `goal_transition_report_path = -`
- `reflection_decision = replan_required` must map to:
  - `action_kind = trigger_replan_review`
  - `delivery_required = true`
  - `message_class_hint = decision_request`
  - `operator_channel_role = primary_operator_channel`
  - `goal_transition_required = false`
  - `requested_goal_status = -`
  - `goal_transition_report_path = -`
- `reflection_decision = goal_achieved` must map to:
  - `action_kind = prepare_goal_completion`
  - `delivery_required = true`
  - `message_class_hint = goal_completed`
  - `operator_channel_role = terminal_notification_channel`
  - `goal_transition_required = true`
  - `requested_goal_status = achieved`
- `reflection_decision = operator_notify` must map to:
  - `action_kind = escalate_operator_attention`
  - `delivery_required = true`
  - `message_class_hint = blocked_report`
  - `operator_channel_role = primary_operator_channel`
  - `goal_transition_required = false`
  - `requested_goal_status = -`
  - `goal_transition_report_path = -`

## Channel Policy Projection Rules
- when `operator_channel_role = primary_operator_channel`, the artifact must copy:
  - `operator_channel_kind`
  - `operator_channel_execution_repo`
  - `operator_channel_adapter_contract_ref`
  from the active goal registry `primary_operator_channel`
- when `operator_channel_role = terminal_notification_channel`, the artifact must copy the same three fields from the active goal registry `terminal_notification_channel`
- when `operator_channel_role = none`, all three channel policy fields must be `-`

## Goal Transition Rules
- `goal_transition_required = true` is allowed only for `reflection_decision = goal_achieved`
- `goal_transition_required = true` requires `requested_goal_status = achieved`
- if the applier executes a goal transition in `apply` mode, `goal_transition_report_path` must point to the emitted transition report
- if the applier runs in `dry-run` mode, `goal_transition_report_path` may remain `-` while the transition intent is still recorded

## Handoff Summary Rules
- `handoff_summary` must be human-readable and queue-aware.
- `handoff_summary` must mention the reflection decision and the queue item identifier.
- `handoff_summary` must not contain transport-specific targets such as Slack channel IDs or email addresses.

## Ownership Boundary
### PlanningOps owns
- mapping reflection decisions into action intent
- goal transition intent and requested target status
- operator channel role selection
- control-plane evidence and handoff summaries

### Monday owns
- translating action artifacts into concrete operator delivery payloads
- local delivery-cycle execution for operator-message classes
- resolving concrete delivery targets from local config or skill context
- invoking Slack/email transport through CLI or MCP adapters
- returning delivery evidence

### PlanningOps must not own
- queue lease mutation
- queue retry/dead-letter mutation
- concrete Slack channel IDs
- concrete email recipients
- transport credentials

## Failure Rules
- the applier must fail closed if `reflection_decision` is outside the allowed vocabulary
- the applier must fail if the action artifact would violate the deterministic mapping rules above
- `delivery_required = true` must never pair with `operator_channel_role = none`
- `goal_transition_required = true` must only pair with `requested_goal_status = achieved`
- `operator_channel_role != none` must never pair with `operator_channel_kind = -`
- action artifacts must remain deterministic for the same reflection evaluation input and active-goal context

## Validation
- `planningops/scripts/test_reflection_action_handoff_contract.sh`
- `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py`
- `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- `monday/scripts/run_operator_message_delivery_cycle.py`
