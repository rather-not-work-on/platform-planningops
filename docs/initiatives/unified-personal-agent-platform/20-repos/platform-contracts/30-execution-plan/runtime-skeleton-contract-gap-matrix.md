---
doc_id: uap-runtime-skeleton-contract-gap-matrix
title: feat: Runtime Skeleton Shared Contract Gap Matrix
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - contracts
  - compatibility
  - blueprint
summary: Records whether the runtime skeleton wave requires new shared schemas or whether existing C1-C5 and C8 contracts are sufficient for the scaffold phase.
related_docs:
  - ../../../30-execution-plan/uap-runtime-skeleton-wave1-blueprint-pack.execution-plan.md
  - ../../monday/30-execution-plan/runtime-skeleton-ready-implementation-pack.md
  - ../../platform-provider-gateway/30-execution-plan/runtime-skeleton-ready-implementation-pack.md
  - ../../platform-observability-gateway/30-execution-plan/runtime-skeleton-ready-implementation-pack.md
---

# feat: Runtime Skeleton Shared Contract Gap Matrix

## Purpose

Determine whether wave 1 runtime skeleton scaffolding requires new shared contracts in `platform-contracts`, or whether existing shared schemas are already sufficient.

This document is intentionally conservative:
- do not add shared contracts because future code might want them
- add shared contracts only when a repo-scoped pack proves that scaffolding cannot begin without one

## Decision

No new shared contract is required for the wave 2 scaffold phase.

The current shared contract set is sufficient for the next implementation wave:
- `C1` run lifecycle
- `C2` subtask handoff
- `C3` executor result
- `C4` provider invocation
- `C5` observability event
- `C8` plan-to-github projection

## Gap Matrix

| Consumer repo | Planned runtime surface | Shared contracts already sufficient | Gap verdict | Action |
| --- | --- | --- | --- | --- |
| `rather-not-work-on/monday` | workspace packages for orchestrator, executor, kernel, and adapters | `C1`, `C2`, `C3`, `C8` | no gap | use existing shared schemas through `contract-bindings` |
| `rather-not-work-on/platform-provider-gateway` | service + provider adapters | `C4` | no gap | keep repo-local routing config and artifact schemas local |
| `rather-not-work-on/platform-observability-gateway` | telemetry gateway + sink + replay worker | `C5` | no gap | keep repo-local ingest smoke and replay artifact schemas local |

## Why No Gap Exists

### monday
- package scaffolding needs stable shared execution vocabulary, not new shared package-specific schemas
- repo-owned runtime evidence remains local to `monday`

### provider gateway
- adapter scaffolding can normalize around existing `C4` invocation shape
- fallback, routing, and smoke evidence remain repo-local concerns

### observability gateway
- sink and replay scaffolding can normalize around existing `C5` event shape
- replay, dedupe, and ingest smoke evidence remain repo-local concerns

## Explicitly Deferred Contract Candidates

These are not needed for wave 2 scaffolding and must not be added preemptively:
- shared provider routing policy schema
- shared observability replay policy schema
- shared package-manifest schema for TypeScript workspace layout
- shared module README schema for execution repos

If any of these become necessary during implementation, the affected card must re-enter `ready-contract` with explicit failure evidence.

## SemVer and Pin Impact

- required shared schema bump now: `none`
- consumer pin update now: `none`
- compatibility risk for wave 2 scaffold: `low`

## Exit Condition

`R14` is complete when:
- the no-gap verdict is explicit
- deferred candidates are recorded
- future shared-contract creation is guarded by redefinition triggers instead of anticipation
