---
title: plan: MONDAY Agent Memory Wave S Runtime-Handoff Direct Reflection Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the direct worker-outcome reflection regression into the canonical runtime-handoff helper so the federated runtime lane owns both reflection entry modes into the monday memory control-plane path.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-r-runtime-handoff-reflection-contract-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-q-runtime-handoff-delivery-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-n-reflection-cycle-shared-plumbing-packet.md
---

# plan: MONDAY Agent Memory Wave S Runtime-Handoff Direct Reflection Lane Packet

## Purpose

Close the remaining runtime-handoff reflection-entry gap. The canonical helper already replays the scheduler-backed reflection path plus delivery and goal-completion follow-ons, but the direct worker-outcome reflection regression still runs outside that lane. Wave S promotes the direct reflection entrypoint into the same helper-owned runtime path.

## Scope

Wave S should add:

- `test_worker_outcome_reflection_cycle.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- helper contract and wiring assertions proving the direct reflection regression stays inside the helper-owned runtime lane
- README and workbench updates documenting that runtime-handoff owns both direct and scheduler-backed reflection entry modes

Wave S should not add:

- new reflection packet fields
- new monday worker-outcome semantics
- new delivery behavior
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes `test_worker_outcome_reflection_cycle.sh`
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays the scheduler-backed reflection path, goal-completion bridge, delivery-cycle path, and reflection contracts
- the direct worker-outcome reflection regression still sits outside the canonical helper inventory

Implement Wave S only:
1. add test_worker_outcome_reflection_cycle.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the direct reflection step
3. update README/workbench docs so runtime-handoff explicitly owns both direct and scheduler-backed reflection entry modes
4. verify the helper lane and the full federated matrix remain green
```
