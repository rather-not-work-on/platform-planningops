---
title: plan: Runtime Mission Wave 22 Rate-Limit Guidance Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds operator-facing cooldown and retry guidance when GitHub API pressure forces snapshot fallback or blocks live apply runs.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - github
  - rate-limit
  - operations
---

# Runtime Mission Wave 22 Rate-Limit Guidance Issue Pack

## Preconditions

This issue pack is valid because:
- wave20 added runner snapshot fallback and wave21 propagated degraded-mode reporting into supervisor cycle summaries
- operators can now see that fallback happened, but they still do not get explicit next-step guidance for cooldown, retry, or allowed execution modes
- the next hardening step is operational clarity, not more fallback behavior

## Goal

Make rate-limit handling actionable:
- `issue_loop_runner.py` must emit structured cooldown/retry guidance whenever project item loading falls back to snapshot or fails live due to rate limiting
- `autonomous_supervisor_loop.py` must surface that guidance at cycle and summary level
- review evidence must confirm the distinction between `snapshot tolerated in dry-run` and `live apply blocked`

The rule for this wave is strict:
- keep guidance deterministic and local
- do not add automatic sleep/retry loops
- do not silently downgrade apply mode into snapshot execution
- keep wording concise enough for machine and human consumption

## Wave 22 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AN10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/core/loop/runner.py` |
| `AN20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `AN30` | 30 | `rather-not-work-on/platform-planningops` | `review_gate` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave22-review.json` |

## Decomposition Rules

- `AN10` adds rate-limit guidance objects to runner output and failure paths.
- `AN20` propagates runner guidance into supervisor cycle and stop summaries.
- `AN30` records recommended cooldown actions for both snapshot-backed dry-run and blocked apply mode.

## Dependencies

- `AN20` depends on `AN10`
- `AN30` depends on `AN10`, `AN20`

## Explicit Non-Goals

- no execution-repo changes
- no GitHub issue projection changes
- no background retry scheduler
