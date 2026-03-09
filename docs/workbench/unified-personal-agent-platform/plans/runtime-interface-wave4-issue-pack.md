---
title: plan: Runtime Interface Wave 4 Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that freezes runtime interface wiring and typed port boundaries before real provider or observability integrations expand.
tags:
  - uap
  - interface
  - contracts
  - runtime
  - backlog
---

# Runtime Interface Wave 4 Issue Pack

## Preconditions

This issue pack is valid because:
- wave 2 runtime scaffolds are merged
- wave 3 local install and typecheck baseline is green
- the next technical unknown is interface wiring, not package creation

## Goal

Freeze the typed port boundaries among:
- `monday`
- `platform-provider-gateway`
- `platform-observability-gateway`
- `platform-contracts`

before expanding runtime behavior or infra integrations.

## User Decision Boundary

This wave intentionally avoids decisions that remain user-owned:
- final first UX
- provider precedence policy
- durable local infra topology
- secrets loading policy

This wave only fixes technical boundaries that are already implied by the current topology.

## Wave 4 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `I10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `docs/initiatives/unified-personal-agent-platform/30-execution-plan/uap-runtime-interface-wave4.execution-plan.md` |
| `I11` | 20 | `rather-not-work-on/monday` | `runtime` | `backlog` | `docs/initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-interface-wiring-pack.md` |
| `I12` | 30 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `backlog` | `docs/initiatives/unified-personal-agent-platform/20-repos/platform-provider-gateway/30-execution-plan/runtime-interface-wiring-pack.md` |
| `I13` | 40 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `backlog` | `docs/initiatives/unified-personal-agent-platform/20-repos/platform-observability-gateway/30-execution-plan/runtime-interface-wiring-pack.md` |
| `I14` | 50 | `rather-not-work-on/platform-contracts` | `contracts` | `backlog` | `docs/initiatives/unified-personal-agent-platform/20-repos/platform-contracts/30-execution-plan/runtime-interface-contract-gap-matrix.md` |
| `I15` | 60 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-interface-wave4-readiness-report.json` |
| `I16` | 70 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `docs/workbench/unified-personal-agent-platform/plans/runtime-behavior-wave5-implementation-issue-pack.md` |

## Decomposition Rules

- `I10` defines the canonical wave objective, required evidence, and stop conditions.
- `I11` freezes monday-owned ports among kernel, executor, orchestrator, provider adapter, and o11y adapter.
- `I12` freezes provider gateway service-to-adapter invocation boundaries.
- `I13` freezes telemetry gateway, sink, and replay worker boundaries.
- `I14` determines whether existing `C1`-`C5` and `C8` are enough or whether new shared contracts are proven necessary.
- `I15` validates that interface references are resolvable and no hidden topology choice remains.
- `I16` projects the next implementation pack only after interface freeze is complete.

## Dependencies

- `I11`, `I12`, `I13` depend on `I10`
- `I14` depends on `I11`, `I12`, `I13`
- `I15` depends on `I11`, `I12`, `I13`, `I14`
- `I16` depends on `I15`

## Explicit Non-Goals

- no real provider SDK integration
- no real Langfuse SDK integration
- no executor retry policy expansion
- no queue semantics expansion
- no provider default policy decision
