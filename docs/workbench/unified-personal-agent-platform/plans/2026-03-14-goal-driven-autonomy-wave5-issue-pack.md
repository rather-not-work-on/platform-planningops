---
title: plan: Goal-Driven Autonomy Wave 5 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the fifth goal-driven autonomy wave so monday grows from a scheduler smoke baseline into a durable local queue runtime with SQLite-backed state and lease-aware execution.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
  - backlog
  - sqlite
---

# Goal-Driven Autonomy Wave 5 Issue Pack

## Goal

Move from a historical queue-cycle smoke to a durable local runtime:
- `planningops policy -> monday SQLite-backed queue runtime`

This wave keeps the control-plane boundary from wave4 intact while adding the first durable queue state and lease lifecycle semantics in monday.

## Wave 5 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `E10` | 10 | `rather-not-work-on/platform-contracts` | `contracts` | `ready_contract` | `schemas/runtime-scheduler-lease-lifecycle.schema.json` |
| `E20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/runtime_queue_store.py` |
| `E30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/run_scheduled_queue_cycle.py` |
| `E40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave5-review.json` |

## Decomposition Rules

- `E10` introduces only the shared lease lifecycle and dead-letter vocabulary that must remain stable across planningops and monday.
- `E20` adds a monday-owned SQLite queue store baseline for local-first durability and explicit runtime inspection.
- `E30` upgrades the scheduled queue cycle so it uses the queue store, records lease/heartbeat transitions, and preserves deterministic evidence output.
- `E40` verifies the durable queue runtime still leaves planningops as control tower only and keeps monday as execution-plane owner.

## Dependencies

- `E20` depends on `E10`
- `E30` depends on `E10`, `E20`
- `E40` depends on `E10`, `E20`, `E30`

## Non-Goals

- no distributed lease coordinator in this wave
- no cloud queue backend in this wave
- no direct Slack-triggered queue mutation in this wave
- no scheduler daemon hosted inside `platform-planningops`
