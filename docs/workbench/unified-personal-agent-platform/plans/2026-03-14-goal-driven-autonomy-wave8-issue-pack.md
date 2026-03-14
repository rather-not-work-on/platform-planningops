---
title: plan: Goal-Driven Autonomy Wave 8 Issue Pack
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the eighth goal-driven autonomy wave so reflection decisions become queue-aware supervisor actions and monday delivery intents instead of isolated evaluation artifacts.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - reflection
  - operator
  - backlog
---

# Goal-Driven Autonomy Wave 8 Issue Pack

## Goal

Move from reflection decisions to deterministic follow-up actions:
- `planningops reflection decision -> control-plane action artifact -> monday operator delivery`

This wave lets evaluation outputs actually drive supervisor behavior and operator communication without pulling queue mutation into planningops.

## Wave 8 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `H10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/reflection-action-handoff-contract.md` |
| `H20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/core/goals/apply_worker_outcome_reflection.py` |
| `H30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_reflection_decision_update.py` |
| `H40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave8-review.json` |

## Decomposition Rules

- `H10` freezes how reflection decisions become action intents, not Slack transport details.
- `H20` converts reflection evaluation outputs into deterministic action artifacts without mutating monday queue state.
- `H30` wraps existing monday operator channel adapters with queue-aware reflection delivery inputs rather than re-implementing transport logic.
- `H40` verifies the new action layer preserves planningops as control-plane owner and monday as delivery/runtime owner.

## Dependencies

- `H20` depends on `H10`
- `H30` depends on `H10`, `H20`
- `H40` depends on `H10`, `H20`, `H30`

## Non-Goals

- no new Slack skill or email provider implementation in this wave
- no queue backend migration
- no provider runtime changes
- no direct supervisor mutation of monday queue tables
