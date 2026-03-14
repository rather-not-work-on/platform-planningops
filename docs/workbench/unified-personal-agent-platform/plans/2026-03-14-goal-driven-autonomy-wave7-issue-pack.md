---
title: plan: Goal-Driven Autonomy Wave 7 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the seventh goal-driven autonomy wave so monday worker outcomes are exported as deterministic reflection packets and planningops can evaluate them into control-plane decisions.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - reflection
  - queue
  - worker
  - backlog
---

# Goal-Driven Autonomy Wave 7 Issue Pack

## Goal

Move from durable worker outcomes to deterministic reflection decisions:
- `monday worker outcomes -> planningops reflection policy`

This wave keeps monday as execution-plane owner while letting planningops turn worker outcome evidence into explicit replan or completion decisions.

## Wave 7 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `G10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/worker-outcome-reflection-contract.md` |
| `G20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/export_worker_outcome_reflection_packet.py` |
| `G30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/core/goals/evaluate_worker_outcome_reflection.py` |
| `G40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave7-review.json` |

## Decomposition Rules

- `G10` freezes only the planningops-side reflection decision contract and does not add queue mutation helpers.
- `G20` exports monday-owned worker outcome packets in a deterministic format that planningops can read without coupling to queue tables directly.
- `G30` evaluates reflection packets into explicit control-plane decisions while keeping runtime mutation out of planningops.
- `G40` verifies the reflection layer preserves the control-plane/runtime boundary and leaves queue execution in monday.

## Dependencies

- `G20` depends on `G10`
- `G30` depends on `G10`, `G20`
- `G40` depends on `G10`, `G20`, `G30`

## Non-Goals

- no direct Slack/email transport change in this wave
- no provider or observability runtime redesign in this wave
- no planningops-owned queue lease or completion mutation
- no external queue backend migration
