---
title: plan: Runtime Behavior Wave 6 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that turns the wave5 typed interfaces into repo-owned behavior baselines without requiring live LiteLLM or Langfuse deployment.
tags:
  - uap
  - implementation
  - runtime
  - behavior
  - backlog
---

# Runtime Behavior Wave 6 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `W10` to `W40` are merged and their outputs exist
- `planningops/artifacts/validation/runtime-behavior-wave5-interface-review.json` recorded `verdict=pass`
- the next uncertainty is no longer interface ownership but repo-local behavior composition

## Goal

Replace the remaining behavior stubs with deterministic repo-owned baseline logic.

The rule for this wave is strict:
- keep external infra mocked or local-only
- deepen runtime behavior inside the owning repo instead of moving policy upstream
- keep shared contracts reactive unless a new cross-repo payload is proven necessary

## Wave 6 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `X10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/orchestrator/src/run_lifecycle.ts` |
| `X20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-runtime/src/provider_registry.ts` |
| `X30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `services/telemetry-gateway/src/dispatch_mode.ts` |
| `X40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-behavior-wave6-review.json` |

## Decomposition Rules

- `X10` adds a monday-owned run lifecycle mapper so orchestrator status is derived from executor outcomes through explicit helpers.
- `X20` adds a provider-owned registry/runtime selection baseline so provider runtime routes through registered drivers instead of ad hoc checks.
- `X30` adds an observability-owned dispatch-mode baseline so ingest can choose buffer, sink, or fanout behavior through repo-local policy.
- `X40` validates that the three execution repos deepened behavior without reopening a shared-contract gap or violating repo boundaries.

## Dependencies

- `X40` depends on `X10`, `X20`, `X30`

## Explicit Non-Goals

- no live LiteLLM or Langfuse runtime deployment yet
- no queue scheduler or long-running worker orchestration yet
- no new shared schema unless `X40` records explicit cross-repo gap evidence
