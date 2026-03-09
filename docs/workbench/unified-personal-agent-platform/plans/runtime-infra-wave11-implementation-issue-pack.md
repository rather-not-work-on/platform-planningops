---
title: plan: Runtime Infra Wave 11 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that wires local-first runtime profiles and launcher-aware transport composition into monday, provider, and observability without collapsing repository boundaries.
tags:
  - uap
  - implementation
  - runtime
  - infra
  - local-first
  - backlog
---

# Runtime Infra Wave 11 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `AB10` to `AB40` are merged and their outputs exist
- `planningops/artifacts/validation/runtime-behavior-wave10-review.json` recorded `verdict=pass`
- default composition now lives in repo-owned composer layers, so the next uncertainty is local profile wiring rather than dependency topology

## Goal

Attach local-first runtime profile and launcher knowledge to the new composer layers so later end-to-end smokes can run without rewriting core packages.

The rule for this wave is strict:
- monday owns local runtime composition that binds profiled provider and telemetry clients without knowing launcher internals
- platform-provider-gateway owns LiteLLM local composer wiring on top of the existing launcher/profile drill
- platform-observability-gateway owns Langfuse local composer wiring on top of the existing launcher/replay drill
- planningops verifies profile portability and evidence paths, but does not own runtime factory code

## Wave 11 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AC10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/orchestrator/src/default_local_runtime.ts` |
| `AC20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-gateway-composer/src/default_litellm_runtime.ts` |
| `AC30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `services/telemetry-gateway-composer/src/default_langfuse_gateway.ts` |
| `AC40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-infra-wave11-review.json` |

## Decomposition Rules

- `AC10` adds a monday-owned local runtime composer that resolves the active runtime profile and builds profiled provider/o11y clients through existing default runtime composition.
- `AC20` adds a provider-owned local LiteLLM composer that translates runtime profile input into a ready local provider runtime without moving launcher logic into core runtime.
- `AC30` adds an observability-owned local Langfuse composer that translates runtime profile input into a ready local telemetry gateway without moving launcher or replay logic into core gateway.
- `AC40` validates that local profile wiring stays in composer layers, keeps profile portability intact, and does not rewrite artifact residency or evidence paths.

## Dependencies

- `AC40` depends on `AC10`, `AC20`, `AC30`

## Explicit Non-Goals

- no live Oracle Cloud activation yet
- no federated end-to-end mission smoke yet
- no long-running daemon or scheduler loop changes yet
- no secrets bootstrap automation in planningops
