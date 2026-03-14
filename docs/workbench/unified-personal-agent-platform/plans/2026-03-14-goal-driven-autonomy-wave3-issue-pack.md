---
title: plan: Goal-Driven Autonomy Wave 3 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the third goal-driven autonomy wave so PlanningOps can hand off supervisor status and terminal completion events to monday-owned CLI surfaces and keep operator communication outside direct Codex chat.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - operator-channel
  - backlog
---

# Goal-Driven Autonomy Wave 3 Issue Pack

## Goal

Move from goal promotion alone to actual operator-loop handoff:
- `planningops supervisor artifact -> monday CLI input -> channel delivery evidence`

This wave keeps transport policy in contracts and real delivery ownership in `monday`.

## Wave 3 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `C10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/supervisor-operator-handoff-contract.md` |
| `C20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_supervisor_status_update.py` |
| `C30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_supervisor_goal_completion.py` |
| `C40` | 40 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `docs/runbook/planningops-supervisor-handoff.md` |
| `C50` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave3-review.json` |

## Decomposition Rules

- `C10` freezes the canonical shape of `operator-report.json`, `operator-summary.md`, and `inbox-payload.json` as inputs for monday-owned delivery surfaces.
- `C20` adds a monday CLI entrypoint that accepts supervisor status/update payloads and emits delivery evidence.
- `C30` adds a monday CLI entrypoint that accepts supervisor goal-completion payloads and emits delivery evidence without re-authoring the completion envelope in prompts.
- `C40` documents how Slack/email skills call the monday CLI surface and which planningops artifacts they are allowed to consume.
- `C50` verifies wave 3 keeps planningops as control tower only while monday owns the delivery bridge.

## Dependencies

- `C20` depends on `C10`
- `C30` depends on `C10`
- `C40` depends on `C20`, `C30`
- `C50` depends on `C10`, `C20`, `C30`, `C40`

## Non-Goals

- no Slack bot token or mail provider setup in this wave
- no direct channel send from `platform-planningops`
- no user-facing skill prompt authority inside planningops
- no automatic goal intake from Slack threads yet
