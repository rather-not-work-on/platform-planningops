---
title: plan: Goal-Driven Autonomy Wave 15 Issue Pack
type: plan
date: 2026-03-15
updated: 2026-03-15
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the fifteenth goal-driven autonomy wave so monday-owned local outbox delivery replaces blocked apply-mode transport placeholders and planningops can complete local apply paths without explicit transport arguments.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - operator
  - outbox
  - backlog
---

# Goal-Driven Autonomy Wave 15 Issue Pack

## Goal

Move from caller-supplied transport arguments to monday-owned local target resolution:
- `planningops reflection or supervisor handoff -> monday local target resolver -> monday local outbox delivery`
- planningops stops supplying concrete `delivery-target` values for the primary local apply path
- monday owns local delivery target profiles, outbox persistence, and idempotent operator-notification dispatch

## Wave 15 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `O10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/local-operator-target-resolution-contract.md` |
| `O20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/operator_channel_local_outbox.py` |
| `O30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/federation/run_reflection_delivery_cycle.py` |
| `O40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `O50` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave15-review.json` |

## Decomposition Rules

- `O10` freezes only the ownership and evidence boundary for monday-owned local target resolution and outbox delivery; it does not define real Slack or SMTP integration.
- `O20` adds the monday-owned local outbox module, repo-local target profiles, and the minimum CLI changes needed so operator and goal-completion delivery succeed in `apply` mode for the local path.
- `O30` updates planningops reflection-delivery orchestration to rely on monday local target resolution for the primary local apply path instead of requiring explicit transport parameters.
- `O40` updates planningops supervisor completion handling to hand off goal-completion delivery through monday local target resolution and persist deterministic evidence.
- `O50` verifies planningops still does not own concrete recipients or transport execution and that monday owns local outbox delivery semantics.

## Dependencies

- `O20` depends on `O10`
- `O30` depends on `O10`, `O20`
- `O40` depends on `O10`, `O20`
- `O50` depends on `O10`, `O20`, `O30`, `O40`

## Non-Goals

- no real Slack token flow
- no SMTP delivery implementation
- no planningops-owned recipient config
- no remote queue backend changes
