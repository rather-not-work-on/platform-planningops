---
title: plan: Runtime Mission Wave 16 Issue-Driven Federated Stack Smoke Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that lifts wave15's issue-driven monday mission smoke into a planningops-owned federated stack smoke that also records provider and observability repo-owned evidence.
tags:
  - uap
  - implementation
  - runtime
  - mission
  - federated
  - backlog
---

# Runtime Mission Wave 16 Issue-Driven Federated Stack Smoke Issue Pack

## Preconditions

This issue pack is valid because:
- runtime mission wave15 is fully merged and its review recorded `verdict=pass`
- planningops now owns a deterministic issue-to-mission runner for monday
- provider and observability repos already expose repo-owned local smoke entrypoints that planningops can orchestrate without reimplementing their logic

## Goal

Create the first issue-driven federated stack smoke:
- planningops accepts a planningops issue as input
- monday is exercised through the wave15 issue-driven mission path
- provider and observability repo-owned live smoke entrypoints run under the same aggregate execution
- planningops records a single deterministic report that links all three evidence paths

The rule for this wave is strict:
- planningops owns issue selection, orchestration, and aggregate evidence only
- monday continues to own mission execution behavior
- provider and observability continue to own their smoke entrypoints and local evidence contracts
- no shared contract expansion unless the review artifact exposes a concrete mismatch

## Wave 16 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AH10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/federation/run_issue_driven_runtime_stack_smoke.py` |
| `AH20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/test_issue_driven_runtime_stack_smoke_contract.sh` |
| `AH30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave16-review.json` |

## Decomposition Rules

- `AH10` adds a planningops-owned federated runner that reuses `run_issue_driven_mission_smoke.py` for monday and the existing provider/observability smoke entrypoints for the other repos, then writes a deterministic aggregate report.
- `AH20` adds a contract test for `AH10` using fixture issue input plus stubbed component smoke scripts so orchestration shape and evidence linking do not drift.
- `AH30` validates that the aggregate smoke path stayed orchestration-only in planningops and did not collapse repo-owned smoke logic into the control plane.

## Dependencies

- `AH20` depends on `AH10`
- `AH30` depends on `AH10`, `AH20`

## Explicit Non-Goals

- no issue mutation or queue scheduling yet
- no direct provider/o11y code changes
- no automatic issue selection from backlog yet
- no live infra assumption beyond existing local smoke contracts
