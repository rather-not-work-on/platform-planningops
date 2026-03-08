---
doc_id: uap-observability-gateway-runtime-skeleton-ready-implementation-pack
title: feat: platform-observability-gateway Runtime Skeleton Ready-Implementation Pack
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - observability
  - gateway
  - blueprint
summary: Freezes the observability gateway service, sink, and replay topology, dependency manifest, file plan, and verification pack required before workspace scaffolding begins.
related_docs:
  - ../../../30-execution-plan/uap-runtime-skeleton-wave1-blueprint-pack.execution-plan.md
  - ../../../../../../planningops/contracts/implementation-readiness-gate-contract.md
  - ../../../../../../docs/workbench/unified-personal-agent-platform/audits/langfuse-boundary-map.md
---

# feat: platform-observability-gateway Runtime Skeleton Ready-Implementation Pack

## Purpose

Freeze the implementation blueprint for `platform-observability-gateway` before any observability runtime packages are scaffolded.

The repository already owns:
- ingest/replay evidence contracts
- local replay and ingest smoke tooling
- LangFuse-oriented launcher and reason taxonomy

The next wave must add runtime packages without embedding replay policy in scripts or leaking LangFuse-specific details into planningops or monday.

## Current Baseline

The current repository contains:
- `contracts/`
- `config/`
- `scripts/`
- `docs/runbook/`
- `runtime-artifacts/`

It does **not** yet contain:
- `services/telemetry-gateway`
- `sinks/langfuse-sink`
- `buffer/replay-worker`
- workspace manifests for a TypeScript runtime layer

## Interface Contract Refs

### Shared contracts
- `rather-not-work-on/platform-contracts:schemas/c5-observability-event.schema.json`

### Repo-owned contracts and config
- `rather-not-work-on/platform-observability-gateway:contracts/c5-observability-ingest-contract.schema.json`
- `rather-not-work-on/platform-observability-gateway:contracts/c5-observability-ingest-smoke-artifact.schema.json`
- `rather-not-work-on/platform-observability-gateway:config/observability-reason-taxonomy.json`
- `rather-not-work-on/platform-observability-gateway:config/contract-pin.json`

### Governing planning contracts
- `planningops/contracts/implementation-readiness-gate-contract.md`
- `planningops/contracts/control-plane-boundary-contract.md`

## Target Package Topology

### Keep as-is in wave 2
- `contracts/`
- `config/`
- `scripts/`
- `docs/runbook/`
- `runtime-artifacts/`

### Add in wave 2
- `services/telemetry-gateway`
- `sinks/langfuse-sink`
- `buffer/replay-worker`

### Explicitly defer
- alternate observability sinks beyond LangFuse
- remote deployment packaging
- control-plane-owned replay policy in this repo

## Dependency Manifest

### Layering
1. `contracts/` and `config/`
2. `sinks/langfuse-sink`
3. `buffer/replay-worker`
4. `services/telemetry-gateway`

### Allowed dependencies
- `sinks/langfuse-sink`
  - may depend on observability contract bindings
  - may depend on static endpoint/config readers
  - must not own replay policy
- `buffer/replay-worker`
  - may depend on observability contract bindings
  - may depend on sink interfaces
  - owns replay/dedupe loop behavior
  - must not expose LangFuse SDK details upstream
- `services/telemetry-gateway`
  - may depend on observability contract bindings
  - may depend on sink interfaces
  - may depend on replay-worker interfaces
  - owns ingest normalization and dispatch decisions

### Forbidden edges
- `sinks/langfuse-sink -> planningops`
- `buffer/replay-worker -> planningops`
- `services/telemetry-gateway -> planningops`
- `scripts/ -> services/telemetry-gateway` as the source of architectural truth
- `runtime-artifacts/ -> services/*`

## File Plan

### Root additions
- `package.json`
- `pnpm-workspace.yaml`
- `tsconfig.base.json`

### Package additions
- `services/telemetry-gateway/package.json`
- `services/telemetry-gateway/src/index.ts`
- `services/telemetry-gateway/src/telemetry_gateway.ts`
- `services/telemetry-gateway/README.md`
- `sinks/langfuse-sink/package.json`
- `sinks/langfuse-sink/src/index.ts`
- `sinks/langfuse-sink/src/langfuse_sink.ts`
- `sinks/langfuse-sink/README.md`
- `buffer/replay-worker/package.json`
- `buffer/replay-worker/src/index.ts`
- `buffer/replay-worker/src/replay_worker.ts`
- `buffer/replay-worker/src/file_buffer.ts`
- `buffer/replay-worker/README.md`

### Root updates
- `README.md`
- `docs/repo-topology.md`
- `contracts/README.md`
- `config/README.md`
- `scripts/README.md`
- `docs/runbook/README.md`

### Explicit non-goals for wave 2
- moving ingest smoke scenarios out of `scripts/`
- writing runtime outputs into tracked Git paths
- coupling monday directly to LangFuse sink implementation

## Verification Plan

Wave 2 implementation is not allowed to enter `ready-implementation` unless all of the following are satisfied:
- `python3 scripts/langfuse_ingest_smoke.py --scenario normal`
- `python3 scripts/langfuse_ingest_smoke.py --scenario delay_and_replay`
- `python3 scripts/validate_ingest_smoke_evidence.py --report runtime-artifacts/ingest/<run-id>-delay_and_replay.json`
- `python3 scripts/validate_contract_pin.py`
- `bash scripts/test_observability_guardrails.sh`
- `bash scripts/test_module_readmes.sh`
- workspace bootstrap check:
  - `pnpm install --frozen-lockfile=false`
  - `pnpm -r exec tsc --noEmit`

## Module README Deltas

The implementation wave must update or add:
- root `README.md` to describe the new service/sink/replay layer
- `services/telemetry-gateway/README.md`
- `sinks/langfuse-sink/README.md`
- `buffer/replay-worker/README.md`
- `docs/repo-topology.md` to include `services/`, `sinks/`, and `buffer/` as first-class boundaries once scaffolding lands
- `scripts/README.md` to keep scripts classified as repeatable smoke and launcher tooling

## Ready-Implementation Exit Criteria

This pack is sufficient for `ready-implementation` only if:
- runtime service, sink, and replay package names are final
- ingest, replay, and sink ownership is final
- dependency direction is final
- file additions are explicit
- README delta list is explicit
- no additional shared-contract change is required before scaffolding

## Working Defaults

- runtime workspace language: TypeScript on Node.js
- workspace manager: `pnpm`
- existing Python scripts remain smoke and launcher tooling in this wave
