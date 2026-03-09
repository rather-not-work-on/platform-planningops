---
title: plan: Runtime Behavior Wave 9 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that aligns monday client adapters, provider request normalization, and observability envelope normalization without introducing live infra coupling.
tags:
  - uap
  - implementation
  - runtime
  - behavior
  - adapters
  - normalization
  - backlog
---

# Runtime Behavior Wave 9 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- `Z10` to `Z40` are merged and their outputs exist
- `planningops/artifacts/validation/runtime-behavior-wave8-review.json` recorded `verdict=pass`
- the next uncertainty is not policy ownership but whether runtime payloads are shaped consistently before transport boundaries are wired

## Goal

Tighten repo-local runtime payload construction so the next transport and infra wave can plug into stable inputs instead of stubs that invent shape ad hoc.

The rule for this wave is strict:
- monday owns shaping of outbound provider and telemetry payloads
- platform-provider-gateway owns normalization of inbound invocation requests before driver dispatch
- platform-observability-gateway owns normalization of inbound telemetry envelopes before dispatch and sink delivery
- shared contracts remain reactive and are not extended unless review proves a gap

## Wave 9 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AA10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/provider-client-adapter/src/provider_client.ts` |
| `AA20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `services/provider-runtime/src/request_policy.ts` |
| `AA30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `services/telemetry-gateway/src/envelope_policy.ts` |
| `AA40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-behavior-wave9-review.json` |

## Decomposition Rules

- `AA10` adds monday-owned request and event shaping helpers so executor code passes explicit payload builders into provider and telemetry client adapters instead of constructing inline transport payloads.
- `AA20` adds provider-owned request normalization so runtime resolves provider selection, normalized prompt text, and invocation metadata before driver lookup.
- `AA30` adds observability-owned envelope normalization so telemetry gateway and sink consume explicit normalized envelopes instead of trimming fields independently.
- `AA40` validates that execution repos aligned payload shape at their own boundaries and did not reopen a shared-contract gap.

## Dependencies

- `AA40` depends on `AA10`, `AA20`, `AA30`

## Explicit Non-Goals

- no live LiteLLM or Langfuse transport wiring yet
- no cross-repo package import between monday and execution repos
- no scheduler or queue behavior changes
- no new shared schema unless `AA40` records concrete mismatch evidence
