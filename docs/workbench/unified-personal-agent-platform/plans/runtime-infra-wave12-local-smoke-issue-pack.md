---
title: plan: Runtime Infra Wave 12 Local Smoke Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that proves a local-first federated smoke path across monday, provider, observability, and planningops after profile-aware composer wiring lands.
tags:
  - uap
  - implementation
  - runtime
  - smoke
  - federated
  - backlog
---

# Runtime Infra Wave 12 Local Smoke Issue Pack

## Preconditions

This issue pack is valid because:
- runtime infra wave11 is the preceding wave and must land first
- launcher/profile drill scripts already exist in provider and observability repos
- the next missing evidence is an integrated local-first smoke that uses repo-owned composer layers end to end

## Goal

Create a repeatable local-first smoke path that exercises planningops-driven execution through monday, provider, and observability with stable evidence outputs.

The rule for this wave is strict:
- monday owns the local mission smoke entrypoint
- platform-provider-gateway owns the launcher-backed provider smoke path
- platform-observability-gateway owns the launcher-backed ingest smoke path
- planningops owns only the federated smoke review and gate evidence

## Wave 12 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AD10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/run_local_runtime_smoke.py` |
| `AD20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `scripts/litellm_live_smoke.py` |
| `AD30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `scripts/langfuse_live_smoke.py` |
| `AD40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-infra-wave12-review.json` |

## Decomposition Rules

- `AD10` adds a monday-owned local smoke entrypoint that drives one local mission cycle through profiled runtime composition and writes deterministic runtime evidence.
- `AD20` adds a provider-owned live local smoke wrapper that uses the launcher/profile drill boundary and emits stable smoke evidence without changing existing contract schemas.
- `AD30` adds an observability-owned live local smoke wrapper that uses the launcher/replay boundary and emits stable smoke evidence without changing existing contract schemas.
- `AD40` validates that the three smoke entrypoints compose cleanly under planningops and that local-first evidence remains portable to later OCI rehearsals.

## Dependencies

- `AD40` depends on `AD10`, `AD20`, `AD30`

## Explicit Non-Goals

- no Oracle Cloud execution yet
- no autonomous long-running scheduler soak test yet
- no NanoClaw integration yet
- no GitHub issue execution loop attached to the smoke path yet
