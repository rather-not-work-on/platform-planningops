---
title: plan: MONDAY Agent Memory Wave T Runtime-Handoff Delivery Admission Contract Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the delivery-orchestration and scheduled-admission contract regressions into the canonical runtime-handoff helper so the federated runtime lane owns the full boundary from reflection action to monday scheduled queue handoff.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-s-runtime-handoff-direct-reflection-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-r-runtime-handoff-reflection-contract-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-p-delivery-cycle-shared-plumbing-packet.md
---

# plan: MONDAY Agent Memory Wave T Runtime-Handoff Delivery Admission Contract Lane Packet

## Purpose

Close the remaining delivery-boundary gap around the monday memory reflection path. The canonical helper already owns direct and scheduler-backed reflection execution plus the reflection contracts, but the adjacent delivery-orchestration and scheduled-admission contract guards still sit outside the same lane. Wave T promotes those contract checks into `runtime-handoff`.

## Scope

Wave T should add:

- `test_local_delivery_cycle_orchestration_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_scheduled_delivery_queue_admission_contract.sh` to the same helper-owned runtime lane
- `test_scheduled_queue_admission_handoff_contract.sh` to the same helper-owned runtime lane
- `test_scheduler_native_worker_outcome_selection_contract.sh` to the same helper-owned runtime lane
- `test_scheduled_worker_outcome_handoff_contract.sh` to the same helper-owned runtime lane
- helper contract, wiring, README, and workbench updates freezing the expanded delivery-admission inventory

Wave T should not add:

- new reflection packet fields
- new monday queue mutation behavior
- new worker-outcome semantics
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the five delivery-admission contract regressions
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays direct and scheduler-backed reflection paths plus the reflection contract guards
- delivery orchestration and scheduled-admission contract tests still sit outside the canonical helper inventory

Implement Wave T only:
1. add test_local_delivery_cycle_orchestration_contract.sh, test_scheduled_delivery_queue_admission_contract.sh, test_scheduled_queue_admission_handoff_contract.sh, test_scheduler_native_worker_outcome_selection_contract.sh, and test_scheduled_worker_outcome_handoff_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the expanded delivery-admission contract inventory
3. update README/workbench docs so runtime-handoff explicitly owns the delivery-admission boundary around the memory reflection path
4. verify the helper lane and the full federated matrix remain green
```
