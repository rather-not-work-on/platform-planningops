---
title: plan: MONDAY Agent Memory Wave O Goal-Completion Bridge Shared Plumbing Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Moves the goal-completion bridge onto the shared reflection control-plane plumbing so monday memory terminal-completion orchestration no longer duplicates repo, workspace, goal-resolution, and path helpers inline.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-i-goal-completion-handoff-packet.md
  - ./2026-03-26-monday-agent-memory-wave-n-reflection-cycle-shared-plumbing-packet.md
  - ./2026-03-26-monday-agent-memory-wave-m-runtime-handoff-supervisor-contract-packet.md
---

# plan: MONDAY Agent Memory Wave O Goal-Completion Bridge Shared Plumbing Packet

## Purpose

Finish the reflection-side plumbing extraction. After Wave N, the worker-outcome and scheduled reflection runners share `reflection_cycle_common.py`, but `run_reflection_goal_completion_handoff_cycle.py` still carries its own repo/workspace/goal/path helpers. Wave O moves that bridge onto the same shared control-plane module while leaving handoff rendering and monday admission on `supervisor_handoff_common.py`.

## Scope

Wave O should add:

- import rewiring so `planningops/scripts/federation/run_reflection_goal_completion_handoff_cycle.py` sources repo/workspace/goal/path helpers from `reflection_cycle_common.py`
- regression coverage proving the bridge now depends on both shared modules:
  - `reflection_cycle_common.py` for control-plane plumbing
  - `supervisor_handoff_common.py` for operator handoff/report/admission helpers
- README/workbench updates freezing that split boundary

Wave O should not add:

- new monday queue behavior
- new supervisor handoff semantics
- new reflection vocabulary
- a new CLI surface

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_reflection_goal_completion_handoff_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/reflection_cycle_common.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_reflection_goal_completion_handoff_cycle.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/docs/workbench/unified-personal-agent-platform/README.md`

## Acceptance Gates

- the goal-completion bridge imports `reflection_cycle_common.py` for shared control-plane plumbing
- the goal-completion bridge still imports `supervisor_handoff_common.py` for operator handoff/report/admission helpers
- extracted control-plane helper names are no longer defined locally in the bridge
- runtime-handoff and full federated CI remain green after the extraction

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- worker-outcome and scheduled reflection runners already share reflection_cycle_common.py
- the goal-completion bridge still duplicates repo/workspace/goal/path plumbing inline
- handoff/report/admission helpers already live in supervisor_handoff_common.py

Implement Wave O only:
1. rewire run_reflection_goal_completion_handoff_cycle.py to use reflection_cycle_common.py for control-plane plumbing
2. keep handoff rendering/admission on supervisor_handoff_common.py
3. update the cross-repo bridge regression to prove that split boundary
4. update README/workbench docs and keep behavior unchanged
```
