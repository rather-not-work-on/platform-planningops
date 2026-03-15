# Scheduled Queue Admission Handoff Contract

## Purpose
Define the deterministic handoff between the planningops scheduled control-plane runner and the monday-owned queue admission runtime step.

This contract exists so:
- `planningops` can describe one scheduled queue admission request without mutating monday queue storage directly
- `monday` can own queue-store mutation before scheduled execution starts
- the primary scheduled path can stop passing a direct `--queue` seed file into `monday/scripts/run_scheduled_queue_cycle.py`

## Canonical Boundary
- planningops scheduled orchestrator: `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
- monday queue admission CLI: `monday/scripts/admit_scheduled_queue_packet.py`
- monday scheduled queue cycle: `monday/scripts/run_scheduled_queue_cycle.py`
- monday queue store runtime: `monday/scripts/runtime_queue_store.py`
- monday scheduler-native worker-outcome selector: `monday/scripts/select_scheduled_worker_outcome.py`
- scheduler boundary contract: `planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md`
- scheduled cycle contract: `planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`
- worker-outcome handoff contract: `planningops/contracts/scheduled-worker-outcome-handoff-contract.md`
- queue item schema authority: `platform-contracts/schemas/runtime-scheduler-queue-item.schema.json`

## Handoff Scope
The handoff packet exists only to admit one planningops-prepared queue seed into monday-owned queue storage for one scheduled control-plane cycle.

The handoff includes:
- one deterministic reference to the queue seed payload selected by planningops
- the `goal_key` and `schedule_key` that admission must preserve
- enough metadata for monday to validate the packet before queue mutation begins

The handoff does not include:
- direct planningops mutation of monday queue storage
- direct planningops invocation of monday scheduled execution with a primary-path `--queue` seed input
- worker-outcome payloads
- reflection or delivery payloads

## Required Admission Packet
Every emitted admission packet must include:
- `admission_version`
- `generated_at_utc`
- `admission_contract_ref`
- `source_repo`
- `goal_key`
- `schedule_key`
- `queue_seed_ref`
- `seed_format`
- `seed_item_count`
- `verdict`

Field rules:
- `admission_contract_ref` must equal `planningops/contracts/scheduled-queue-admission-handoff-contract.md`
- `source_repo` must equal `rather-not-work-on/platform-planningops`
- `queue_seed_ref` must stay repo-root relative from the `planningops` repo when possible
- `seed_format` must currently equal `runtime_scheduler_queue_items_json`
- `seed_item_count` must equal the number of queue items available in the referenced seed payload
- `verdict` may be only `pass` or `skipped`

## Consumer Rules
`monday/scripts/admit_scheduled_queue_packet.py` must consume the admission packet first and seed monday queue storage before `monday/scripts/run_scheduled_queue_cycle.py` runs on the primary path.

Consumer rules:
- monday must validate `admission_contract_ref` before reading `queue_seed_ref`
- monday must resolve `queue_seed_ref` through the planningops repo root or workspace root, not by assuming the seed lives inside the monday repo
- monday must use `monday/scripts/runtime_queue_store.py` for queue-store mutation instead of re-implementing persistence inline
- monday must preserve `goal_key` and `schedule_key` from the admission packet into admitted queue rows
- monday scheduled execution may still support `--queue` for explicit fixture or fallback flows, but the primary planningops-driven path must use queue admission plus store-only scheduled execution

## Store-Only Scheduled Execution Rules
- once queue admission is in scope, `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py` must call monday admission before monday scheduled execution
- the primary planningops-driven path must not forward a direct `--queue` seed input into `monday/scripts/run_scheduled_queue_cycle.py`
- monday scheduled execution must be able to run from queue-store state plus `--queue-db` on the primary path
- queue admission and scheduled execution must remain deterministic for identical packet input, queue-db state, and mode apart from timestamps

## Ownership Boundary
### PlanningOps owns
- queue admission packet emission
- queue admission orchestration order
- validation that monday admission runs before scheduled execution on the primary path

### Monday owns
- queue-store mutation
- queue seed validation against runtime expectations
- scheduled execution over admitted queue state
- worker-outcome production after scheduled execution starts

### PlanningOps must not own
- queue row insertion into monday storage
- monday queue lease, retry, or dead-letter mutation
- monday runtime schema enforcement logic

## Failure Rules
- missing `queue_seed_ref` when `verdict = pass` must fail the handoff
- missing or mismatched `admission_contract_ref` must fail monday admission
- monday must fail closed if `seed_item_count` disagrees with the referenced queue seed payload
- planningops must fail if monday admission is skipped on the primary path while the queue admission contract is active
- planningops must not silently fall back to direct `--queue` forwarding on the primary path once this contract is in scope

## Validation
- `planningops/scripts/test_scheduled_queue_admission_handoff_contract.sh`
- `planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`
- `planningops/contracts/scheduled-worker-outcome-handoff-contract.md`
- `monday/scripts/admit_scheduled_queue_packet.py`
- `monday/scripts/run_scheduled_queue_cycle.py`
- `monday/scripts/runtime_queue_store.py`
