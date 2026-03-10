---
title: plan: Runtime Mission Wave 21 Supervisor Rate-Limit Reporting Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Propagates rate-limit fallback signals from issue-loop intake into supervisor commands, per-cycle reports, and convergence stop reasons.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - supervisor
  - rate-limit
  - backlog
---

# Runtime Mission Wave 21 Supervisor Rate-Limit Reporting Issue Pack

## Preconditions

This issue pack is valid because:
- wave20 hardened `issue_loop_runner.py` with snapshot fallback and issue-doc caching
- the supervisor currently treats the runner as an opaque black box and does not record whether a cycle used live or snapshot project data
- overnight automation needs explicit degraded-mode evidence, otherwise operators cannot tell a true live convergence from a snapshot-backed one

## Goal

Make supervisor reports rate-limit aware:
- `autonomous_supervisor_loop.py` must pass project-item snapshot controls through to `issue_loop_runner.py`
- supervisor cycle reports must surface `project_items_source`, snapshot fallback usage, and any runner-reported rate-limit error
- convergence under snapshot fallback must remain explicit in the final stop reason

The rule for this wave is strict:
- keep the change inside planningops
- do not change execution-repo behavior
- do not introduce retry sleeps or background wait loops
- preserve pass/fail semantics while making degraded convergence visible

## Wave 21 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AM10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `AM20` | 20 | `rather-not-work-on/platform-planningops` | `review_gate` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave21-review.json` |

## Decomposition Rules

- `AM10` threads snapshot controls into the runner command and records rate-limit fallback signals in cycle reports.
- `AM20` records whether convergence stayed fully live or used snapshot fallback, and what stop reason was emitted.

## Dependencies

- `AM20` depends on `AM10`

## Explicit Non-Goals

- no new GitHub issue projection
- no backoff/retry timing policy
- no apply-mode fallback beyond what wave20 already defined
