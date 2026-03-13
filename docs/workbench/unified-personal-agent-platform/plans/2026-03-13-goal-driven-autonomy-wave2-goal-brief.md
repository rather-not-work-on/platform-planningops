---
title: plan: Goal-Driven Autonomy Wave 2 Goal Brief
type: plan
date: 2026-03-13
updated: 2026-03-13
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next active goal for goal-driven autonomy so the supervisor can promote achieved goals and continue into a new execution contract without manual registry edits.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - automation
---

# Goal-Driven Autonomy Wave 2 Goal Brief

## Objective

Make long-running autonomy continue after one goal is achieved by promoting the next goal deterministically instead of stalling on closed backlog drift.

## Success Outcomes

- `planningops` can move a completed goal from `active` to `achieved` or `archived` without hand-editing the registry
- supervisor logic can discover or promote the next active goal before falling back to ad hoc replanning
- monday-owned channel baselines remain the only operator-facing delivery boundary
- follow-up skill or transport work is projected from the active goal registry instead of prompt-local backlog invention

## Non-Goals

- no direct Slack or email provider secrets in `platform-planningops`
- no transport-specific implementation inside planningops scripts
- no new provider or observability runtime work in this wave
- no UI surface beyond planningops and monday contracts

## Operator Channels

- primary operator channel: `slack_skill_cli`
- terminal notification channel: `email_cli`

## Completion References

- `planningops/contracts/goal-completion-contract.md`
- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/active-goal-registry-contract.md`

## Execution Contract

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2.execution-contract.json`
