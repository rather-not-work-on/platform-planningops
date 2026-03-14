---
title: plan: Goal-Driven Autonomy Wave 7 Goal Brief
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the reflection integration wave so monday worker outcomes become deterministic planningops inputs for replan, continue, and goal-completion decisions.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - reflection
  - queue
  - worker
---

# Goal-Driven Autonomy Wave 7 Goal Brief

## Objective

Turn monday worker outcomes into planningops reflection decisions:
- `monday` exports deterministic worker outcome reflection packets
- `planningops` evaluates those packets into control-plane decisions such as `continue`, `replan_required`, `goal_achieved`, or `operator_notify`
- queue mutation remains in monday while reflection and goal policy remain in planningops

## Success Outcomes

- monday has a repo-owned reflection packet export entrypoint for queue worker outcomes
- planningops has a deterministic evaluator that consumes reflection packets and produces decision artifacts
- dead-letter and retry exhaustion can trigger explicit replan signals without moving runtime mutation into planningops
- goal advancement remains evidence-driven instead of prompt-local

## Non-Goals

- no direct Slack delivery changes in this wave
- no provider execution redesign in this wave
- no external queue backend or daemon migration in this wave
- no planningops-owned runtime queue mutation

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

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave7.execution-contract.json`
