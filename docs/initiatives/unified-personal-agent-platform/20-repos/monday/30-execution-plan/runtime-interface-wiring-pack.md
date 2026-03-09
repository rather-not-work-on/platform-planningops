---
doc_id: uap-monday-runtime-interface-wiring-pack
title: feat: monday Runtime Interface Wiring Pack
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - monday
  - runtime
  - interfaces
summary: Freezes the typed port boundaries for the monday orchestrator, executor, kernel, and external adapters before runtime behavior implementation begins.
related_docs:
  - ./runtime-skeleton-ready-implementation-pack.md
  - ../../../30-execution-plan/uap-runtime-interface-wave4.execution-plan.md
  - ../20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
  - ../../../../../../planningops/contracts/implementation-readiness-gate-contract.md
---

# feat: monday Runtime Interface Wiring Pack

## Purpose

Freeze the typed boundaries inside `monday` so wave 5 can implement behavior without inventing new runtime seams.

Wave 2 created the package topology. Wave 4 fixes what each package is allowed to say to the next package.

## Current Baseline

The current package skeleton already exists:
- `packages/contract-bindings`
- `packages/agent-kernel`
- `packages/executor-ralph-loop`
- `packages/orchestrator`
- `packages/provider-client-adapter`
- `packages/o11y-client-adapter`
- `packages/messaging-adapter`

The current code still uses placeholder signatures:
- `MissionOrchestrator.createRun()` directly instantiates executor and delegator
- `RalphLoopExecutor.execute()` receives raw `MissionInput`
- `ProviderClient.invoke()` returns an `ExecutorResult`
- `TimelineEmitterClient.emit()` accepts only `eventName: string`

Wave 4 must replace these placeholder signatures with explicit ports and envelopes before local infra wiring begins.

## Interface Contract Refs

### Shared contracts
- `rather-not-work-on/platform-contracts:schemas/c1-run-lifecycle.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c2-subtask-handoff.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c3-executor-result.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c8-plan-to-github-projection.schema.json`

### monday-owned contracts
- `rather-not-work-on/monday:contracts/executor-worker-handoff-map.json`
- `rather-not-work-on/monday:contracts/handoff-required-fields.json`
- `rather-not-work-on/monday:contracts/runtime-handoff-evidence.schema.json`
- `rather-not-work-on/monday:contracts/runtime-scheduler-evidence.schema.json`
- `rather-not-work-on/monday:contracts/runtime-integration-evidence.schema.json`

### Governing planning contracts
- `planningops/contracts/node-workspace-bootstrap-contract.md`
- `planningops/contracts/implementation-readiness-gate-contract.md`
- `planningops/contracts/control-plane-boundary-contract.md`

## Target Package Topology

### Package responsibilities
- `contract-bindings`
  - shared runtime vocabulary and repo-local port envelopes
- `agent-kernel`
  - mission decomposition and task delegation semantics
- `executor-ralph-loop`
  - bounded execution loop over already-shaped task units
- `orchestrator`
  - dependency composition and run lifecycle entrypoints
- `provider-client-adapter`
  - monday-side port to `platform-provider-gateway`
- `o11y-client-adapter`
  - monday-side port to `platform-observability-gateway`
- `messaging-adapter`
  - external notification acknowledgements and handoff signals

### New explicit interface placements
- `contract-bindings` becomes the only place allowed to export:
  - `TaskExecutionEnvelope`
  - `ProviderInvocationPort`
  - `TelemetryEmitPort`
  - `MessagingAckPort`
  - `ExecutorLoopDependencies`
- `orchestrator` consumes ports but does not define gateway payloads
- `executor-ralph-loop` consumes `ProviderInvocationPort` and `TelemetryEmitPort`, never concrete clients
- adapter packages implement ports but do not define mission or run semantics

## Dependency Manifest

### Allowed imports
- `contract-bindings`
  - imports shared schema bindings only
- `agent-kernel`
  - may import `contract-bindings`
- `provider-client-adapter`
  - may import `contract-bindings`
- `o11y-client-adapter`
  - may import `contract-bindings`
- `messaging-adapter`
  - may import `contract-bindings`
- `executor-ralph-loop`
  - may import `contract-bindings`
  - may import `agent-kernel` types only when delegation output is already normalized
- `orchestrator`
  - may import `contract-bindings`
  - may import `agent-kernel`
  - may import `executor-ralph-loop`
  - may import adapter packages only through exported ports/factories

### Forbidden imports
- `orchestrator -> provider gateway payload internals`
- `orchestrator -> observability ingest payload internals`
- `executor-ralph-loop -> concrete provider/o11y implementations`
- `agent-kernel -> adapter packages`
- `scripts/ -> packages/*` as the authoritative runtime boundary

### Cross-repo dependency rule
- `monday` depends on provider and observability repos only through HTTP/client-adapter semantics
- no direct source import across repositories is allowed

## File Plan

### Files to add
- `packages/contract-bindings/src/runtime_ports.ts`
- `packages/contract-bindings/src/runtime_envelopes.ts`
- `packages/executor-ralph-loop/src/executor_dependencies.ts`
- `packages/orchestrator/src/orchestrator_ports.ts`
- `packages/provider-client-adapter/src/provider_gateway_client.ts`
- `packages/o11y-client-adapter/src/telemetry_gateway_client.ts`
- `packages/messaging-adapter/src/ack_port.ts`

### Files to update
- `packages/contract-bindings/src/index.ts`
- `packages/agent-kernel/src/index.ts`
- `packages/agent-kernel/src/subtask_delegator.ts`
- `packages/executor-ralph-loop/src/index.ts`
- `packages/executor-ralph-loop/src/ralph_loop_executor.ts`
- `packages/orchestrator/src/index.ts`
- `packages/orchestrator/src/mission_orchestrator.ts`
- `packages/provider-client-adapter/src/index.ts`
- `packages/provider-client-adapter/src/provider_client.ts`
- `packages/o11y-client-adapter/src/index.ts`
- `packages/o11y-client-adapter/src/timeline_emitter_client.ts`
- `packages/messaging-adapter/src/index.ts`
- `packages/messaging-adapter/src/messaging_adapter.ts`
- `docs/repo-topology.md`
- `README.md`

### Explicitly deferred
- queue scheduler persistence
- concrete messaging provider implementations
- long-running worker runtime
- live LiteLLM or Langfuse network wiring

## Verification Plan

- `pnpm -r exec tsc --noEmit`
- `bash scripts/test_module_readmes.sh`
- `python3 scripts/validate_handoff_mapping.py`
- `python3 scripts/integrate_planningops_handoff.py --run-id <run-id>`
- `bash scripts/test_scheduler_queue.sh`
- `python3 scripts/validate_contract_pin.py`
- `bash scripts/test_contract_pin_validation.sh`

Implementation is not ready if:
- any package still exports placeholder string-only ports
- orchestrator still constructs gateway payloads ad hoc
- executor still returns provider results without an explicit execution envelope

## Module README Deltas

- root `README.md`
  - explain that runtime packages now communicate through typed ports
- `packages/contract-bindings/README.md`
  - document which port interfaces are public within the repo
- `packages/executor-ralph-loop/README.md`
  - define loop ownership and forbidden dependencies
- `packages/orchestrator/README.md`
  - define composition-only responsibility
- `packages/provider-client-adapter/README.md`
  - define monday-side provider gateway contract
- `packages/o11y-client-adapter/README.md`
  - define monday-side observability gateway contract
- `packages/messaging-adapter/README.md`
  - define acknowledgement-only role
- `docs/repo-topology.md`
  - update arrows so imports and ports match the same story
