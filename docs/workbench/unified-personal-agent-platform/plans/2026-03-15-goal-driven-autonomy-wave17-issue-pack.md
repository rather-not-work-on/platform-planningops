---
title: plan: Goal-Driven Autonomy Wave 17 Issue Pack
type: plan
date: 2026-03-15
updated: 2026-03-15
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the seventeenth goal-driven autonomy wave so monday-owned dispatch packets become executable local dispatch cycle inputs that a future Slack skill or terminal notifier adapter can consume without planningops taking ownership of runtime dispatch mutation.
tags:
  - uap
  - autonomy
  - planningops
  - monday
  - operator
  - dispatch
  - backlog
---

# Goal-Driven Autonomy Wave 17 Issue Pack

## Goal

Operationalize monday local dispatch after wave16 handoff:
- `monday dispatch packet -> monday execution packet -> monday local dispatch cycle`
- monday owns dispatch packet selection, execution packet export, local dispatch receipt, and packet acknowledgement
- planningops keeps contract/review ownership but does not own runtime dispatch loops or concrete transport execution

## Wave 17 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `Q10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `planningops/contracts/local-dispatch-cycle-handoff-contract.md` |
| `Q20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/export_local_dispatch_execution_packet.py` |
| `Q30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `monday/scripts/run_local_dispatch_cycle.py` |
| `Q40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-driven-autonomy-wave17-review.json` |

## Decomposition Rules

- `Q10` freezes only the dispatch execution handoff boundary and receipt evidence model; it does not define real Slack or SMTP provider calls.
- `Q20` exports one deterministic execution packet from one ready monday dispatch packet so future skill or notifier surfaces can consume a stable runtime-owned input.
- `Q30` runs one local dispatch cycle that records a local dispatch receipt and acknowledgement for the selected packet without planningops mutating runtime artifacts.
- `Q40` verifies planningops still does not own monday dispatch selection, execution, or receipt mutation and that monday owns the runtime dispatch loop.

## Dependencies

- `Q20` depends on `Q10`
- `Q30` depends on `Q10`, `Q20`
- `Q40` depends on `Q10`, `Q20`, `Q30`

## Non-Goals

- no real Slack API calls
- no SMTP or third-party email provider calls
- no planningops-owned dispatch queue or daemon
- no remote scheduler service outside monday
