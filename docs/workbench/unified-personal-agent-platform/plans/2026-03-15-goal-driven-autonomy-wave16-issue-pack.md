---
title: plan: Goal-Driven Autonomy Wave 16 Issue Pack
type: plan
date: 2026-03-15
updated: 2026-03-15
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the sixteenth goal-driven autonomy wave so monday-owned local outbox artifacts turn into dispatch packets and acknowledgements that future Slack skill and terminal notifier surfaces can consume without planningops taking ownership of transport runtime state.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - operator
  - outbox
  - dispatch
  - backlog
---

# Goal-Driven Autonomy Wave 16 Issue Pack

## Goal

Move from repo-local outbox files to monday-owned dispatch handoff artifacts:
- `monday local outbox -> monday dispatch packet -> future Slack skill or terminal notifier`
- monday owns outbox selection, dispatch packet emission, and acknowledgement checkpoints
- planningops keeps contract/review ownership but does not poll or mutate runtime-owned transport artifacts on the primary path

## Wave 16 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `P10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/local-outbox-dispatch-handoff-contract.md` |
| `P20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/export_local_outbox_dispatch_packet.py` |
| `P30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/ack_local_outbox_dispatch.py` |
| `P40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave16-review.json` |

## Decomposition Rules

- `P10` freezes only the outbox dispatch handoff boundary and evidence model; it does not define real Slack or SMTP execution.
- `P20` exports one deterministic dispatch packet from one monday-owned local outbox message so downstream skill or notifier surfaces have a stable handoff format.
- `P30` records dispatch acknowledgement and checkpoint evidence inside monday so transport-facing mutation stays runtime-owned.
- `P40` verifies planningops still does not own monday outbox mutation or transport execution and that monday owns dispatch packet and acknowledgement semantics.

## Dependencies

- `P20` depends on `P10`
- `P30` depends on `P10`, `P20`
- `P40` depends on `P10`, `P20`, `P30`

## Non-Goals

- no real Slack API token flow
- no SMTP provider integration
- no planningops-owned dispatch queue
- no remote scheduler service
