---
title: plan: Runtime Infra Wave 13 Federated Smoke Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that lifts the repo-local wave12 smoke entrypoints into a single planningops-owned federated local stack smoke runner and review gate.
tags:
  - uap
  - implementation
  - runtime
  - smoke
  - federated
  - backlog
---

# Runtime Infra Wave 13 Federated Smoke Issue Pack

## Preconditions

This issue pack is valid because:
- runtime infra wave12 is merged and its review recorded `verdict=pass`
- repo-local smoke entrypoints now exist in monday, provider, and observability
- the next missing capability is a planningops-owned one-command smoke that coordinates the three repos without collapsing ownership

## Goal

Create a planningops-owned federated smoke runner that executes the monday/provider/observability local smoke entrypoints and writes a deterministic aggregate report.

The rule for this wave is strict:
- planningops owns orchestration and aggregate evidence only
- monday/provider/observability continue to own their repo-local smoke entrypoints
- aggregate output must reference repo-owned evidence rather than re-encoding the same logic in planningops

## Wave 13 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AE10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/federation/run_local_runtime_stack_smoke.py` |
| `AE20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/test_local_runtime_stack_smoke_contract.sh` |
| `AE30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-infra-wave13-review.json` |

## Decomposition Rules

- `AE10` adds a planningops-owned federated local smoke runner that shells into repo-owned monday/provider/observability smoke entrypoints and records stable aggregate evidence without rewriting repo-local smoke logic.
- `AE20` adds a contract test for the new federated local smoke runner so orchestration shape and evidence expectations do not drift silently.
- `AE30` validates that planningops now owns only the aggregate smoke path and that repo-local evidence remains the source for each execution domain.

## Dependencies

- `AE20` depends on `AE10`
- `AE30` depends on `AE10`, `AE20`

## Explicit Non-Goals

- no Oracle Cloud rehearsal yet
- no long-running daemon or scheduler soak
- no GitHub issue execution loop wired onto the federated smoke path yet

