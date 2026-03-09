---
doc_id: uap-observability-gateway-runtime-interface-wiring-pack
title: feat: platform-observability-gateway Runtime Interface Wiring Pack
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - observability
  - runtime
  - interfaces
summary: Freezes the ingest, buffer, replay, and sink interfaces so observability integrations can expand without re-cutting repo topology.
related_docs:
  - ./runtime-skeleton-ready-implementation-pack.md
  - ../../../30-execution-plan/uap-runtime-interface-wave4.execution-plan.md
  - ../../../../../../planningops/contracts/implementation-readiness-gate-contract.md
---

# feat: platform-observability-gateway Runtime Interface Wiring Pack

## Purpose

Freeze the typed path from ingest to sink so later Langfuse or storage-specific integrations do not redefine observability ownership.

This wave must make one thing explicit: ingest semantics belong to the gateway, replay semantics belong to the worker, and sink semantics belong to the sink implementation.

## Current Baseline

Current runtime pieces already exist:
- `services/telemetry-gateway`
- `buffer/replay-worker`
- `sinks/langfuse-sink`

Current code gaps:
- `TelemetryGateway.ingest()` accepts only `eventName: string`
- `FileBuffer.append()` and `LangfuseSink.deliver()` are not typed around a shared repo-local envelope
- `ReplayWorker.replay()` does not yet communicate through explicit buffer and sink ports

## Interface Contract Refs

### Shared contracts
- `rather-not-work-on/platform-contracts:schemas/c5-observability-event.schema.json`

### observability-owned contracts
- `rather-not-work-on/platform-observability-gateway:contracts/c5-observability-ingest-contract.schema.json`
- `rather-not-work-on/platform-observability-gateway:contracts/c5-observability-ingest-smoke-artifact.schema.json`
- `rather-not-work-on/platform-observability-gateway:config/observability-reason-taxonomy.json`
- `rather-not-work-on/platform-observability-gateway:config/ingest-policy.example.json`

### Governing planning contracts
- `planningops/contracts/node-workspace-bootstrap-contract.md`
- `planningops/contracts/federated-artifact-storage-contract.md`
- `planningops/contracts/implementation-readiness-gate-contract.md`

## Target Package Topology

### Public ingest surface
- `services/telemetry-gateway`
  - owns `TelemetryIngestPort`
  - normalizes caller input into a repo-local telemetry envelope
  - writes to buffer and/or synchronous sink ports through interfaces only

### Replay surface
- `buffer/replay-worker`
  - owns replay batch traversal and retry reason mapping
  - implements the buffer-side port
  - consumes the sink-side port

### Sink surface
- `sinks/langfuse-sink`
  - implements the sink-side delivery port
  - does not own replay orchestration or ingest validation

## Dependency Manifest

### Allowed imports
- `services/telemetry-gateway`
  - may import shared `C5` bindings
  - may import local ingest policy config
  - may import repo-local port definitions
- `buffer/replay-worker`
  - may import shared `C5` bindings
  - may import repo-local port definitions
  - may import reason taxonomy
- `sinks/langfuse-sink`
  - may import shared `C5` bindings
  - may import repo-local sink port definitions

### Forbidden imports
- `services/telemetry-gateway -> sinks/langfuse-sink` concrete implementation
- `services/telemetry-gateway -> buffer/replay-worker` concrete implementation
- `sinks/langfuse-sink -> buffer/replay-worker`
- `buffer/replay-worker -> services/telemetry-gateway`
- any package writing tracked artifacts directly

### Cross-repo dependency rule
- `monday` and other consumers depend only on the ingest surface of this repo
- no consumer may call replay or sink implementations directly

## File Plan

### Files to add
- `services/telemetry-gateway/src/telemetry_ingest_port.ts`
- `services/telemetry-gateway/src/telemetry_envelope.ts`
- `services/telemetry-gateway/src/telemetry_ports.ts`
- `buffer/replay-worker/src/replay_batch.ts`
- `buffer/replay-worker/src/replay_reason.ts`
- `sinks/langfuse-sink/src/sink_delivery_port.ts`

### Files to update
- `services/telemetry-gateway/src/index.ts`
- `services/telemetry-gateway/src/telemetry_gateway.ts`
- `buffer/replay-worker/src/index.ts`
- `buffer/replay-worker/src/file_buffer.ts`
- `buffer/replay-worker/src/replay_worker.ts`
- `sinks/langfuse-sink/src/index.ts`
- `sinks/langfuse-sink/src/langfuse_sink.ts`
- `docs/repo-topology.md`
- `README.md`

### Explicitly deferred
- real Langfuse credentials and client initialization
- external durable storage backends
- replay scheduling and queue runtime
- cross-repo trace correlation enrichment beyond the current event envelope

## Verification Plan

- `pnpm -r exec tsc --noEmit`
- `python3 scripts/validate_ingest_smoke_evidence.py --artifact <artifact-path>`
- `bash scripts/test_module_readmes.sh`
- `bash scripts/test_ingest_smoke.sh`
- `python3 scripts/run_ingest_smoke.py --scenario normal`
- `python3 scripts/run_ingest_smoke.py --scenario delay_replay`

Implementation is not ready if:
- ingest still accepts only raw string values
- replay worker cannot be described without naming concrete sink classes
- sink delivery types are defined in multiple packages

## Module README Deltas

- root `README.md`
  - explain ingest/buffer/replay/sink ownership
- `services/telemetry-gateway/README.md`
  - define public ingest surface and port ownership
- `buffer/replay-worker/README.md`
  - define replay responsibilities and dependencies
- `sinks/langfuse-sink/README.md`
  - define sink-only responsibility
- `docs/repo-topology.md`
  - show ingest -> buffer -> replay -> sink flow with concrete-to-interface boundaries
