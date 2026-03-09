---
title: plan: Runtime Mission Wave 18 Project Close-State Reconcile Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds a control-plane reconcile path that backfills Project status/workflow_state for issues already closed in GitHub but still left in executable states inside the planningops project.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - reconcile
  - backlog
---

# Runtime Mission Wave 18 Project Close-State Reconcile Issue Pack

## Preconditions

This issue pack is valid because:
- wave17 proved that compile-projected ready items can now be selected by the live issue loop
- the live pilot also exposed historical project drift: many issues are already closed in GitHub but still appear as `Todo`/`ready-implementation` in the project view
- this drift does not block correctness anymore, but it inflates candidate scans and weakens the reliability of the control plane

## Goal

Make project state converge after issue closure:
- `sync_project_fields_after_issue_create.py` must support scanning issues beyond currently-open cards so closed items can be reconciled
- planningops must be able to produce a deterministic drift report and, in apply mode, move closed cards to `done`
- the live issue loop should no longer waste intake attempts on already-closed cards once reconcile has run

The rule for this wave is strict:
- keep the fix inside planningops
- reuse existing project-field sync logic instead of creating a second competing reconcile script
- record one compact review artifact after live reconcile

## Wave 18 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AJ10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/sync_project_fields_after_issue_create.py` |
| `AJ20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/artifacts/validation/project-close-state-reconcile-report.json` |
| `AJ30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave18-review.json` |

## Decomposition Rules

- `AJ10` adds a repo scan mode that can include `open`, `closed`, or `all` issue states without breaking the existing issue-ref and open-only behavior.
- `AJ20` adds contract coverage for close-state reconcile and runs a live planningops reconcile pass that writes a deterministic report.
- `AJ30` records whether the reconcile reduced issue-loop candidate noise and whether project states now converge with GitHub issue states.

## Dependencies

- `AJ20` depends on `AJ10`
- `AJ30` depends on `AJ10`, `AJ20`

## Explicit Non-Goals

- no execution-repo changes
- no new scheduler behavior
- no deletion of historical issues or project items
