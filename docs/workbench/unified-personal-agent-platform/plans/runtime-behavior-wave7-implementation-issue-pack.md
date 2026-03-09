---
title: plan: Runtime Behavior Wave 7 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that turns the wave6 behavior baselines into repo-owned policy helpers without requiring live infrastructure rollout.
tags:
  - uap
  - implementation
  - runtime
  - behavior
  - policy
  - backlog
---

# Runtime Behavior Wave 7 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `X10` to `X40` are merged and their outputs exist
- `planningops/artifacts/validation/runtime-behavior-wave6-review.json` recorded `verdict=pass`
- the next uncertainty is no longer baseline behavior ownership but repo-local policy selection

## Goal

Promote implicit runtime choices into deterministic repo-owned policy helpers.

The rule for this wave is strict:
- keep external infra mocked or local-only
- move policy logic into the owning repo instead of planningops
- keep contract expansion reactive unless a new shared payload is proven necessary

## Wave 7 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `Y10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/agent-kernel/src/handoff_plan.ts` |
| `Y20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-runtime/src/routing_policy.ts` |
| `Y30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `buffer/replay-worker/src/replay_policy.ts` |
| `Y40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-behavior-wave7-review.json` |

## Decomposition Rules

- `Y10` adds a monday-owned handoff planning helper so agent-kernel can derive deterministic handoff records from task plans instead of leaving the mapping implicit.
- `Y20` adds a provider-owned routing policy helper so provider runtime can resolve the effective provider through explicit policy instead of direct registry lookups only.
- `Y30` adds an observability-owned replay policy helper so replay worker can decide whether to sink or skip batches through repo-local policy rather than fixed unconditional replay.
- `Y40` validates that the three execution repos deepened policy ownership without reopening a shared-contract gap or violating repo boundaries.

## Dependencies

- `Y40` depends on `Y10`, `Y20`, `Y30`

## Explicit Non-Goals

- no live LiteLLM or Langfuse runtime deployment yet
- no queue scheduler or long-running worker orchestration yet
- no new shared schema unless `Y40` records explicit cross-repo gap evidence
