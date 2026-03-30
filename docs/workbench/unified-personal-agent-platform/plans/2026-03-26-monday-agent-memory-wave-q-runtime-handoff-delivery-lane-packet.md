---
title: plan: MONDAY Agent Memory Wave Q Runtime-Handoff Delivery Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the direct reflection-delivery regression into the canonical runtime-handoff CI helper so the federated runtime lane owns the full monday memory reflection path, not just the scheduled branch.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-m-runtime-handoff-supervisor-contract-packet.md
  - ./2026-03-26-monday-agent-memory-wave-p-delivery-cycle-shared-plumbing-packet.md
  - ./2026-03-25-monday-agent-memory-wave-k-runtime-handoff-ci-packet.md
---

# plan: MONDAY Agent Memory Wave Q Runtime-Handoff Delivery Lane Packet

## Purpose

Finish the CI promotion of the shared reflection path. Wave P moved `run_reflection_delivery_cycle.py` onto the common reflection plumbing, but the canonical `runtime-handoff` helper still replayed only the scheduler-backed branch. Wave Q closes that gap by making the direct delivery-cycle regression part of the same helper-owned runtime lane.

## Scope

Wave Q should add:

- `test_reflection_delivery_cycle.sh` to the canonical `run_runtime_handoff_ci_check.sh` step inventory
- helper contract and wiring assertions proving the direct delivery-cycle regression stays inside the helper-owned runtime lane
- README/workbench updates documenting that `runtime-handoff` owns both the direct and scheduled monday memory reflection delivery paths

Wave Q should not add:

- new delivery behavior
- new reflection packet fields
- new monday queue semantics
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes `test_reflection_delivery_cycle.sh`
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix stay green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- the direct delivery-cycle runner already uses reflection_cycle_common.py
- runtime-handoff currently replays reflection, goal-completion handoff, and scheduled delivery checks
- the direct delivery-cycle regression is still outside the canonical runtime-handoff helper inventory

Implement Wave Q only:
1. add test_reflection_delivery_cycle.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the new delivery-cycle step
3. update README/workbench docs so runtime-handoff explicitly owns both direct and scheduled delivery paths
4. verify the helper lane and the full federated matrix remain green
```
