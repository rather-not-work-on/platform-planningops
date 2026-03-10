---
title: plan: Runtime Mission Wave 19 Auto Closed-Item Reconcile Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Makes the live issue loop self-heal closed-card project drift before selection so stale Done work stops polluting ready-implementation intake.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - reconcile
  - backlog
---

# Runtime Mission Wave 19 Auto Closed-Item Reconcile Issue Pack

## Preconditions

This issue pack is valid because:
- wave18 proved targeted reconcile reduces live intake noise, but the effect is temporary
- after wave18 merge, newly closed cards still remain executable-looking in the project until another manual reconcile run happens
- the next control-plane bottleneck is not projection correctness anymore, but keeping project state converged automatically before each live intake attempt

## Goal

Make closed-card drift converge automatically inside the live loop:
- `issue_loop_runner.py` must support a pre-selection reconcile phase that reuses `sync_project_fields_after_issue_create.py`
- automatic reconcile must be mode-aware so dry-run stays non-destructive while apply mode can converge project state before selection
- planningops must record compact evidence showing the pre-selection reconcile reduced closed-card intake noise without introducing a second competing sync path

The rule for this wave is strict:
- keep the fix inside planningops
- reuse the existing project-field sync contract and CLI, not a forked reconcile implementation
- make the behavior explicit in runner arguments and selection trace
- keep execution-repo behavior untouched

## Wave 19 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AK10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/core/loop/runner.py` |
| `AK20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/artifacts/validation/runtime-mission-wave19-auto-reconcile-report.json` |
| `AK30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave19-review.json` |

## Decomposition Rules

- `AK10` adds a runner-level pre-selection reconcile mode with explicit `off`, `check`, `apply`, and `auto` behavior.
- `AK20` adds contract coverage and a live report showing pre-selection reconcile converges closed planningops cards before candidate selection.
- `AK30` records whether live issue-loop selection stays deterministic after the automatic reconcile pass and what follow-up bottleneck remains.

## Dependencies

- `AK20` depends on `AK10`
- `AK30` depends on `AK10`, `AK20`

## Explicit Non-Goals

- no execution-repo changes
- no new GitHub workflow scheduler yet
- no deletion of historical project items
- no new backlog projection behavior in this wave
