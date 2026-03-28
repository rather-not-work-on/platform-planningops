# Reflection Delivery Cycle Contract

## Purpose
Define the deterministic boundary for the second half of the reflection loop:

- `reflection action artifact -> monday queue admission -> queued delivery evidence`

This contract exists so:
- `planningops` can orchestrate recurring delivery intent without embedding Slack/email logic
- `monday` keeps ownership of queue admission, downstream delivery-entrypoint selection, and runtime mutation
- later scheduler work can treat reflection-triggered delivery as one auditable queue-admission stage instead of prompt-local glue

## Canonical Boundary
- reflection action producer: `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- shared control-plane plumbing: `planningops/scripts/federation/reflection_cycle_common.py`
- delivery-cycle runner: `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- monday delivery entrypoint: `monday/scripts/enqueue_scheduled_delivery_work_item.py`
- action handoff contract: `planningops/contracts/reflection-action-handoff-contract.md`
- scheduled delivery queue admission contract: `planningops/contracts/scheduled-delivery-queue-admission-contract.md`
- local delivery-cycle orchestration contract: `planningops/contracts/local-delivery-cycle-orchestration-contract.md`
- operator channel adapter contract: `planningops/contracts/operator-channel-adapter-contract.md`
- supervisor handoff contract: `planningops/contracts/supervisor-operator-handoff-contract.md`

## Cycle Scope
The reflection delivery cycle starts only after a valid reflection action artifact exists.

The cycle includes:
- loading the action artifact emitted by `planningops`
- invoking the monday-owned queue-admission entrypoint
- collecting monday queue-admission evidence
- writing one planningops-owned aggregate cycle report

The cycle does not include:
- reflection packet export
- reflection evaluation
- monday queue-row mutation inside `planningops`
- direct Slack or email transport logic inside `planningops`
- direct planningops invocation of monday one-shot delivery-cycle entrypoints

## Required Inputs
Every delivery-cycle run must accept:
- `--action-file`
- `--schedule-key`
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
- `--monday-queue-db`

Input rules:
- `--action-file` must point to a `verdict=pass` artifact governed by `planningops/contracts/reflection-action-handoff-contract.md`
- the primary recurring path must work without a caller-supplied concrete `delivery-target`
- `planningops` may forward a concrete `delivery-target` only when it is supplied externally; it must not resolve the target from control-plane policy
- `planningops` may forward `channel-kind` and `thread-ref` hints, but must not derive concrete Slack channel IDs or email recipients on its own
- `planningops` may forward a monday-owned local profile config hint only for deterministic testing or local environment selection; it must not author recipient policy inside that config
- `planningops` may forward a monday-owned queue-db override only for deterministic testing; it must not author monday queue mutation fields directly

## Delivery Invocation
The delivery-cycle runner must invoke only:
- `monday/scripts/enqueue_scheduled_delivery_work_item.py`

The runner must not call:
- `monday/scripts/run_operator_message_delivery_cycle.py`
- `monday/scripts/run_goal_completion_delivery_cycle.py`
- `monday/scripts/send_operator_message.py`
- `monday/scripts/send_goal_completion_notification.py`
- `monday/scripts/send_reflection_decision_update.py`
directly from `planningops` on the primary recurring path

The monday entrypoint remains responsible for:
- translating the reflection action into one scheduled delivery work item
- selecting the downstream monday delivery-cycle entrypoint
- emitting queue-admission evidence under the monday runtime-artifacts boundary

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
- `queue_admission_verdict`
- `selected_delivery_entrypoint`
- `scheduled_delivery_work_item_ref`
- `scheduled_queue_item_ref`
- `scheduled_queue_item_id`
- `delivery_idempotency_key`
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
- `monday_delivery_entrypoint = monday/scripts/enqueue_scheduled_delivery_work_item.py`
- `monday_delivery_report_ref`
- a projected `delivery_verdict` that distinguishes `dry_run` from `queued`
- `queue_admission_verdict` copied from monday queue-admission evidence
- `selected_delivery_entrypoint`
- `scheduled_delivery_work_item_ref`
- `scheduled_queue_item_ref`
- `scheduled_queue_item_id`
- `delivery_idempotency_key`

## Cycle Report
The aggregate cycle report is the planningops-owned evidence layer for this stage.

The report must:
- stay workspace-relative when pointing at monday-owned runtime artifacts
- preserve the action artifact path and the monday queue-admission report path
- summarize queue-admission and downstream entrypoint selection without copying concrete recipients or raw transport payloads
- remain deterministic for the same action artifact plus queue-admission arguments

`stage_reports` must contain at least:
- `queue_admission`

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
- the runner must call the monday queue-admission entrypoint instead of invoking monday delivery-cycle CLIs from `planningops`
- `reflection_decision = continue` must not force queue admission; the cycle may end with `delivery_skipped = true`
- `message_class_hint = goal_completed` must fail closed in this runner because goal-completion queue admission belongs to the supervisor handoff path
- `goal_transition_report_path` must be preserved from the action artifact into the aggregate report
- `planningops` may orchestrate the monday CLI, but downstream delivery entrypoint selection and queue mutation semantics remain monday-owned
- the aggregate report must preserve monday-owned queue-item identity and selected delivery-entrypoint evidence without promoting concrete `deliveryTarget` values into planningops-owned fields
- identical `dry-run` inputs must produce the same aggregate verdict and stage structure apart from timestamps

## Ownership Boundary
### PlanningOps owns
- delivery-cycle orchestration
- aggregate cycle evidence
- control-plane path normalization
- validation that the action artifact and monday queue-admission evidence are wired together correctly

### Monday owns
- reflection-action-to-payload translation for operator-message classes
- scheduled delivery work-item creation
- queue-row mutation
- downstream local delivery-cycle entrypoint selection
- transport-facing delivery execution and runtime evidence

### PlanningOps must not own
- concrete Slack or email transport execution
- target resolution from operator policy
- monday queue insertion mutation
- monday messaging payload schema redesign
- retry/dead-letter lifecycle changes

## Failure Rules
- missing monday entrypoint or missing action artifact must fail the cycle
- the runner must fail if monday returns non-zero or emits a non-pass queue-admission report
- the runner must fail if the monday queue-admission report cannot be loaded
- the runner must fail if queue-admission evidence omits the selected downstream delivery entrypoint or queue-item identity
- the runner must fail if aggregate evidence would drop `goal_transition_report_path`
- the runner must not silently downgrade a queue-admission failure into `delivery_skipped`

## Validation
- `planningops/scripts/test_reflection_delivery_cycle_contract.sh`
- `planningops/scripts/federation/reflection_cycle_common.py`
- `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- `planningops/scripts/test_reflection_delivery_cycle.sh`
- `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- `monday/scripts/enqueue_scheduled_delivery_work_item.py`
