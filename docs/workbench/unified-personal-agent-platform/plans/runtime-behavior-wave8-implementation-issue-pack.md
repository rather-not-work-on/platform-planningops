---
title: plan: Runtime Behavior Wave 8 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that turns wave7 policy helpers into deterministic runtime normalization helpers for events, provider outcomes, and sink delivery.
tags:
  - uap
  - implementation
  - runtime
  - behavior
  - normalization
  - backlog
---

# Runtime Behavior Wave 8 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `Y10` to `Y40` are merged and their outputs exist
- `planningops/artifacts/validation/runtime-behavior-wave7-review.json` recorded `verdict=pass`
- the next uncertainty is no longer baseline policy ownership but normalization of repo-local runtime outputs

## Goal

Replace remaining pass-through stubs with deterministic normalization helpers owned by each execution repo.

The rule for this wave is strict:
- keep infrastructure local-only and mocked where necessary
- move normalization logic into the repo that owns the runtime boundary
- keep shared contracts reactive unless a new cross-repo payload is proven necessary

## Wave 8 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `Z10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/executor-ralph-loop/src/event_policy.ts` |
| `Z20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-runtime/src/outcome_policy.ts` |
| `Z30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `sinks/langfuse-sink/src/delivery_policy.ts` |
| `Z40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-behavior-wave8-review.json` |

## Decomposition Rules

- `Z10` adds a monday-owned executor event policy helper so telemetry emission is derived from outcome and handoff context through explicit runtime helpers.
- `Z20` adds a provider-owned outcome policy helper so provider runtime normalizes driver reason codes instead of passing opaque values through unchanged.
- `Z30` adds an observability-owned delivery policy helper so sink delivery normalizes blank or malformed event payloads through repo-local rules.
- `Z40` validates that the three execution repos deepened normalization behavior without reopening a shared-contract gap or violating repo boundaries.

## Dependencies

- `Z40` depends on `Z10`, `Z20`, `Z30`

## Explicit Non-Goals

- no live LiteLLM or Langfuse deployment yet
- no queue scheduler or long-running worker orchestration yet
- no new shared schema unless `Z40` records explicit cross-repo gap evidence
