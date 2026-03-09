---
title: plan: Runtime Behavior Wave 5 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that converts the wave4 interface packs into repo-local typed behavior implementation tasks across monday, provider, and observability.
tags:
  - uap
  - implementation
  - runtime
  - interfaces
  - backlog
---

# Runtime Behavior Wave 5 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `I10` to `I14` are merged and their outputs exist
- `I15` recorded `verdict=pass` in `planningops/artifacts/validation/runtime-interface-wave4-readiness-report.json`
- the next blocked step is behavior implementation, not package or interface naming

## Goal

Implement the typed runtime boundaries defined in wave 4 without collapsing repo ownership.

The rule for this wave is strict:
- keep public shared contracts reactive
- move placeholder method signatures to typed repo-local ports
- keep routing, replay, and orchestration policy inside the owning repo
- use planningops only for cross-repo validation and backlog projection

## Wave 5 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `W10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/contract-bindings/src/runtime_ports.ts` |
| `W11` | 20 | `rather-not-work-on/monday` | `runtime` | `backlog` | `packages/orchestrator/src/mission_orchestrator.ts` |
| `W20` | 30 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-runtime/src/provider_driver.ts` |
| `W21` | 40 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `backlog` | `adapters/provider-codex/src/driver.ts` |
| `W30` | 50 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `services/telemetry-gateway/src/telemetry_ports.ts` |
| `W31` | 60 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `backlog` | `buffer/replay-worker/src/replay_worker.ts` |
| `W40` | 70 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-behavior-wave5-interface-review.json` |

## Decomposition Rules

- `W10` introduces monday-owned typed runtime ports and envelopes in `contract-bindings`.
- `W11` adopts those ports in `agent-kernel`, `executor-ralph-loop`, `orchestrator`, and the monday-side adapters.
- `W20` introduces the provider runtime-owned driver contract and routing surface.
- `W21` adopts the runtime-owned driver contract across concrete provider adapters.
- `W30` introduces observability-owned telemetry envelope and ingest/buffer/sink ports.
- `W31` adopts those ports in replay worker and sink implementations.
- `W40` validates that all three execution repos implemented the wave4 boundaries without opening a new shared-contract gap.

## Dependencies

- `W11` depends on `W10`
- `W21` depends on `W20`
- `W31` depends on `W30`
- `W40` depends on `W11`, `W21`, `W31`

## Explicit Non-Goals

- no live LiteLLM or Langfuse runtime deployment yet
- no queue scheduler or long-running worker orchestration yet
- no shared schema additions unless `W40` produces explicit cross-repo gap evidence
