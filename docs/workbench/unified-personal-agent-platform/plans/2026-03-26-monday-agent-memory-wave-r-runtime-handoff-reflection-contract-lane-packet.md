---
title: plan: MONDAY Agent Memory Wave R Runtime-Handoff Reflection Contract Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the reflection orchestration and delivery contract regressions into the canonical runtime-handoff helper so the federated runtime lane owns both the monday memory reflection behavior and its control-plane boundary checks.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-q-runtime-handoff-delivery-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-p-delivery-cycle-shared-plumbing-packet.md
  - ./2026-03-26-monday-agent-memory-wave-n-reflection-cycle-shared-plumbing-packet.md
---

# plan: MONDAY Agent Memory Wave R Runtime-Handoff Reflection Contract Lane Packet

## Purpose

Finish the runtime-handoff promotion of the memory reflection stack. After Wave Q, the canonical helper replays the direct and scheduled reflection delivery regressions, but the contract guards for reflection orchestration and delivery still run outside the same lane. Wave R closes that gap so the helper owns both the runtime behavior and the shared boundary contracts.

## Scope

Wave R should add:

- `test_reflection_cycle_orchestration_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_reflection_delivery_cycle_contract.sh` to the same helper-owned runtime lane
- `test_scheduled_reflection_delivery_cycle_contract.sh` to the same helper-owned runtime lane
- contract, wiring, README, and workbench updates freezing that expanded helper inventory

Wave R should not add:

- new reflection packet fields
- new monday queue semantics
- new supervisor handoff behavior
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the three reflection contract regressions
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays the live monday memory reflection path, including direct and scheduled delivery regressions
- reflection-cycle and delivery-cycle contract tests still sit outside the canonical helper inventory

Implement Wave R only:
1. add test_reflection_cycle_orchestration_contract.sh, test_reflection_delivery_cycle_contract.sh, and test_scheduled_reflection_delivery_cycle_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the expanded reflection contract inventory
3. update README/workbench docs so runtime-handoff explicitly owns both the reflection runtime path and its contract boundary
4. verify the helper lane and the full federated matrix stay green
```
