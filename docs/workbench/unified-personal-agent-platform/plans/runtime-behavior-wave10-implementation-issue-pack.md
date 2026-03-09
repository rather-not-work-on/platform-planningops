---
title: plan: Runtime Behavior Wave 10 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that extracts default runtime composition into repo-owned factories so later transport and infra wiring does not collapse back into god constructors.
tags:
  - uap
  - implementation
  - runtime
  - behavior
  - composition
  - backlog
---

# Runtime Behavior Wave 10 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `AA10` to `AA40` are merged and their outputs exist
- `planningops/artifacts/validation/runtime-behavior-wave9-review.json` recorded `verdict=pass`
- outbound payload shape is now explicit, so the next instability is default dependency composition rather than request structure

## Goal

Move default runtime composition into repo-owned factories so future local infra wiring can swap transports without rewriting orchestrators, runtimes, or gateways inline.

The rule for this wave is strict:
- monday owns default executor dependency composition
- platform-provider-gateway owns default provider driver registry composition in a composer package, not inside core runtime
- platform-observability-gateway owns default telemetry gateway composition in a composer package, not inside core gateway
- planningops only verifies the resulting boundaries and does not become the factory owner

## Wave 10 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AB10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/orchestrator/src/default_runtime_dependencies.ts` |
| `AB20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-gateway-composer/src/default_provider_registry.ts` |
| `AB30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `services/telemetry-gateway-composer/src/default_telemetry_gateway.ts` |
| `AB40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-behavior-wave10-review.json` |

## Decomposition Rules

- `AB10` extracts monday default executor dependency construction from `MissionOrchestrator` into explicit factory helpers.
- `AB20` extracts the default provider driver registry into a repo-owned composer package that composes codex, claude, and local-llm adapters without reversing core runtime dependency direction.
- `AB30` extracts the default telemetry gateway composition into a repo-owned composer package that composes the file buffer and Langfuse sink without reversing core gateway dependency direction.
- `AB40` validates that the three execution repos own their default composition and that planningops still only holds evidence and review logic.

## Dependencies

- `AB40` depends on `AB10`, `AB20`, `AB30`

## Explicit Non-Goals

- no live LiteLLM or Langfuse process management yet
- no environment-specific config loading yet
- no monday queue or worker topology expansion yet
- no cross-repo shared factory package
