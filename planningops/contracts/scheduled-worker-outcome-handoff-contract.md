# Scheduled Worker-Outcome Handoff Contract

## Purpose
Define the deterministic handoff between the monday-owned scheduled queue cycle and the planningops-owned scheduled reflection-delivery orchestration.

This contract exists so:
- `monday` can publish one auditable handoff artifact for the current scheduled run
- `planningops` can resolve the correct worker outcome without an explicit `--worker-outcome-json` input
- later scheduler and queue evolution can keep one thin control-plane boundary instead of leaking monday runtime paths into planning prompts or operator glue

## Canonical Boundary
- monday scheduled runtime entrypoint: `monday/scripts/run_scheduled_queue_cycle.py`
- monday queue worker outcome schema: `platform-contracts/schemas/runtime-queue-worker-outcome.schema.json`
- monday reflection exporter: `monday/scripts/export_worker_outcome_reflection_packet.py`
- planningops scheduled orchestrator: `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
- scheduled cycle contract: `planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`
- reflection boundary contract: `planningops/contracts/worker-outcome-reflection-contract.md`

## Handoff Scope
The handoff artifact exists only to bridge one scheduled monday run to one planningops scheduled orchestration run.

The handoff includes:
- one deterministic reference to the worker outcome artifact chosen for the current scheduled run
- enough queue identity to prove which scheduled dequeue decision produced that worker outcome
- the contract references needed for planningops to validate the handoff before reflection starts

The handoff does not include:
- monday queue row mutation commands
- a new reflection packet schema
- Slack or email transport payloads
- more than one worker outcome candidate for the same scheduled run

## Required Handoff Artifact
Every emitted handoff artifact must include:
- `handoff_version`
- `generated_at_utc`
- `handoff_contract_ref`
- `source_repo`
- `scheduled_run_id`
- `scheduled_report_ref`
- `source_worker_outcome_ref`
- `source_worker_outcome_contract_ref`
- `goal_key`
- `schedule_key`
- `queue_item_id`
- `worker_run_id`
- `state_to`
- `transition_reason`
- `verdict`

Field rules:
- `handoff_contract_ref` must equal `planningops/contracts/scheduled-worker-outcome-handoff-contract.md`
- `source_repo` must equal `rather-not-work-on/monday`
- `source_worker_outcome_contract_ref` must equal `platform-contracts/schemas/runtime-queue-worker-outcome.schema.json`
- `scheduled_report_ref` and `source_worker_outcome_ref` must stay repo-root relative from the `monday` repo when possible
- `goal_key`, `schedule_key`, `queue_item_id`, and `worker_run_id` must match the selected worker outcome
- `verdict` may be only `pass` or `skipped`

## Scheduled Evidence Integration
The monday scheduled queue evidence produced by `monday/scripts/run_scheduled_queue_cycle.py` must expose:
- `worker_outcome_handoff_ref`
- `worker_outcome_handoff_contract_ref`
- `handoff_required`

Integration rules:
- when exactly one worker outcome is selected for the current scheduled run, monday must emit one handoff artifact and set `handoff_required = true`
- when the scheduled run ends with `scheduler_no_dequeue`, monday may set `handoff_required = false` and `worker_outcome_handoff_ref = -`
- `worker_outcome_handoff_contract_ref` must equal `planningops/contracts/scheduled-worker-outcome-handoff-contract.md`
- the scheduled evidence must not inline the full worker outcome payload as a replacement for the handoff artifact

## Consumer Rules
`planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py` must consume the monday scheduled evidence first and resolve the handoff artifact from `worker_outcome_handoff_ref`.

Consumer rules:
- planningops must not require an explicit `--worker-outcome-json` input once the handoff path is available
- planningops may load `source_worker_outcome_ref` from the handoff artifact only after the handoff contract passes validation
- planningops must fail closed if the handoff artifact points to a worker outcome from a different `scheduled_run_id`, `goal_key`, or `queue_item_id`
- planningops may preserve `source_worker_outcome_ref` into reflection-cycle evidence, but it must not rewrite monday runtime paths into new control-plane-local paths

## Deterministic Mapping Rules
- one scheduled run may produce zero or one handoff artifact for the current control-plane cycle
- if monday cannot identify exactly one worker outcome for the run, it must fail the scheduled run instead of emitting an ambiguous handoff
- `state_to` in the handoff must match the canonical worker outcome `state_to`
- `transition_reason` in the handoff must match the canonical worker outcome `transition_reason`
- identical scheduled evidence plus identical monday runtime artifacts must resolve the same handoff artifact reference apart from timestamps

## Ownership Boundary
### Monday owns
- queue persistence and dequeue state mutation
- worker outcome production
- handoff artifact emission
- scheduled evidence that points to the handoff artifact

### PlanningOps owns
- handoff validation
- scheduled orchestration that consumes the handoff
- reflection and delivery control-plane sequencing
- aggregate orchestration evidence

### PlanningOps must not own
- queue lease heartbeat logic
- retry or dead-letter mutation
- monday worker outcome generation
- transport execution details

## Failure Rules
- missing `worker_outcome_handoff_ref` when `handoff_required = true` must fail the scheduled orchestration
- missing or mismatched `handoff_contract_ref` must fail the handoff
- missing worker outcome artifact or mismatched queue identity must fail the handoff
- ambiguous multi-outcome selection must fail in `monday` before the handoff is emitted
- planningops must not silently fall back to a manually supplied worker outcome path when the handoff contract is in scope

## Validation
- `planningops/scripts/test_scheduled_worker_outcome_handoff_contract.sh`
- `planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`
- `monday/scripts/run_scheduled_queue_cycle.py`
- `monday/scripts/export_worker_outcome_reflection_packet.py`
- `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
