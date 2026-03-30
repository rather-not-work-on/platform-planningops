---
title: plan: MONDAY Agent Memory Wave J Scheduled Control-Plane Automation Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next planningops slice after goal-completion bridge wiring: the canonical scheduled reflection runner must automatically branch terminal memory completions into the supervisor goal-completion handoff path.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-i-goal-completion-handoff-packet.md
  - ./2026-03-25-monday-agent-memory-wave-h-control-plane-reflection-packet.md
---

# plan: MONDAY Agent Memory Wave J Scheduled Control-Plane Automation Packet

## Purpose

Move the new memory goal-completion bridge from a manual utility into the canonical scheduled control-plane loop. After monday scheduler evidence yields a terminal `goal_completed` reflection action, planningops should automatically select the supervisor goal-completion handoff path instead of the generic reflection delivery path.

## Scope

Wave J should add:

- one branch inside `run_scheduled_reflection_delivery_cycle.py` that detects terminal `goal_completed` reflection actions
- automatic invocation of `run_reflection_goal_completion_handoff_cycle.py` for that branch
- regression coverage proving scheduled monday completion evidence now lands in monday goal-completion scheduled admission without manual bridge calls
- contract and README updates that freeze the terminal scheduled branch as canonical behavior

Wave J should not yet add:

- batching multiple terminal scheduler outcomes in one control-plane pass
- automatic monday delivery execution after queue admission
- non-terminal reflection vocabulary changes

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_scheduled_reflection_delivery_cycle.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`

## Acceptance Gates

- terminal `goal_completed` reflection actions no longer flow into `run_reflection_delivery_cycle.py`
- the scheduled runner calls `run_reflection_goal_completion_handoff_cycle.py` for terminal completions
- apply-mode scheduled completion runs admit a monday `goal_completion_delivery` queue item
- the resolved goal registry transitions the completed memory goal to `achieved`
- non-terminal scheduled outcomes still use the generic reflection delivery runner unchanged

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops scheduled control-plane loop.

Current state:
- monday scheduler evidence already feeds planningops reflection
- planningops already has a goal-completion bridge runner for terminal memory reflection actions
- the canonical scheduled runner still routes every reflection action through the generic delivery cycle

Implement Wave J only:
1. detect terminal goal-completed reflection actions inside the scheduled runner
2. route those actions through run_reflection_goal_completion_handoff_cycle.py
3. keep non-terminal delivery behavior unchanged
4. add regression coverage for an apply-mode scheduled completion case
```
