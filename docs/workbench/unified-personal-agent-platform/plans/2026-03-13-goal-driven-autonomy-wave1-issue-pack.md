---
title: plan: Goal-Driven Autonomy Wave 1 Issue Pack
type: plan
date: 2026-03-13
updated: 2026-03-13
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the first goal-driven autonomy wave that moves Monday-facing operator communication and completion notification out of ad hoc automation prompts into canonical control-plane contracts and execution backlog.
tags:
  - uap
  - autonomy
  - monday
  - slack
  - email
  - backlog
---

# Goal-Driven Autonomy Wave 1 Issue Pack

## Goal

Move from issue-only automation to goal-driven autonomy:
- PlanningOps owns the active goal pointer and completion policy
- Monday owns operator communication and terminal notifications
- Slack communication is modeled as `skill -> CLI/MCP adapter -> Slack API`
- goal completion can trigger a single terminal email without human polling

## Wave 1 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `A80` | 80 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/operator-channel-adapter-contract.md` |
| `A81` | 81 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/goal-completion-contract.md` |
| `A82` | 82 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `docs/workbench/unified-personal-agent-platform/plans/2026-03-13-monday-channel-adapter-wave1-issue-pack.md` |
| `A83` | 83 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-completion-notifier-wave1-issue-pack.md` |
| `A84` | 84 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave1-review.json` |

## Decomposition Rules

- `A80` freezes the Monday-owned Slack skill + CLI/MCP adapter boundary and delivery evidence rules.
- `A81` freezes goal completion and terminal email policy so automation can stop on achieved goals deterministically.
- `A82` projects Monday repo-local implementation work for channel adapters without pushing execution code into PlanningOps.
- `A83` projects Monday repo-local implementation work for completion email notifications and reporting.
- `A84` verifies that active goal state, completion policy, and channel boundary remain aligned.

## Dependencies

- `A81` depends on `A80`
- `A82` depends on `A80`
- `A83` depends on `A81`
- `A84` depends on `A80`, `A81`, `A82`, `A83`

## Non-Goals

- no direct Slack or mail provider credentials in PlanningOps
- no raw HTTP Slack calls authored in prompts
- no Monday execution code inside this repo
