# Scheduler-Native Worker-Outcome Selection Contract

## Purpose
Define the monday-owned selector boundary that resolves exactly one worker outcome for the current scheduled queue run before the handoff reaches planningops.

This contract exists so:
- `monday` can resolve the current scheduled worker outcome from runtime-owned evidence instead of a control-plane-supplied bridge path
- `planningops` can consume only monday-emitted handoff evidence for the primary scheduled reflection-delivery path
- later scheduler and queue evolution can keep worker-outcome selection inside runtime ownership instead of leaking file-selection heuristics into planningops

## Canonical Boundary
- monday scheduled runtime entrypoint: `monday/scripts/run_scheduled_queue_cycle.py`
- monday scheduler-native selector: `monday/scripts/select_scheduled_worker_outcome.py`
- monday scheduler evidence schema: `monday/contracts/runtime-scheduler-evidence.schema.json`
- monday worker outcome schema: `platform-contracts/schemas/runtime-queue-worker-outcome.schema.json`
- monday scheduled worker-outcome handoff contract: `planningops/contracts/scheduled-worker-outcome-handoff-contract.md`
- planningops scheduled orchestrator: `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`

## Selection Scope
The selector exists only to resolve one canonical worker outcome for one scheduled monday run.

The selector includes:
- reading monday-owned scheduler evidence for the current `scheduled_run_id`
- verifying queue identity for the scheduled dequeue decision
- resolving one worker outcome artifact for the selected queue item
- returning deterministic references that the scheduled queue cycle can convert into handoff evidence

The selector does not include:
- queue dequeue, lease, retry, or dead-letter mutation
- planningops-owned path normalization
- reflection export, evaluation, or delivery orchestration
- more than one worker outcome candidate for the same scheduled run

## Required Selector Inputs
Every scheduler-native selection run must accept enough monday-owned evidence to resolve the current worker outcome without a planningops-supplied worker-outcome path.

Required selector inputs:
- `scheduled_run_id`
- one monday scheduler evidence document for that run
- one monday-owned runtime-artifact root or equivalent runtime-owned search base

Input rules:
- the selector must treat monday scheduler evidence as the source of truth for `goal_key`, `schedule_key`, `queue_item_id`, and `worker_run_id`
- the selector must not require `--worker-outcome-json` for the primary path
- any compatibility bridge input must remain explicitly marked as legacy and must not redefine the canonical selector contract

## Required Selector Output
Every successful selector run must emit or return:
- `selected = true`
- `scheduled_run_id`
- `goal_key`
- `schedule_key`
- `queue_item_id`
- `worker_run_id`
- `source_worker_outcome_ref`
- `source_worker_outcome_contract_ref`
- `selection_reason`
- `selector_contract_ref`
- `verdict`

Field rules:
- `selector_contract_ref` must equal `planningops/contracts/scheduler-native-worker-outcome-selection-contract.md`
- `source_worker_outcome_contract_ref` must equal `platform-contracts/schemas/runtime-queue-worker-outcome.schema.json`
- `source_worker_outcome_ref` must remain repo-root relative from the `monday` repo when possible
- `selection_reason` may be only `scheduled_run_match` or `scheduler_no_dequeue`
- `verdict` may be only `pass`, `skipped`, or `fail`

## Handoff Integration Rules
The monday scheduled queue cycle must use the selector output to populate the scheduled worker-outcome handoff artifact.

Integration rules:
- when the scheduler evidence shows one dequeued queue item for the current run, monday must resolve exactly one selector output before the handoff is written
- when the scheduler evidence shows `scheduler_no_dequeue`, monday may emit `selected = false` semantics through the scheduled evidence and skip handoff creation
- the handoff artifact must inherit `goal_key`, `schedule_key`, `queue_item_id`, `worker_run_id`, and `source_worker_outcome_ref` from the selector output instead of a planningops bridge argument
- planningops must treat the selector-driven handoff as the canonical source for the primary path

## PlanningOps Consumer Expectations
`planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py` must consume monday scheduled evidence that was produced from the selector boundary.

Consumer rules:
- planningops must not decide which worker outcome file is canonical for a scheduled run
- planningops may validate monday-emitted selector results only through the handoff contract
- planningops must fail closed if the handoff points to a worker outcome whose `scheduled_run_id`, `goal_key`, `schedule_key`, or `queue_item_id` does not match the monday scheduler evidence
- planningops may keep a legacy bridge flag only as an explicit compatibility path until the selector path is fully wired, but it must not remain the primary scheduled orchestration input

## Deterministic Mapping Rules
- one scheduled run may resolve zero or one selector result for the current control-plane cycle
- if monday cannot identify exactly one worker outcome for the scheduled run, the selector must fail instead of guessing
- identical monday scheduler evidence plus identical runtime-artifact state must resolve the same `source_worker_outcome_ref` apart from timestamps
- selector resolution must not depend on planningops-owned temporary directories or artifact copies

## Ownership Boundary
### Monday owns
- scheduler evidence
- runtime-artifact lookup for the current worker outcome
- selector execution and error handling
- handoff emission derived from selector output

### PlanningOps owns
- contracts that validate the selector/handoff boundary
- scheduled orchestration that consumes monday-emitted handoff evidence
- review artifacts that prove the selector path remains monday-owned

### PlanningOps must not own
- worker outcome candidate search logic
- scheduler evidence mutation
- queue state mutation
- runtime-artifact selection caches for monday runs

## Failure Rules
- missing scheduler evidence for the current run must fail selection
- missing or ambiguous worker outcome candidates must fail selection
- mismatched `goal_key`, `schedule_key`, `queue_item_id`, or `worker_run_id` between scheduler evidence and worker outcome evidence must fail selection
- planningops must not silently fall back to a handwritten `source_worker_outcome_ref` when the selector contract is in scope

## Validation
- `planningops/scripts/test_scheduler_native_worker_outcome_selection_contract.sh`
- `planningops/scripts/test_scheduled_worker_outcome_handoff_contract.sh`
- `planningops/scripts/test_scheduled_reflection_delivery_cycle_contract.sh`
- `monday/scripts/select_scheduled_worker_outcome.py`
- `monday/scripts/run_scheduled_queue_cycle.py`
- `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
