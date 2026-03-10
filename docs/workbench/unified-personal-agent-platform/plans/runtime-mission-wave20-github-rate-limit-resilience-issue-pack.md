---
title: plan: Runtime Mission Wave 20 GitHub Rate-Limit Resilience Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens issue-loop intake against GitHub API rate limits by caching issue docs within a run and allowing project-item snapshot fallback for dry-run style validation.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - github
  - rate-limit
  - backlog
---

# Runtime Mission Wave 20 GitHub Rate-Limit Resilience Issue Pack

## Preconditions

This issue pack is valid because:
- wave19 removed the slow subprocess reconcile path, but repeated `gh project item-list` and `gh issue view` calls can still hit the GitHub GraphQL/API limit during heavy local pilot cycles
- once the rate limit is exhausted, post-change live verification and automated overnight loops lose momentum even when local contracts still pass
- the next control-plane hardening step is graceful degradation, not new execution behavior

## Goal

Make issue-loop intake resilient under GitHub API pressure:
- `issue_loop_runner.py` must cache issue documents within a single run so reconcile/selection/dependency checks do not refetch the same issue repeatedly
- successful `project item-list` calls must refresh a local snapshot, and dry-run style loops must be able to fall back to that snapshot when the live API is rate-limited
- planningops must record a compact review artifact that distinguishes `live` vs `snapshot` intake sources and captures the remaining operational risk

The rule for this wave is strict:
- keep the change inside planningops
- do not hide rate-limit failures during mutating apply mode
- preserve explicit output about whether live or snapshot data was used
- do not create a second backlog source; this is runner resilience only

## Wave 20 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AL10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/core/loop/runner.py` |
| `AL20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave20-review.json` |

## Decomposition Rules

- `AL10` adds per-run issue-doc caching plus project-item snapshot fallback controls for dry-run validation paths.
- `AL20` records whether rate-limit fallback remains explicit and whether mutating apply mode still fails fast when live GitHub data is unavailable.

## Dependencies

- `AL20` depends on `AL10`

## Explicit Non-Goals

- no execution-repo changes
- no new GitHub issue projection in this wave
- no automatic waiting/retry sleep loops around GitHub rate limits
