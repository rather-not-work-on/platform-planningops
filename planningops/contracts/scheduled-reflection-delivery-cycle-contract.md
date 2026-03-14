# Scheduled Reflection Delivery Cycle Contract

## Purpose
Define the deterministic boundary for the first queue-aware autonomous control-plane loop:

- `monday scheduled queue cycle -> worker outcome -> reflection cycle -> delivery cycle`

This contract exists so:
- `planningops` can orchestrate one scheduled autonomous loop without embedding queue mutation or transport logic
- `monday` remains the owner of scheduled dequeue, lease/retry state changes, and operator-channel execution
- later queue and scheduler evolution can reuse one auditable stage boundary instead of re-stitching runtime, reflection, and delivery steps ad hoc

## Canonical Boundary
- monday scheduled runtime entrypoint: `monday/scripts/run_scheduled_queue_cycle.py`
- monday reflection exporter: `monday/scripts/export_worker_outcome_reflection_packet.py`
- planningops reflection-cycle runner: `planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
- planningops delivery-cycle runner: `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- planningops scheduled-cycle runner: `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
- scheduler boundary contract: `planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md`
- reflection boundary contract: `planningops/contracts/reflection-cycle-orchestration-contract.md`
- delivery boundary contract: `planningops/contracts/reflection-delivery-cycle-contract.md`

## Cycle Scope
The scheduled reflection-delivery cycle starts when `planningops` invokes the monday-owned scheduled queue entrypoint.

The cycle includes:
1. invoking one monday scheduled queue cycle
2. loading one monday worker outcome artifact from that scheduled run
3. running the planningops-owned reflection cycle over that worker outcome
4. running the planningops-owned delivery cycle over the emitted reflection action artifact
5. writing one planningops-owned aggregate scheduled cycle report

The cycle does not include:
- planningops-owned queue lease mutation
- planningops-owned retry or dead-letter mutation
- direct Slack or email transport execution inside `planningops`
- redesigning monday payload formats or queue persistence

## Required Inputs
Every scheduled reflection-delivery run must accept:
- `--mode` with `dry-run` or `apply`
- `--output`

Optional execution inputs may include:
- `--workspace-root`
- `--monday-repo-dir`
- `--monday-python`
- `--queue-db`
- `--queue-seed-file`
- `--transition-log`
- `--schedule-key`
- `--goal-key`
- `--delivery-target`
- `--channel-kind`
- `--thread-ref`

Input rules:
- the runner must invoke `monday/scripts/run_scheduled_queue_cycle.py` instead of recreating queue dequeue logic in `planningops`
- when `--goal-key` is supplied, it must be forwarded consistently through the scheduled run, reflection cycle, and delivery cycle
- `planningops` may forward operator-channel hints such as `delivery-target`, `channel-kind`, and `thread-ref`, but must not derive concrete transport recipients on its own

## Required Outputs
Every successful run must emit:
- one monday scheduled queue evidence report
- one planningops reflection-cycle report
- one planningops delivery-cycle report
- one planningops-owned aggregate scheduled cycle report

The aggregate scheduled cycle report must include:
- `generated_at_utc`
- `mode`
- `goal_key`
- `scheduled_cycle_report_ref`
- `worker_outcome_ref`
- `reflection_cycle_report_ref`
- `reflection_action_ref`
- `delivery_cycle_report_ref`
- `reflection_decision`
- `action_kind`
- `delivery_required`
- `delivery_skipped`
- `goal_transition_required`
- `goal_transition_report_path`
- `runner_contract_ref`
- `stage_reports`
- `error_count`
- `errors`
- `verdict`

## Stage Reports
`stage_reports` must contain at least:
- `scheduled_queue_cycle`
- `reflection_cycle`
- `delivery_cycle`

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
- the runner must call the monday scheduled queue entrypoint instead of dequeuing work directly in `planningops`
- the runner must derive `worker_outcome_ref` from monday scheduled queue evidence instead of reconstructing worker outcome paths inline
- the runner must call the planningops reflection-cycle runner instead of re-implementing reflection export, evaluation, or action mapping inline
- the runner must call the planningops delivery-cycle runner instead of re-implementing monday delivery invocation inline
- the runner must preserve `goal_transition_report_path` from the reflection action artifact through the delivery cycle and aggregate report
- `delivery_required = false` must still produce a successful aggregate report with `delivery_skipped = true`
- identical `dry-run` inputs must produce the same stage structure and verdicts apart from timestamps

## Ownership Boundary
### PlanningOps owns
- scheduled-cycle orchestration
- aggregate scheduled cycle evidence
- path normalization across scheduled, reflection, and delivery stages
- verification that monday scheduler evidence, reflection evidence, and delivery evidence are wired together correctly

### Monday owns
- queue persistence
- dequeue, lease, retry, and dead-letter mutation
- scheduled queue execution evidence
- worker outcome production
- operator-channel delivery execution

### PlanningOps must not own
- queue row mutation or lease heartbeat logic
- concrete Slack or email transport execution
- delivery target resolution from operator policy
- monday runtime payload schema redesign

## Failure Rules
- missing monday scheduled entrypoint or missing scheduled evidence must fail the cycle
- the runner must fail if monday scheduled queue evidence does not resolve exactly one worker outcome artifact for the current cycle
- reflection-cycle failure must fail the aggregate cycle before delivery starts
- delivery-cycle failure must fail the aggregate cycle even if scheduled and reflection stages passed
- the runner must fail if aggregate evidence would drop `goal_transition_report_path` for a goal-completion path
- the runner must not silently downgrade scheduled, reflection, or delivery failures into `delivery_skipped`

## Validation
- `planningops/scripts/test_scheduled_reflection_delivery_cycle_contract.sh`
- `monday/scripts/run_scheduled_queue_cycle.py`
- `planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
- `planningops/scripts/federation/run_reflection_delivery_cycle.py`
- `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
