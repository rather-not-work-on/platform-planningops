---
title: plan: MONDAY Agent Memory Wave V Runtime-Handoff Goal Policy Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the active-goal registry and goal-transition contract regressions into the canonical runtime-handoff helper so the federated runtime lane owns the goal policy layer consumed by the monday memory reflection action path.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-u-runtime-handoff-local-delivery-contract-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-r-runtime-handoff-reflection-contract-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-s-runtime-handoff-direct-reflection-lane-packet.md
---

# plan: MONDAY Agent Memory Wave V Runtime-Handoff Goal Policy Lane Packet

## Purpose

Close the remaining goal-policy gap under the monday memory reflection path. The canonical helper already owns reflection execution, delivery admission, and downstream local delivery contracts, but the active-goal registry and goal-transition policy checks still sit outside that same lane. Wave V promotes those policy checks into `runtime-handoff`.

## Scope

Wave V should add:

- `test_active_goal_registry_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_transition_goal_state_contract.sh` to the same helper-owned runtime lane
- helper contract, wiring, README, and workbench updates freezing that expanded goal-policy inventory

Wave V should not add:

- new goal lifecycle behavior
- new reflection action fields
- new monday delivery behavior
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes `test_active_goal_registry_contract.sh` and `test_transition_goal_state_contract.sh`
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays reflection execution plus the delivery-admission and local delivery contract layers
- active-goal registry and goal-transition contract tests still sit outside the canonical helper inventory

Implement Wave V only:
1. add test_active_goal_registry_contract.sh and test_transition_goal_state_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the goal-policy steps
3. update README/workbench docs so runtime-handoff explicitly owns the goal-policy boundary consumed by the reflection action path
4. verify the helper lane and the full federated matrix remain green
```
