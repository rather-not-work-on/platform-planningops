---
title: plan: Goal-Driven Autonomy Wave 6 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the sixth goal-driven autonomy wave so monday grows from a durable queue store into a queue runtime that can finalize leased work into completed, retry_wait, or dead_letter states with deterministic evidence.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
  - worker
  - retry
  - dead-letter
  - backlog
---

# Goal-Driven Autonomy Wave 6 Issue Pack

## Goal

Move from a durable queue store to a deterministic worker completion lifecycle:
- `planningops policy -> monday queue outcome transitions`

This wave keeps the control-plane boundary from wave5 intact while adding the first durable completion, retry, and dead-letter semantics for leased work.

## Wave 6 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `F10` | 10 | `rather-not-work-on/platform-contracts` | `contracts` | `ready_contract` | `schemas/runtime-queue-worker-outcome.schema.json` |
| `F20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/record_queue_worker_outcome.py` |
| `F30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/test_record_queue_worker_outcome.sh` |
| `F40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave6-review.json` |

## Decomposition Rules

- `F10` introduces only the worker outcome schema that planningops must read when reflecting over monday queue completion results.
- `F20` adds a monday-owned CLI baseline that records `completed`, `retry_wait`, and `dead_letter` transitions for leased queue items.
- `F30` proves the worker outcome lifecycle through deterministic local regression coverage and monday local CI wiring.
- `F40` verifies the worker outcome lifecycle keeps planningops as control tower only and monday as runtime owner.

## Dependencies

- `F20` depends on `F10`
- `F30` depends on `F10`, `F20`
- `F40` depends on `F10`, `F20`, `F30`

## Non-Goals

- no provider execution adapter in this wave
- no distributed scheduler daemon in this wave
- no direct Slack-triggered queue mutation in this wave
- no planningops-owned queue state transition helper
