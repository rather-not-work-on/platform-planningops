---
title: plan: MONDAY Agent Memory Wave P Delivery Cycle Shared Plumbing Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Moves the delivery-cycle runner onto the shared reflection control-plane plumbing so all planningops memory reflection runners stop duplicating the same repo, workspace, and path-normalization helpers.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-n-reflection-cycle-shared-plumbing-packet.md
  - ./2026-03-26-monday-agent-memory-wave-o-goal-completion-bridge-shared-plumbing-packet.md
  - ./2026-03-25-monday-agent-memory-wave-j-scheduled-control-plane-automation-packet.md
---

# plan: MONDAY Agent Memory Wave P Delivery Cycle Shared Plumbing Packet

## Purpose

Finish the reflection-runner plumbing cleanup. After Waves N and O, the worker-outcome, scheduled reflection, and goal-completion bridge runners all share `reflection_cycle_common.py`, but `run_reflection_delivery_cycle.py` still owns the same repo/workspace/path and report helpers inline. Wave P moves that runner onto the same shared control-plane module.

## Scope

Wave P should add:

- import rewiring so `planningops/scripts/federation/run_reflection_delivery_cycle.py` consumes `reflection_cycle_common.py`
- regression coverage proving the delivery runner no longer defines the extracted helpers locally
- contract/README/workbench updates freezing `reflection_cycle_common.py` as part of the delivery-cycle boundary

Wave P should not add:

- new monday queue admission semantics
- new delivery target resolution behavior
- new reflection vocabulary
- a new top-level CLI surface

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_reflection_delivery_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/reflection_cycle_common.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_reflection_delivery_cycle.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_reflection_delivery_cycle_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/contracts/reflection-delivery-cycle-contract.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_reflection_delivery_cycle.py` imports `reflection_cycle_common.py`
- extracted helper names are no longer defined locally in the delivery runner
- delivery-cycle, scheduled reflection, and runtime-handoff regressions stay green
- full federated CI remains green after the extraction

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- worker-outcome, scheduled reflection, and goal-completion bridge runners already share reflection_cycle_common.py
- run_reflection_delivery_cycle.py still duplicates repo/workspace/path helper logic inline

Implement Wave P only:
1. rewire run_reflection_delivery_cycle.py to use reflection_cycle_common.py
2. add regression assertions that the delivery runner no longer defines the extracted helpers locally
3. update the delivery-cycle contract and README/workbench docs to include the shared module
4. keep behavior unchanged and verify delivery-cycle plus runtime-handoff still pass
```
