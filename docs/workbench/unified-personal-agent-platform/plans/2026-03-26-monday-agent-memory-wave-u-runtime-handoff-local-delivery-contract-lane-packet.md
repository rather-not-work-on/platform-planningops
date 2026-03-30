---
title: plan: MONDAY Agent Memory Wave U Runtime-Handoff Local Delivery Contract Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the reflection-action and local delivery execution contract regressions into the canonical runtime-handoff helper so the federated runtime lane owns the downstream boundary from planningops action artifacts to monday local delivery-cycle handoff.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-t-runtime-handoff-delivery-admission-contract-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-s-runtime-handoff-direct-reflection-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-p-delivery-cycle-shared-plumbing-packet.md
---

# plan: MONDAY Agent Memory Wave U Runtime-Handoff Local Delivery Contract Lane Packet

## Purpose

Close the remaining downstream delivery contract gap around the monday memory reflection path. The canonical helper already owns reflection, delivery orchestration, and scheduled-admission boundaries, but the action-handoff and local delivery execution contracts still sit outside the same lane. Wave U promotes those contracts into `runtime-handoff`.

## Scope

Wave U should add:

- `test_reflection_action_handoff_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_scheduled_delivery_cycle_handoff_contract.sh` to the same helper-owned runtime lane
- `test_local_delivery_cycle_entrypoint_contract.sh` to the same helper-owned runtime lane
- `test_local_operator_target_resolution_contract.sh` to the same helper-owned runtime lane
- `test_local_outbox_dispatch_handoff_contract.sh` to the same helper-owned runtime lane
- `test_local_dispatch_cycle_handoff_contract.sh` to the same helper-owned runtime lane
- helper contract, wiring, README, and workbench updates freezing that expanded downstream delivery inventory

Wave U should not add:

- new monday delivery behavior
- new reflection action fields
- new transport semantics
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the six downstream delivery contract regressions
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays reflection execution, reflection contracts, and delivery-admission contracts
- the downstream reflection-action and local delivery execution contract tests still sit outside the canonical helper inventory

Implement Wave U only:
1. add test_reflection_action_handoff_contract.sh, test_scheduled_delivery_cycle_handoff_contract.sh, test_local_delivery_cycle_entrypoint_contract.sh, test_local_operator_target_resolution_contract.sh, test_local_outbox_dispatch_handoff_contract.sh, and test_local_dispatch_cycle_handoff_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the expanded downstream delivery contract inventory
3. update README/workbench docs so runtime-handoff explicitly owns the downstream action-handoff and local delivery execution boundary
4. verify the helper lane and the full federated matrix remain green
```
