---
title: plan: MONDAY Agent Memory Wave L Shared Handoff Surface Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Extracts the goal-completion bridge off the large autonomous supervisor script by introducing a dedicated shared handoff helper module for operator report, inbox payload, bundle, and monday terminal admission surfaces.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-k-runtime-handoff-ci-packet.md
  - ./2026-03-25-monday-agent-memory-wave-i-goal-completion-handoff-packet.md
---

# plan: MONDAY Agent Memory Wave L Shared Handoff Surface Packet

## Purpose

Reduce structural coupling in the control-plane memory path. After Wave K, runtime-handoff owns the monday memory reflection regressions canonically, but `run_reflection_goal_completion_handoff_cycle.py` still imports a wide helper surface directly from `autonomous_supervisor_loop.py`. Wave L extracts that bridge dependency onto a dedicated shared module.

## Scope

Wave L should add:

- one `planningops/scripts/supervisor_handoff_common.py` module containing the shared operator handoff/report/rendering helpers used by the goal-completion bridge
- import rewiring so `run_reflection_goal_completion_handoff_cycle.py` depends on the new common module instead of `autonomous_supervisor_loop.py`
- regression coverage proving the bridge import boundary now points at the common module
- README/workbench updates freezing the extracted shared surface

Wave L should not yet add:

- full deduplication of `autonomous_supervisor_loop.py`
- any change to monday queue semantics, reflection vocabulary, or delivery behavior
- a new public CLI surface

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/supervisor_handoff_common.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_reflection_goal_completion_handoff_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_reflection_goal_completion_handoff_cycle.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- the goal-completion bridge no longer imports `autonomous_supervisor_loop.py`
- the new common module owns the shared operator report, inbox payload, bundle, and monday goal-completion admission helpers used by the bridge
- bridge behavior remains unchanged under the existing cross-repo memory reflection regression
- runtime-handoff and federated CI still stay green after the extraction

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already owns the monday memory reflection chain in federated CI
- the goal-completion bridge still imports handoff/report helpers from autonomous_supervisor_loop.py

Implement Wave L only:
1. extract the bridge-consumed operator handoff helpers into supervisor_handoff_common.py
2. rewire run_reflection_goal_completion_handoff_cycle.py to import that common module
3. add a regression that proves the bridge no longer imports autonomous_supervisor_loop.py
4. keep behavior unchanged and verify the existing memory reflection path still passes
```
