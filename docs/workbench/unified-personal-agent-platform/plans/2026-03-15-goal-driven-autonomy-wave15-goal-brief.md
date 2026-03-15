---
title: plan: Goal-Driven Autonomy Wave 15 Goal Brief
type: plan
date: 2026-03-15
updated: 2026-03-15
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the fifteenth goal-driven autonomy wave so monday resolves local operator and terminal notification targets from repo-owned config and apply-mode delivery no longer depends on caller-supplied transport arguments.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - scheduler
  - operator
  - outbox
  - email
---

# Goal-Driven Autonomy Wave 15 Goal Brief

## Objective

Make apply-mode operator delivery self-contained for local-first autonomy:
- `planningops reflection or supervisor handoff -> monday local target resolver -> monday local outbox delivery report`
- planningops no longer needs to pass concrete `delivery-target` or `channel-kind` flags for the primary local path
- monday remains the owner of local operator target resolution, idempotent outbox delivery, and terminal notification dispatch

## Success Outcomes

- planningops has a contract that freezes the local operator target resolution boundary without taking ownership of concrete recipients
- monday can resolve deterministic local targets for `slack_skill_cli` and `email_cli` from repo-owned config
- monday operator and goal-completion delivery CLIs can succeed in `apply` mode against a local outbox sink without caller-supplied transport arguments
- planningops scheduled reflection delivery and supervisor goal-completion paths can execute their primary local apply path through monday-owned target resolution
- review evidence proves planningops still does not own concrete delivery targets or transport credentials

## Non-Goals

- no real Slack API integration
- no SMTP or third-party mail provider integration
- no cloud queue backend
- no planningops-owned transport config or recipient registry

## Completion References

- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/goal-completion-contract.md`
- `planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md`

## Roadmap Reference

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-autonomous-scheduler-queue-control-plane-plan.md`

## Execution Contract

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-15-goal-driven-autonomy-wave15.execution-contract.json`
