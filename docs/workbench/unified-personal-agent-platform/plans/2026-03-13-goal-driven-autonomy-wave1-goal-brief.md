---
title: plan: Goal-Driven Autonomy Wave 1 Goal Brief
type: plan
date: 2026-03-13
updated: 2026-03-13
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the current active goal for goal-driven autonomy so PlanningOps can resolve a single execution path while monday owns Slack and email delivery adapters.
tags:
  - uap
  - goal
  - autonomy
  - monday
  - slack
  - email
---

# Goal-Driven Autonomy Wave 1 Goal Brief

## Objective

Make long-running autonomy choose work from one canonical active goal and communicate with the operator through `monday`, not through prompt-local ad hoc transport logic.

## Success Outcomes

- `planningops` resolves one active goal from a file-backed registry instead of inferring it from stale backlog state
- supervisor/materialization can derive the current execution contract from that registry
- `monday` becomes the owner of operator-facing channel adapters
- primary operator communication is modeled as `Slack skill -> monday-owned CLI or MCP adapter -> Slack API`
- terminal completion is modeled as `monday-owned CLI or MCP adapter -> email provider`

## Non-Goals

- no Slack or email provider secrets stored in `platform-planningops`
- no direct vendor HTTP logic in planningops scripts or prompts
- no full Slack app provisioning in this wave
- no UI surface beyond monday + external operator channels

## Operator Channels

- primary operator channel: `slack_skill_cli`
- terminal notification channel: `email_cli`

## Completion References

- `planningops/contracts/goal-completion-contract.md`
- `planningops/contracts/operator-channel-adapter-contract.md`

## Execution Contract

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1.execution-contract.json`
