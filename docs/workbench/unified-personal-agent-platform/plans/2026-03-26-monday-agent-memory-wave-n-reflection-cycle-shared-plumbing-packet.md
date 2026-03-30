---
title: plan: MONDAY Agent Memory Wave N Reflection Cycle Shared Plumbing Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Extracts shared repo, workspace, goal-resolution, and stage-report helpers for the planningops reflection-cycle runners so the monday memory control-plane path stops duplicating the same plumbing across worker-outcome and scheduled orchestration surfaces.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-h-control-plane-reflection-packet.md
  - ./2026-03-25-monday-agent-memory-wave-j-scheduled-control-plane-automation-packet.md
  - ./2026-03-26-monday-agent-memory-wave-m-runtime-handoff-supervisor-contract-packet.md
---

# plan: MONDAY Agent Memory Wave N Reflection Cycle Shared Plumbing Packet

## Purpose

Reduce duplicated control-plane plumbing in the monday memory reflection path. The worker-outcome reflection runner and the scheduled reflection-delivery runner both owned the same repo/workspace resolution, goal-context lookup, stage-report rendering, and command execution helpers inline. Wave N extracts that shared surface into one federation-local module.

## Scope

Wave N should add:

- one `planningops/scripts/federation/reflection_cycle_common.py` module for shared repo/workspace/goal/bootstrap helpers
- import rewiring so:
  - `planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
  - `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
  consume that module instead of re-owning the helper block inline
- regression coverage proving both runners import the common module and no longer define the extracted helpers locally
- README/contract/workbench updates freezing the new shared surface

Wave N should not add:

- new reflection vocabulary
- new monday scheduler behavior
- new queue semantics
- a new top-level CLI surface

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/reflection_cycle_common.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_worker_outcome_reflection_cycle_scheduler_report.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_scheduled_reflection_delivery_cycle.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/contracts/reflection-cycle-orchestration-contract.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`

## Acceptance Gates

- both reflection runners import `reflection_cycle_common.py`
- extracted helper names are no longer defined locally in those two runners
- existing reflection/scheduled regressions still pass unchanged in behavior
- runtime-handoff and full federated CI remain green after the extraction

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff canonically owns the monday memory reflection and supervisor handoff chain
- run_worker_outcome_reflection_cycle.py and run_scheduled_reflection_delivery_cycle.py still duplicate the same control-plane helper block

Implement Wave N only:
1. extract shared repo/workspace/goal/stage-report helpers into reflection_cycle_common.py
2. rewire both reflection runners to import that module
3. add regression assertions that the runners import the common module and no longer define the extracted helpers inline
4. update README/contract/workbench docs and keep behavior unchanged
```
