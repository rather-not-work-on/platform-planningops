---
title: plan: Goal-Driven Autonomy Wave 4 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the fourth goal-driven autonomy wave so PlanningOps freezes the scheduler and queue control-plane boundary and monday becomes the planned owner of durable local-first scheduling runtime.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
  - backlog
---

# Goal-Driven Autonomy Wave 4 Issue Pack

## Goal

Move from operator handoff alone to a queue-aware runtime foundation:
- `planningops policy -> monday-owned scheduler/queue runtime`

This wave freezes the contract and runtime shape required to replace Codex recurring automation with monday-owned scheduling later.

## Wave 4 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `D10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md` |
| `D20` | 20 | `rather-not-work-on/platform-contracts` | `contracts` | `ready_contract` | `schemas/runtime-scheduler-queue-item.schema.json` |
| `D30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_contract` | `docs/adr/adr-0002-local-first-scheduler-queue-runtime.md` |
| `D40` | 40 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/run_scheduled_queue_cycle.py` |
| `D50` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave4-review.json` |

## Decomposition Rules

- `D10` freezes the scheduler/queue policy boundary so planningops continues to own goals, queue admission, retries, escalation, and completion policy without becoming a daemon host.
- `D20` introduces only the shared queue schemas that genuinely cross repo boundaries; repo-local runtime details stay in monday.
- `D30` documents the monday local-first runtime shape, storage decision, package responsibility, and migration constraints before runtime implementation expands.
- `D40` adds the first monday-owned scheduled queue cycle CLI baseline that can later replace Codex recurring automation as the execution entrypoint.
- `D50` verifies the wave keeps monday as execution-plane owner while planningops remains the control tower.

## Dependencies

- `D20` depends on `D10`
- `D30` depends on `D10`, `D20`
- `D40` depends on `D20`, `D30`
- `D50` depends on `D10`, `D20`, `D30`, `D40`

## Non-Goals

- no distributed queue backend in this wave
- no Slack transport wiring changes outside monday-owned adapters
- no scheduler runtime implementation inside `platform-planningops`
- no provider or observability orchestration ownership change
