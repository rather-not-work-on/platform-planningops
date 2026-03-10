---
title: plan: Runtime Mission Wave 23 Supervisor Operator Report Issue Pack
type: plan
date: 2026-03-10
updated: 2026-03-10
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Emits a compact operator-facing supervisor report so overnight automation can surface cooldown, retry, and attention guidance without parsing the full run summary.
tags:
  - uap
  - implementation
  - runtime
  - control-plane
  - supervisor
  - operations
  - reporting
---

# Runtime Mission Wave 23 Supervisor Operator Report Issue Pack

## Preconditions

This issue pack is valid because:
- wave22 added structured rate-limit guidance to runner and supervisor outputs
- overnight automation still has to parse the full supervisor summary to extract the next operator action
- the next hardening step is a compact sidecar report, not a new retry mechanism

## Goal

Emit a deterministic operator report for each supervisor run:
- `autonomous_supervisor_loop.py` must derive a compact operator report from the final run summary
- the report must distinguish `converged`, `converged_with_snapshot_fallback`, `github_rate_limited`, and review-required stops
- the report must be written next to run summaries so automations can attach it directly

The rule for this wave is strict:
- keep the report machine-readable and compact
- do not introduce new background retries or wait loops
- do not duplicate the full cycle log in the report
- keep execution inside planningops

## Wave 23 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AO10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/autonomous_supervisor_loop.py` |
| `AO20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/autonomous-supervisor-loop-contract.md` |
| `AO30` | 30 | `rather-not-work-on/platform-planningops` | `review_gate` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave23-review.json` |

## Decomposition Rules

- `AO10` derives and writes the operator report sidecar from final supervisor state.
- `AO20` updates the supervisor contract so report outputs are part of the stable interface.
- `AO30` records the decision matrix for normal convergence, snapshot-backed convergence, and live API block.

## Dependencies

- `AO20` depends on `AO10`
- `AO30` depends on `AO10`, `AO20`

## Explicit Non-Goals

- no execution-repo changes
- no new GitHub project mutation logic
- no automatic backoff scheduler
