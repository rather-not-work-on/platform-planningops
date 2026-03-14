# Reflection Cycle Orchestration Contract

## Purpose
Freeze the thin control-plane orchestration path that turns one monday worker outcome into one planningops reflection decision and one planningops action artifact.

This contract exists so:
- `planningops` can run the reflection chain end to end without prompt-local glue
- `monday` remains the owner of runtime outcome export and downstream operator delivery
- later scheduler and queue work can reuse one deterministic cycle runner instead of re-stitching the same steps in ad hoc scripts

## Canonical Boundary
- runtime exporter: `monday/scripts/export_worker_outcome_reflection_packet.py`
- control-plane evaluator: `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py`
- control-plane applier: `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- orchestration runner: `planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
- downstream monday consumer: `monday/scripts/send_reflection_decision_update.py`

## Cycle Scope
The reflection cycle covered by this contract is:
1. read one monday worker outcome artifact
2. export one reflection packet through the monday-owned exporter
3. evaluate the packet into one planningops reflection decision
4. apply the decision into one planningops action artifact
5. emit one planningops-owned cycle report

The cycle ends at the action artifact.

The cycle must not:
- mutate monday queue state directly
- invoke monday delivery transports directly
- derive new reflection vocabularies outside the existing contracts

## Required Inputs
The orchestration runner must accept enough input to resolve the full cycle deterministically:
- a worker outcome artifact path
- an active-goal registry path
- a goal key or a deterministic active-goal resolution path
- an execution mode: `dry-run` or `apply`
- explicit output paths or deterministic default output locations for:
  - the reflection packet
  - the reflection evaluation
  - the reflection action artifact
  - the cycle report

## Required Outputs
Every successful cycle must emit:
- one reflection packet artifact
- one reflection evaluation artifact
- one reflection action artifact
- one cycle report

## Cycle Report
Every cycle report must include:
- `generated_at_utc`
- `mode`
- `goal_key`
- `source_outcome_ref`
- `reflection_packet_ref`
- `reflection_evaluation_ref`
- `reflection_action_ref`
- `reflection_decision`
- `action_kind`
- `delivery_required`
- `goal_transition_required`
- `goal_transition_report_path`
- `runner_contract_ref`
- `verdict`

Optional cycle report fields may include:
- `queue_item_id`
- `worker_run_id`
- `decision_reason`
- `control_plane_action`
- `operator_channel_role`
- `operator_channel_kind`
- `operator_channel_execution_repo`

## Deterministic Orchestration Rules
- the runner must call the monday exporter instead of recreating packet logic inside planningops
- the runner must call the planningops evaluator instead of deriving decisions inline
- the runner must call the planningops applier instead of deriving action mappings inline
- the runner must pass the same goal context to the evaluator and applier within one cycle
- the runner must preserve repo-root-relative evidence refs in its emitted cycle report whenever the produced artifact lives inside the repo
- `dry-run` mode must preserve control-plane intent without invoking goal transition side effects beyond those already allowed by the applier in `dry-run`
- `apply` mode may allow the applier to perform goal transition side effects, but only through `planningops/scripts/core/goals/transition_goal_state.py`

## Failure Rules
- exporter failure must fail the cycle before evaluation starts
- evaluator failure must fail the cycle before action application starts
- applier failure must fail the cycle before the runner reports success
- the runner must fail closed and emit deterministic failure evidence instead of silently skipping a stage
- the runner must never report `verdict=pass` when any stage returns `verdict=fail`

## Ownership Boundary
### PlanningOps owns
- cycle orchestration
- cycle report evidence
- control-plane evaluation and action application
- goal transition policy side effects initiated by the applier

### Monday owns
- worker outcome production
- reflection packet export implementation
- operator-channel delivery implementation
- queue persistence and lease mutation

### PlanningOps must not own
- runtime queue dequeue, retry, or dead-letter mutation
- concrete Slack or email transport execution
- transport credentials or delivery target resolution

## Validation
- `planningops/scripts/test_reflection_cycle_orchestration_contract.sh`
- `monday/scripts/export_worker_outcome_reflection_packet.py`
- `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py`
- `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- `planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
