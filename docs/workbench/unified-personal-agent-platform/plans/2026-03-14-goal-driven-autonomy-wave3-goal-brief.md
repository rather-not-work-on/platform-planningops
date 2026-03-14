---
title: plan: Goal-Driven Autonomy Wave 3 Goal Brief
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next active goal for goal-driven autonomy so PlanningOps hands supervisor status and completion artifacts to monday-owned delivery CLIs instead of relying on direct Codex chat as the operator surface.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - slack
  - email
---

# Goal-Driven Autonomy Wave 3 Goal Brief

## Objective

Make long-running autonomy hand operator communication to `monday` deterministically:
- `planningops` produces canonical supervisor artifacts
- `monday` consumes those artifacts through repo-owned CLI boundaries
- Slack/email skills become thin wrappers over Monday-owned delivery entrypoints

## Success Outcomes

- `planningops` defines one canonical handoff contract from supervisor artifacts to monday messaging inputs
- `monday` can consume a supervisor status/update payload file without prompt-authored transport logic
- `monday` can consume a supervisor goal-completion payload file without manual envelope reconstruction
- the next goal remains promotable from the active-goal registry without hand-editing backlog issues

## Non-Goals

- no real Slack or mail-provider credential wiring in this wave
- no vendor HTTP transport implementation inside `platform-planningops`
- no goal-intake-from-Slack workflow yet
- no new MCP server surface unless the CLI handoff proves insufficient first

## Operator Channels

- primary operator channel: `slack_skill_cli`
- terminal notification channel: `email_cli`

## Completion References

- `planningops/contracts/goal-completion-contract.md`
- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/active-goal-registry-contract.md`

## Execution Contract

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave3.execution-contract.json`
