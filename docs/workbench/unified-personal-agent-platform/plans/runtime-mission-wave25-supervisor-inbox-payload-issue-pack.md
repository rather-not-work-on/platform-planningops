---
title: plan: Runtime Mission Wave 25 Supervisor Inbox Payload Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Emits a deterministic inbox payload JSON from supervisor summaries so recurring automation can open inbox items without reparsing markdown or cycle logs.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - supervisor
  - inbox
  - automation
---

# Runtime Mission Wave 25 Supervisor Inbox Payload Issue Pack

## Preconditions

This issue pack is valid because:
- wave24 emits compact markdown summaries for supervisor runs
- recurring automation still needs a machine-ready inbox payload instead of scraping markdown
- the next step is a deterministic payload projection, not new control logic

## Goal

Emit an inbox-ready JSON payload for each supervisor run:
- `autonomous_supervisor_loop.py` must derive a compact inbox payload from the operator report and summary paths
- the payload must expose title, action, wait, and attachment paths for automation handoff
- the payload must be written alongside existing sidecars for both run-specific and last-run paths

The rule for this wave is strict:
- keep payload deterministic and compact
- do not add network calls or actual inbox publishing
- do not change supervisor stop logic
- keep execution inside planningops

## Wave 25 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AQ10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `AQ20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/autonomous-supervisor-loop-contract.md` |
| `AQ30` | 30 | `rather-not-work-on/platform-planningops` | `review_gate` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave25-review.json` |

## Decomposition Rules

- `AQ10` derives and writes inbox payload JSON sidecars from the operator report.
- `AQ20` extends the supervisor contract to include inbox payload outputs.
- `AQ30` records how statuses and attachments are projected for automation handoff.

## Dependencies

- `AQ20` depends on `AQ10`
- `AQ30` depends on `AQ10`, `AQ20`

## Explicit Non-Goals

- no execution-repo changes
- no actual inbox API publishing
- no scheduler or retry policy changes
