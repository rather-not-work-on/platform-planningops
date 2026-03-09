---
title: plan: Runtime Mission Wave 15 Issue-Driven Smoke Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that bridges a planningops GitHub issue into monday local runtime smoke without collapsing execution ownership into planningops.
tags:
  - uap
  - implementation
  - runtime
  - mission
  - issue-driven
  - backlog
---

# Runtime Mission Wave 15 Issue-Driven Smoke Issue Pack

## Preconditions

This issue pack is valid because:
- runtime infra wave13 and wave14 are merged and their review artifacts recorded `verdict=pass`
- monday already owns a local runtime smoke entrypoint that exercises the profiled provider and observability path
- planningops already owns federated orchestration runners but still lacks a deterministic bridge from a real planningops issue into a monday mission run

## Goal

Create the first deterministic issue-driven mission smoke path:
- monday accepts mission input from a file instead of only flattened CLI flags
- planningops converts a GitHub issue into mission input and invokes monday local runtime smoke
- planningops records review evidence that ownership remains clean: issue extraction/orchestration in planningops, mission execution in monday

The rule for this wave is strict:
- planningops owns issue retrieval, issue-to-mission normalization, and aggregate evidence
- monday owns mission execution and local runtime smoke behavior
- provider and observability repos remain untouched in this wave and continue to be exercised only through monday's existing profiled adapters

## Wave 15 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AG10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/run_local_runtime_smoke.py` |
| `AG20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/federation/run_issue_driven_mission_smoke.py` |
| `AG30` | 30 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/scripts/test_issue_driven_mission_smoke_contract.sh` |
| `AG40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/runtime-mission-wave15-review.json` |

## Decomposition Rules

- `AG10` adds monday-owned mission file input support so planningops can pass normalized mission context without inventing positional CLI glue.
- `AG20` adds a planningops-owned runner that fetches a planningops issue, derives deterministic mission input, shells into monday's smoke entrypoint, and records the linked evidence.
- `AG30` adds a contract test for `AG20` using a fixture issue document so issue normalization and report shape do not drift.
- `AG40` validates that the resulting path is issue-driven, deterministic, and still respects repo boundaries.

## Dependencies

- `AG20` depends on `AG10`
- `AG30` depends on `AG20`
- `AG40` depends on `AG10`, `AG20`, `AG30`

## Explicit Non-Goals

- no live queue or scheduler selection yet
- no direct provider or observability repo changes
- no shared contract expansion unless the review artifact shows a concrete gap
- no automatic mutation of issue state from the smoke runner
