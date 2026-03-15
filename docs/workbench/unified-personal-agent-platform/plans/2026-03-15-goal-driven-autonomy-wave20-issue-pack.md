---
title: plan: Goal-Driven Autonomy Wave 20 Issue Pack
type: plan
date: 2026-03-15
updated: 2026-03-15
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the twentieth goal-driven autonomy wave so monday scheduled queue execution becomes the primary local runtime path for operator and goal-completion delivery cycles.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - operator
  - scheduler
  - queue
  - backlog
---

# Goal-Driven Autonomy Wave 20 Issue Pack

## Goal

Make monday scheduled queue execution the primary recurring delivery path:
- `delivery work item -> monday scheduled queue cycle -> monday local delivery cycle entrypoint`
- operator-message and goal-completion delivery become queue-native runtime work
- planningops keeps contract/review ownership and does not own queue mutation or concrete delivery execution

## Wave 20 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `T10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/scheduled-delivery-cycle-handoff-contract.md` |
| `T20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/scheduler_delivery_cycle_work_items.py` |
| `T30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/run_scheduled_queue_cycle.py` |
| `T40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave20-review.json` |

## Decomposition Rules

- `T10` freezes only the control-plane boundary for queue-native delivery-cycle handoff; it does not redesign Slack or email transport contracts.
- `T20` introduces deterministic scheduler work-item shapes for operator-message and goal-completion delivery using monday-owned runtime evidence.
- `T30` upgrades monday scheduled queue execution so one delivery work item can invoke the appropriate local delivery-cycle entrypoint and persist queue-owned evidence.
- `T40` verifies planningops no longer assumes direct one-shot delivery entrypoint invocation on the recurring autonomy path.

## Dependencies

- `T20` depends on `T10`
- `T30` depends on `T10`, `T20`
- `T40` depends on `T10`, `T20`, `T30`

## Non-Goals

- no real Slack API delivery
- no SMTP or third-party email provider integration
- no planningops-owned queue worker
- no external scheduler backend
