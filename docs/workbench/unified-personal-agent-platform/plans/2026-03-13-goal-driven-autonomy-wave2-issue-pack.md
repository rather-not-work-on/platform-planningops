---
title: plan: Goal-Driven Autonomy Wave 2 Issue Pack
type: plan
date: 2026-03-13
updated: 2026-03-13
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the second goal-driven autonomy wave so PlanningOps can promote achieved goals automatically and hand the next execution contract to long-running automation without manual backlog surgery.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - automation
  - backlog
---

# Goal-Driven Autonomy Wave 2 Issue Pack

## Goal

Move from a single active-goal registry entry to a self-healing goal lifecycle:
- achieved goals become explicit registry state, not stale active pointers
- automation can promote the next goal deterministically
- monday channel work continues to be projected from planningops instead of embedded in automation prompts

## Wave 2 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `B90` | 90 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/goal-lifecycle-transition-contract.md` |
| `B91` | 91 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/core/goals/transition_goal_state.py` |
| `B92` | 92 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `B93` | 93 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `docs/workbench/unified-personal-agent-platform/plans/2026-03-13-monday-skill-bridge-wave1-issue-pack.md` |
| `B94` | 94 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave2-review.json` |

## Decomposition Rules

- `B90` freezes the allowed registry transitions between `draft`, `active`, `blocked`, `achieved`, and `archived`.
- `B91` introduces a deterministic state-transition script for the active-goal registry and corresponding evidence output.
- `B92` teaches the supervisor to promote or switch goals before it falls back to closed-issue replanning.
- `B93` projects the follow-up monday skill bridge wave so Slack skill packaging is still driven from canonical planningops documents.
- `B94` verifies that goal lifecycle promotion now works without pulling monday execution logic back into planningops.

## Dependencies

- `B91` depends on `B90`
- `B92` depends on `B90`, `B91`
- `B93` depends on `B90`
- `B94` depends on `B90`, `B91`, `B92`, `B93`

## Non-Goals

- no Slack skill implementation inside `platform-planningops`
- no real mail provider transport implementation inside this wave
- no reopening of achieved wave 1 issues
