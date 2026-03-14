---
title: plan: Goal-Driven Autonomy Wave 6 Goal Brief
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the worker completion lifecycle wave so monday advances from a durable queue store into a queue runtime that can finalize leased work as completed, retry_wait, or dead_letter with deterministic evidence.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
  - worker
  - retry
  - dead-letter
---

# Goal-Driven Autonomy Wave 6 Goal Brief

## Objective

Turn the durable queue runtime from wave5 into the first repo-owned worker completion lifecycle:
- `platform-contracts` freezes only the worker outcome schema that genuinely crosses monday and planningops
- `monday` records leased work as `completed`, `retry_wait`, or `dead_letter` in the SQLite queue store
- `planningops` continues to reflect over outcome evidence without becoming a runtime mutation host

## Success Outcomes

- monday has a deterministic worker outcome entrypoint for leased queue items
- queue items can transition from `leased` to `completed`, `retry_wait`, or `dead_letter` with explicit retry budget and evidence fields
- shared worker outcome vocabulary is frozen in `platform-contracts` only where planningops must reason over the resulting evidence
- planningops can review the worker completion lifecycle without taking ownership of queue mutation logic

## Non-Goals

- no provider execution dispatch in this wave
- no distributed queue coordinator in this wave
- no Slack-triggered queue mutation in this wave
- no observability or provider topology redesign unrelated to queue completion outcomes

## Operator Channels

- primary operator channel: `slack_skill_cli`
- terminal notification channel: `email_cli`

## Completion References

- `planningops/contracts/goal-completion-contract.md`
- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/active-goal-registry-contract.md`

## Roadmap Reference

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-autonomous-scheduler-queue-control-plane-plan.md`

## Execution Contract

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave6.execution-contract.json`
