---
title: plan: Runtime Skeleton Wave 2 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable implementation issue pack for runtime workspace scaffolding after wave 1 blueprint and readiness gates passed.
tags:
  - uap
  - implementation
  - runtime-skeleton
  - backlog
---

# Runtime Skeleton Wave 2 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `R11`, `R12`, `R13` published repo-scoped ready-implementation packs
- `R14` concluded that no new shared contract is required before scaffolding
- `R15` recorded `ready_for_wave2_issue_projection=true`

## Wave 2 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `S10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `package.json` |
| `S11` | 20 | `rather-not-work-on/monday` | `runtime` | `backlog` | `packages/executor-ralph-loop/package.json` |
| `S12` | 30 | `rather-not-work-on/monday` | `runtime` | `backlog` | `packages/provider-client-adapter/package.json` |
| `S20` | 40 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-runtime/package.json` |
| `S21` | 50 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `backlog` | `adapters/provider-codex/package.json` |
| `S30` | 60 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `services/telemetry-gateway/package.json` |
| `S40` | 70 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-skeleton-wave2-scaffold-review.json` |

## Decomposition Rules

- `S10` creates the monday workspace root and shared runtime workspace descriptors.
- `S11` creates monday core runtime package skeletons:
  - `contract-bindings`
  - `agent-kernel`
  - `executor-ralph-loop`
  - `orchestrator`
- `S12` creates monday adapter package skeletons:
  - `provider-client-adapter`
  - `o11y-client-adapter`
  - `messaging-adapter`
- `S20` creates provider gateway workspace root plus `services/provider-runtime`.
- `S21` creates provider adapter package skeletons.
- `S30` creates observability workspace root plus `services/telemetry-gateway`, `sinks/langfuse-sink`, and `buffer/replay-worker`.
- `S40` validates that scaffold outputs match the published blueprint packs and repo boundaries.

## Dependencies

- `S11` depends on `S10`
- `S12` depends on `S10`
- `S21` depends on `S20`
- `S40` depends on `S11`, `S12`, `S21`, `S30`

## Intentional Omissions

- No `platform-contracts` scaffold issue is created in this wave because `R14` found no shared contract gap.
- No local infra issue is included here; LiteLLM/LangFuse runtime wiring remains a later wave after package scaffolds exist.
