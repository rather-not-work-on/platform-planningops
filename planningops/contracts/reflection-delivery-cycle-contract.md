# Reflection Delivery Cycle Contract

## Purpose
Define the deterministic boundary for the second half of the reflection loop:

- `reflection action artifact -> monday delivery execution -> delivery evidence`

This contract exists so:
- `planningops` can orchestrate the delivery cycle without embedding Slack/email logic
- `monday` keeps ownership of the delivery entrypoint and transport-facing evidence
- later scheduler and queue work can treat operator delivery as one auditable stage instead of prompt-local glue

## Canonical Boundary
- reflection action producer: `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- delivery-cycle runner: `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- monday delivery entrypoint: `monday/scripts/run_operator_message_delivery_cycle.py`
- action handoff contract: `planningops/contracts/reflection-action-handoff-contract.md`
- local delivery-cycle orchestration contract: `planningops/contracts/local-delivery-cycle-orchestration-contract.md`
- operator channel adapter contract: `planningops/contracts/operator-channel-adapter-contract.md`
- local target resolution contract: `planningops/contracts/local-operator-target-resolution-contract.md`
- supervisor handoff contract: `planningops/contracts/supervisor-operator-handoff-contract.md`

## Cycle Scope
The reflection delivery cycle starts only after a valid reflection action artifact exists.

The cycle includes:
- loading the action artifact emitted by `planningops`
- invoking the monday-owned delivery entrypoint
- collecting monday delivery evidence
- writing one planningops-owned aggregate cycle report

The cycle does not include:
- reflection packet export
- reflection evaluation
- queue mutation
- direct Slack or email transport logic inside `planningops`

## Required Inputs
Every delivery-cycle run must accept:
- `--action-file`
- `--mode` with `dry-run` or `apply`
- `--output`

Optional execution inputs may include:
- `--delivery-target`
- `--channel-kind`
- `--thread-ref`
- `--workspace-root`
- `--monday-repo-dir`
- `--monday-python`
- `--monday-profiles-config`

Input rules:
- `--action-file` must point to a `verdict=pass` artifact governed by `planningops/contracts/reflection-action-handoff-contract.md`
- the primary local autonomous path must work without a caller-supplied concrete `delivery-target`
- `planningops` may forward a concrete `delivery-target` only when it is supplied externally; it must not resolve the target from control-plane policy
- when no explicit `delivery-target` is supplied, monday may resolve a local target under `planningops/contracts/local-operator-target-resolution-contract.md`
- `planningops` may forward `channel-kind` and `thread-ref` hints, but must not derive concrete Slack channel IDs or email recipients on its own
- `planningops` may forward a monday-owned local profile config hint only for deterministic testing or local environment selection; it must not author recipient policy inside that config

## Delivery Invocation
The delivery-cycle runner must invoke only:
- `monday/scripts/run_operator_message_delivery_cycle.py`

The runner must not call:
- `monday/scripts/send_operator_message.py`
- `monday/scripts/send_goal_completion_notification.py`
- `monday/scripts/send_reflection_decision_update.py`
directly from `planningops` on the primary local path

The monday entrypoint remains responsible for:
- translating the reflection action into the final operator payload
- emitting delivery evidence
- emitting delivery-cycle evidence under the monday runtime-artifacts boundary

## Required Outputs
Every delivery-cycle run must emit one aggregate report that includes:
- `generated_at_utc`
- `mode`
- `goal_key`
- `reflection_action_ref`
- `reflection_decision`
- `action_kind`
- `message_class_hint`
- `delivery_required`
- `delivery_skipped`
- `monday_delivery_entrypoint`
- `monday_delivery_report_ref`
- `delivery_verdict`
- `delivery_target_resolution_mode`
- `delivery_target_profile_ref`
- `delivery_transport_kind`
- `delivery_outbox_message_ref`
- `goal_transition_report_path`
- `runner_contract_ref`
- `stage_reports`
- `error_count`
- `errors`
- `verdict`

When `delivery_required = false`, the report must still include:
- `reflection_action_ref`
- `delivery_skipped = true`
- `delivery_verdict = skipped`
- `monday_delivery_report_ref = -`

When `delivery_required = true`, the report must include:
- `monday_delivery_entrypoint = monday/scripts/run_operator_message_delivery_cycle.py`
- `monday_delivery_report_ref`
- a projected `delivery_verdict` copied from monday delivery evidence
- a projected `delivery_target_resolution_mode` copied from monday delivery evidence
- a projected `delivery_target_profile_ref` copied from monday delivery evidence when monday resolved a local profile
- a projected `delivery_transport_kind` copied from monday delivery evidence
- a projected `delivery_outbox_message_ref` copied from monday delivery evidence when apply mode wrote a local outbox artifact

## Cycle Report
The aggregate cycle report is the planningops-owned evidence layer for this stage.

The report must:
- stay repo-root relative when pointing at artifacts
- preserve the action artifact path and the monday delivery report path
- summarize local target-resolution and outbox routing without copying concrete recipients or raw transport payloads
- remain deterministic for the same action artifact plus delivery arguments

`stage_reports` must contain at least:
- `delivery_execution`

Each stage report must include:
- `stage`
- `command`
- `cwd`
- `exit_code`
- `stdout_tail`
- `stderr_tail`
- `artifact_path`
- `artifact_exists`
- `verdict`

## Deterministic Orchestration Rules
- the runner must fail closed if the action artifact does not reference `planningops/contracts/reflection-action-handoff-contract.md`
- the runner must call the monday delivery entrypoint instead of invoking lower-level monday delivery CLIs from `planningops`
- `reflection_decision = continue` must not force delivery execution; the cycle may end with `delivery_skipped = true`
- `message_class_hint = goal_completed` must fail closed in this runner because goal-completion delivery belongs to `monday/scripts/run_goal_completion_delivery_cycle.py`
- `goal_transition_report_path` must be preserved from the action artifact into the aggregate report
- `planningops` may orchestrate the monday CLI, but transport behavior and delivery verdict semantics remain monday-owned
- the aggregate report must preserve monday-owned local target resolution evidence without promoting concrete `deliveryTarget` values into planningops-owned fields
- identical `dry-run` inputs must produce the same aggregate verdict and stage structure apart from timestamps

## Ownership Boundary
### PlanningOps owns
- delivery-cycle orchestration
- aggregate cycle evidence
- control-plane path normalization
- validation that the action artifact and monday delivery evidence are wired together correctly

### Monday owns
- reflection-action-to-payload translation for operator-message classes
- local delivery-cycle execution
- Slack/email adapter execution
- transport-facing delivery evidence

### PlanningOps must not own
- concrete Slack or email transport execution
- target resolution from operator policy
- monday messaging payload schema redesign
- queue mutation or retry/dead-letter lifecycle changes

## Failure Rules
- missing monday entrypoint or missing action artifact must fail the cycle
- `delivery_required = true` with missing `delivery-target` must fail only when monday cannot resolve a valid local target under `planningops/contracts/local-operator-target-resolution-contract.md`
- the runner must fail if monday returns non-zero or emits a non-pass delivery report in `dry-run`
- the runner must fail if the monday delivery report cannot be loaded
- the runner must fail if aggregate evidence would drop `goal_transition_report_path` for a goal-completion action
- the runner must not silently downgrade a delivery failure into `delivery_skipped`

## Validation
- `planningops/scripts/test_reflection_delivery_cycle_contract.sh`
- `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- `planningops/scripts/test_reflection_delivery_cycle.sh`
- `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- `monday/scripts/run_operator_message_delivery_cycle.py`
