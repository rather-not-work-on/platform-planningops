---
title: plan: MONDAY Agent Memory Wave M Runtime-Handoff Supervisor Contract Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the shared-handoff-aware autonomous supervisor contract into the canonical runtime-handoff CI helper so the upstream supervisor surface is sealed in the same lane as the monday memory reflection bridges.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-k-runtime-handoff-ci-packet.md
  - ./2026-03-25-monday-agent-memory-wave-l-shared-handoff-surface-packet.md
---

# plan: MONDAY Agent Memory Wave M Runtime-Handoff Supervisor Contract Packet

## Purpose

Seal the upstream supervisor surface inside the same runtime lane that already owns the monday memory reflection chain. After Wave L, the goal-completion bridge and supervisor loop both depend on `supervisor_handoff_common.py`, but `run_runtime_handoff_ci_check.sh` still only replayed the downstream bridge regressions. Wave M promotes the autonomous supervisor contract into that canonical helper.

## Scope

Wave M should add:

- `planningops/scripts/test_autonomous_supervisor_loop_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` step inventory
- helper contract and wiring coverage proving runtime-handoff now owns the supervisor-loop contract as well as the downstream bridge chain
- README/workbench documentation describing runtime-handoff as the CI home for the shared supervisor handoff dependency

Wave M should not add:

- new monday runtime behavior
- new control-plane reflection semantics
- extra standalone CI helpers for this same surface

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/docs/workbench/unified-personal-agent-platform/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes `planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
- local/workflow runtime-handoff surfaces still call only the helper
- runtime-handoff helper still passes end to end with the added supervisor contract regression
- README/workbench docs describe runtime-handoff as the canonical lane for the shared supervisor handoff dependency

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already owns the monday memory scheduler reflection chain
- autonomous_supervisor_loop.py now sources its live handoff helpers from supervisor_handoff_common.py
- the helper does not yet replay the autonomous supervisor contract that seals that dependency

Implement Wave M only:
1. add test_autonomous_supervisor_loop_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring coverage to require that new step
3. update README/workbench docs so runtime-handoff is the canonical CI home for the shared supervisor handoff dependency
4. keep the lane helper-only for local/workflow callers and verify it still passes
```
