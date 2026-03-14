---
title: plan: Goal-Driven Autonomy Wave 13 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the thirteenth goal-driven autonomy wave so monday can resolve the current scheduled worker outcome from runtime-owned state and planningops can consume the resulting handoff without a bridge input.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
  - worker-outcome
  - handoff
  - backlog
---

# Goal-Driven Autonomy Wave 13 Issue Pack

## Goal

Move from bridge-input handoff emission to scheduler-native worker-outcome selection:
- `monday scheduled queue cycle -> monday worker-outcome selector -> scheduled worker-outcome handoff -> planningops scheduled reflection-delivery cycle`
- monday resolves the current scheduled worker outcome from runtime-owned state
- planningops no longer forwards `--worker-outcome-json` for the primary path

## Wave 13 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `M10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/scheduler-native-worker-outcome-selection-contract.md` |
| `M20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/select_scheduled_worker_outcome.py` |
| `M30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py` |
| `M40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave13-review.json` |

## Decomposition Rules

- `M10` freezes only the scheduler-native worker-outcome selection boundary; it does not redesign worker-outcome schemas or queue persistence.
- `M20` adds a monday-owned selector that resolves one worker outcome for the current scheduled run and feeds the existing handoff contract.
- `M30` removes the primary-path bridge input from planningops scheduled orchestration and consumes only monday-emitted handoff evidence.
- `M40` verifies the control-plane still does not own queue/runtime mutation and that monday still owns worker-outcome selection.

## Dependencies

- `M20` depends on `M10`
- `M30` depends on `M10`, `M20`
- `M40` depends on `M10`, `M20`, `M30`

## Non-Goals

- no new queue storage backend
- no scheduler daemon
- no planningops-owned runtime selection cache
- no new transport or provider logic
