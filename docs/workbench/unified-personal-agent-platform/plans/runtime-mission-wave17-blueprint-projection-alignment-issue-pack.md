---
title: plan: Runtime Mission Wave 17 Blueprint Projection Alignment Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Fixes the control-plane gap where compile-projected ready-implementation issues are not immediately executable by the live issue loop because required blueprint refs are absent from issue bodies.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - backlog
---

# Runtime Mission Wave 17 Blueprint Projection Alignment Issue Pack

## Preconditions

This issue pack is valid because:
- wave16 proved that planningops can orchestrate an issue-driven federated stack smoke
- the next step is a live issue-loop pilot that selects a real GitHub Project issue through `issue_loop_runner.py`
- current compile-projected `ready_implementation` issues do not include required blueprint refs, so `issue_loop_runner.py` rejects them before execution

## Goal

Make `ready_implementation` cards executable at creation time:
- `compile_plan_to_backlog.py` must emit blueprint refs into issue bodies for `ready_implementation`
- `verify_plan_projection.py` must fail when a projected `ready_implementation` issue is missing blueprint refs
- the resulting contract must guarantee that a newly projected ready item can be selected by `issue_loop_runner.py` without a manual repair pass

The rule for this wave is strict:
- no execution-repo changes
- no new runtime behavior yet
- no new fallback path that silently repairs projection drift after selection
- fix the control-plane contract at the source of projection

## Wave 17 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AI10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/compile_plan_to_backlog.py` |
| `AI20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/verify_plan_projection.py` |
| `AI30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave17-review.json` |

## Decomposition Rules

- `AI10` injects `interface_contract_refs`, `package_topology_ref`, `dependency_manifest_ref`, and `file_plan_ref` into `ready_implementation` issue bodies during compile/projection using the canonical defaults catalog.
- `AI20` extends projection verification so `ready_implementation` rows fail strict validation when the issue body still lacks a complete blueprint block.
- `AI30` records evidence that compile-created ready items and projection verification are now aligned with live issue-loop intake rules.

## Dependencies

- `AI20` depends on `AI10`
- `AI30` depends on `AI10`, `AI20`

## Explicit Non-Goals

- no live issue-loop pilot yet
- no monday/provider/observability runtime changes
- no post-hoc issue body repair as the primary mechanism for new backlog items
