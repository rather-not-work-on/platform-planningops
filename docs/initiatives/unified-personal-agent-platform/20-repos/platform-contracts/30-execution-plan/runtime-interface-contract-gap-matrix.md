---
doc_id: uap-runtime-interface-contract-gap-matrix
title: feat: Runtime Interface Shared Contract Gap Matrix
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - contracts
  - interfaces
  - compatibility
summary: Records whether the runtime interface wave requires new shared schemas or whether existing shared contracts remain sufficient while typed ports stay repo-local.
related_docs:
  - ../../../30-execution-plan/uap-runtime-interface-wave4.execution-plan.md
  - ../../monday/30-execution-plan/runtime-interface-wiring-pack.md
  - ../../platform-provider-gateway/30-execution-plan/runtime-interface-wiring-pack.md
  - ../../platform-observability-gateway/30-execution-plan/runtime-interface-wiring-pack.md
---

# feat: Runtime Interface Shared Contract Gap Matrix

## Purpose

Determine whether wave 4 interface wiring requires new shared contracts in `platform-contracts`, or whether existing shared schemas plus repo-local typed ports are sufficient.

This document remains conservative:
- do not create a shared schema because two repos use similar words
- create a shared schema only when a cross-repo payload must be versioned and pinned by multiple consumers

## Decision

No new shared contract is required for wave 4.

Existing shared contracts remain sufficient:
- `C1` run lifecycle
- `C2` subtask handoff
- `C3` executor result
- `C4` provider invocation
- `C5` observability event
- `C8` plan-to-github projection

## Interface Contract Refs

- `rather-not-work-on/platform-contracts:schemas/c1-run-lifecycle.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c2-subtask-handoff.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c3-executor-result.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c4-provider-invocation.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c5-observability-event.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c8-plan-to-github-projection.schema.json`

## Target Package Topology

No topology expansion is allowed in `platform-contracts` for wave 4.

Wave 4 only touches:
- existing shared schemas under `schemas/`
- compatibility analysis under `scripts/compatibility/`
- documentation under `docs/` and initiative execution-plan refs

Wave 4 must not introduce:
- repo-internal port schemas that only one consumer uses
- workspace-layout schemas
- driver-specific or sink-specific contracts

## Dependency Manifest

### Allowed dependencies
- shared schema evolution may depend on:
  - existing schema set `C1` to `C5`, `C8`
  - compatibility classification tooling
  - consumer pin verification rules

### Forbidden dependencies
- `platform-contracts` must not absorb repo-local interface types from:
  - `monday`
  - `platform-provider-gateway`
  - `platform-observability-gateway`
- shared schema additions must not be created from naming similarity alone
- no schema may be added without a named consumer-pin impact

## File Plan

### Files to update
- `docs/initiatives/unified-personal-agent-platform/20-repos/platform-contracts/30-execution-plan/runtime-interface-contract-gap-matrix.md`

### Conditionally deferred files
- `schemas/*.schema.json`
- `schemas/compatibility-matrix.json`
- `scripts/classify_schema_change.py`

These stay untouched unless wave 4 produces concrete gap evidence.

## Verification Plan

- `python3 scripts/validate_contracts.py`
- `python3 scripts/classify_schema_change.py --scenario additive_optional`
- confirm that all wave 4 repo packs still normalize to existing shared contracts
- confirm that no new consumer pin is required

Wave 4 fails if:
- a repo pack requires a new shared payload that cannot be described with the current schema set
- SemVer impact is non-zero but no schema delta is proposed
- a repo-local interface is promoted to shared scope without at least two real consumers

## Module README Deltas

- `docs/repo-topology.md`
  - no topology change expected; mention explicitly that wave 4 stayed reactive
- `contracts/README.md` or schema index docs
  - update only if a new shared contract becomes necessary

## Gap Matrix

| Consumer repo | Interface wave scope | Shared contracts already sufficient | Gap verdict | Action |
| --- | --- | --- | --- | --- |
| `rather-not-work-on/monday` | internal runtime ports between orchestrator, executor, kernel, and adapters | `C1`, `C2`, `C3`, `C8` | no gap | keep port interfaces repo-local in `contract-bindings` |
| `rather-not-work-on/platform-provider-gateway` | runtime-to-driver request/result and routing interfaces | `C4` | no gap | keep driver/runtime interfaces repo-local; normalize to `C4` at the public boundary |
| `rather-not-work-on/platform-observability-gateway` | ingest/buffer/replay/sink interfaces | `C5` | no gap | keep buffer/sink interfaces repo-local; normalize to `C5` at the public ingest boundary |

## Why No Gap Exists

### monday
- wave 4 only needs stable repo-internal ports for runtime composition
- no new cross-repo payload is introduced beyond existing lifecycle, handoff, and result vocabulary

### provider gateway
- the repo needs clearer internal driver contracts, not a new public consumer schema
- provider-specific fallback and reason codes remain local implementation policy

### observability gateway
- replay and sink semantics are repo-local execution details
- external consumers still only need the public event shape already covered by `C5`

## Deferred Shared Contract Candidates

These remain explicitly deferred until failure evidence proves otherwise:
- shared provider capability catalog schema
- shared telemetry correlation envelope spanning `monday` and observability
- shared retry-budget contract between executor and provider gateway
- shared replay cursor schema

If any of these become necessary, the owning card must move back to `ready_contract` with:
- failing implementation evidence
- SemVer impact analysis
- consumer pin delta list

## SemVer and Pin Impact

- required shared schema bump now: `none`
- consumer pin update now: `none`
- compatibility risk for wave 4: `low`
- reason to stay conservative: internal interface wiring is still settling and should not be frozen at org scope yet

## Exit Condition

`I14` is complete when:
- the `no gap` verdict is explicit
- deferred shared-contract candidates are named
- future shared schema work is blocked on concrete cross-repo evidence rather than anticipation
