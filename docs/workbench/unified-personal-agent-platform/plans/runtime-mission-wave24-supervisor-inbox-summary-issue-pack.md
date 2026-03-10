---
title: plan: Runtime Mission Wave 24 Supervisor Inbox Summary Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Projects the supervisor operator report into a compact markdown summary artifact suitable for inbox delivery and quick human review.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - supervisor
  - inbox
  - reporting
---

# Runtime Mission Wave 24 Supervisor Inbox Summary Issue Pack

## Preconditions

This issue pack is valid because:
- wave23 emits structured `operator-report.json` sidecars for supervisor runs
- recurring automation still benefits from a concise markdown artifact that can be attached or pasted without parsing JSON
- the next step is formatting and projection, not new supervisor decisions

## Goal

Emit an inbox-ready markdown summary per supervisor run:
- `autonomous_supervisor_loop.py` must render a compact markdown summary from the operator report
- the summary must highlight status, action, cooldown, and evidence paths
- the summary must be written alongside the JSON sidecar for both run-specific and last-run paths

The rule for this wave is strict:
- keep markdown deterministic and compact
- do not duplicate full cycle logs
- do not change stop logic or retry logic
- keep execution inside planningops

## Wave 24 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AP10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `AP20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/autonomous-supervisor-loop-contract.md` |
| `AP30` | 30 | `rather-not-work-on/platform-planningops` | `review_gate` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave24-review.json` |

## Decomposition Rules

- `AP10` renders and persists markdown summaries from the operator report.
- `AP20` extends the supervisor contract to include markdown summary outputs.
- `AP30` records how degraded and blocked runs are represented for inbox consumption.

## Dependencies

- `AP20` depends on `AP10`
- `AP30` depends on `AP10`, `AP20`

## Explicit Non-Goals

- no execution-repo changes
- no new automation scheduler behavior
- no additional retry/backoff logic
