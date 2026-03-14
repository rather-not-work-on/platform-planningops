---
title: plan: Goal-Driven Autonomy Wave 4 Goal Brief
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the scheduler and queue foundation wave so autonomy can graduate from Codex-hosted recurring execution to a monday-owned runtime with durable queue semantics and planningops-owned policy.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
---

# Goal-Driven Autonomy Wave 4 Goal Brief

## Objective

Make autonomy schedulable without depending on Codex recurring automation as the long-term runtime host:
- `planningops` stays the source of truth for goal, schedule, queue, and reflection policy
- `monday` becomes the owner of the scheduler and queue runtime
- shared queue and lifecycle semantics move into explicit contracts before durable implementation expands

## Success Outcomes

- the scheduler/queue control-plane boundary is frozen before runtime growth
- monday has a defined local-first queue runtime shape with lease, retry, and dead-letter semantics
- planningops can hand schedule and queue policy to monday without becoming a runtime daemon
- future operator interaction flows remain queue-aware and goal-aware instead of prompt-local

## Non-Goals

- no distributed scheduler backend in this wave
- no direct Slack goal intake yet
- no cloud-first storage decision in this wave
- no provider or observability runtime redesign unrelated to queue dispatch

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

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave4.execution-contract.json`
