# Worker Outcome Reflection Contract

## Purpose
Define the deterministic handoff between monday-owned queue worker outcomes and planningops-owned reflection decisions.

This contract exists so:
- `monday` can export reflection-ready evidence without leaking queue table internals into planningops
- `planningops` can evaluate runtime outcomes into control-plane decisions without mutating the runtime queue
- both repos share one fixed packet and decision vocabulary for wave7 and later scheduler work

## Canonical Boundary
- runtime source schema: `platform-contracts/schemas/runtime-queue-worker-outcome.schema.json`
- runtime exporter target: `monday/scripts/export_worker_outcome_reflection_packet.py`
- control-plane evaluator target: `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py`

## Reflection Packet Envelope
Every reflection packet exported by `monday` must include:
- `packet_version`
- `exported_at_utc`
- `source_repo`
- `source_contract_ref`
- `source_outcome_ref`
- `worker_outcome`
- `reflection_hints`

### Required Source Outcome Fields
`worker_outcome` must preserve the canonical runtime fields:
- `transition_id`
- `queue_item_id`
- `goal_key`
- `schedule_key`
- `lease_owner`
- `worker_run_id`
- `state_from`
- `state_to`
- `transition_reason`
- `occurred_at_utc`
- `attempt_count`
- `retry_budget_remaining`

Optional outcome fields may pass through when present:
- `completion_evidence_ref`
- `retry_after_utc`
- `dead_letter_reason`

### Required Reflection Hints
`reflection_hints` must be derived deterministically from the runtime outcome and include:
- `outcome_class`
- `completion_candidate`
- `retry_exhausted`
- `dead_letter`
- `operator_attention_recommended`
- `allowed_decisions`

### Outcome Class Vocabulary
The packet-level `outcome_class` vocabulary is:
- `completion`
- `retry_wait`
- `dead_letter`

## Decision Vocabulary
PlanningOps may emit only these reflection decisions:
- `continue`
- `replan_required`
- `goal_achieved`
- `operator_notify`

Every evaluator result must include:
- `goal_key`
- `queue_item_id`
- `worker_run_id`
- `source_packet_ref`
- `reflection_decision`
- `decision_reason`
- `decision_timestamp_utc`
- `control_plane_action`
- `verdict`

## Deterministic Mapping Rules
- `state_to = completed` maps to `outcome_class = completion`
- `state_to = retry_wait` maps to `outcome_class = retry_wait`
- `state_to = dead_letter` maps to `outcome_class = dead_letter`
- `outcome_class = completion` may allow only `continue` or `goal_achieved`
- `outcome_class = retry_wait` must allow only `continue`
- `outcome_class = dead_letter` may allow only `replan_required` or `operator_notify`
- `retry_budget_remaining = 0` or a populated `dead_letter_reason` must set `operator_attention_recommended = true`
- the evaluator must fail closed if the packet proposes a decision outside `allowed_decisions`

## Ownership Boundary
### Monday owns
- queue runtime mutation
- runtime outcome production
- reflection packet export
- repo-local runtime evidence paths

### PlanningOps owns
- reflection decision policy
- goal promotion and replanning policy
- operator escalation intent
- completion policy references

### PlanningOps must not own
- queue lease updates
- dequeue/retry/dead-letter mutation
- monday queue persistence internals

## Failure Rules
- missing or malformed runtime source fields must fail packet export
- malformed `reflection_hints` must fail evaluation
- evaluators must return deterministic failure evidence instead of silently defaulting to `continue`
- control-plane evaluation must not mutate monday queue state directly

## Validation
- `planningops/scripts/test_worker_outcome_reflection_contract.sh`
- `platform-contracts/schemas/runtime-queue-worker-outcome.schema.json`
- `monday/scripts/export_worker_outcome_reflection_packet.py`
- `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py`
