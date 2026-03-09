---
doc_id: uap-provider-gateway-runtime-interface-wiring-pack
title: feat: platform-provider-gateway Runtime Interface Wiring Pack
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - provider
  - runtime
  - interfaces
summary: Freezes the provider runtime, routing, and driver boundaries so later LiteLLM or model-provider integrations do not reshape repo topology.
related_docs:
  - ./runtime-skeleton-ready-implementation-pack.md
  - ../../../30-execution-plan/uap-runtime-interface-wave4.execution-plan.md
  - ../../../../../../planningops/contracts/implementation-readiness-gate-contract.md
---

# feat: platform-provider-gateway Runtime Interface Wiring Pack

## Purpose

Freeze the provider gateway around a single public runtime port so adapter implementations can expand without leaking routing policy or fallback logic.

Wave 4 for this repo is about separating:
- public invocation shape
- runtime routing semantics
- driver implementation details

## Current Baseline

Current runtime pieces already exist:
- `services/provider-runtime`
- `adapters/provider-codex`
- `adapters/provider-claude`
- `adapters/provider-local-llm`

Current code gaps:
- `ProviderRuntime` returns a minimal `reasonCode`
- driver classes expose only `providerKey()`
- runtime-driver handshake is not explicit
- routing and fallback placement is still implied by filenames, not by types

## Interface Contract Refs

### Shared contracts
- `rather-not-work-on/platform-contracts:schemas/c4-provider-invocation.schema.json`

### provider-owned contracts
- `rather-not-work-on/platform-provider-gateway:contracts/c4-provider-invocation-artifact.schema.json`
- `rather-not-work-on/platform-provider-gateway:config/provider-reason-taxonomy.json`
- `rather-not-work-on/platform-provider-gateway:config/provider-routing.example.json`
- `rather-not-work-on/platform-provider-gateway:config/contract-pin.json`

### Governing planning contracts
- `planningops/contracts/node-workspace-bootstrap-contract.md`
- `planningops/contracts/federated-artifact-storage-contract.md`
- `planningops/contracts/implementation-readiness-gate-contract.md`

## Target Package Topology

### Public runtime surface
- `services/provider-runtime`
  - owns `ProviderInvocationPort`
  - owns routing and fallback coordination
  - owns translation between shared `C4` shape and driver-specific execution requests

### Private driver surface
- `adapters/provider-codex`
- `adapters/provider-claude`
- `adapters/provider-local-llm`

Each driver:
- implements a common `ProviderDriver` contract
- translates runtime requests into provider-specific execution calls
- returns provider-local raw outcome back to runtime for normalization

### Boundary rule
- only `services/provider-runtime` is allowed to export repo-public invocation behavior
- drivers are plugin implementations, not entrypoints

## Dependency Manifest

### Allowed imports
- `services/provider-runtime`
  - may import shared `C4` bindings
  - may import local config loaders
  - may import local `ProviderDriver` interface
  - may import driver registry/factory helpers
- `adapters/provider-*`
  - may import shared `C4` bindings
  - may import local `ProviderDriver` interface
  - must not import other drivers
  - must not import routing config directly

### Forbidden imports
- `adapters/provider-* -> config/provider-routing*`
- `adapters/provider-* -> other adapters/provider-*`
- `adapters/provider-* -> runtime artifact writing`
- `services/provider-runtime -> provider-specific env loading outside explicit driver factory`

### Cross-repo dependency rule
- `monday` may rely only on the runtime-owned invocation port exposed by this repo
- no consumer may call drivers directly

## File Plan

### Files to add
- `services/provider-runtime/src/provider_driver.ts`
- `services/provider-runtime/src/provider_registry.ts`
- `services/provider-runtime/src/provider_invocation_port.ts`
- `services/provider-runtime/src/provider_outcome.ts`
- `services/provider-runtime/src/provider_request_mapper.ts`

### Files to update
- `services/provider-runtime/src/index.ts`
- `services/provider-runtime/src/provider_port.ts`
- `services/provider-runtime/src/provider_runtime.ts`
- `adapters/provider-codex/src/index.ts`
- `adapters/provider-codex/src/driver.ts`
- `adapters/provider-claude/src/index.ts`
- `adapters/provider-claude/src/driver.ts`
- `adapters/provider-local-llm/src/index.ts`
- `adapters/provider-local-llm/src/driver.ts`
- `docs/repo-topology.md`
- `README.md`

### Explicitly deferred
- live LiteLLM process management
- provider-specific auth loading policy
- model cost accounting
- retry budget coordination with `monday`

## Verification Plan

- `pnpm -r exec tsc --noEmit`
- `python3 scripts/validate_provider_smoke_evidence.py --artifact <artifact-path>`
- `bash scripts/test_module_readmes.sh`
- `bash scripts/test_provider_smoke.sh`
- `python3 scripts/run_provider_smoke.py --scenario success`
- `python3 scripts/run_provider_smoke.py --scenario contract_violation`

Implementation is not ready if:
- drivers remain indistinguishable beyond hard-coded `providerKey()`
- runtime can route only by inspecting concrete driver class names
- `C4` request/response normalization is still split across multiple packages

## Module README Deltas

- root `README.md`
  - clarify runtime-vs-driver ownership
- `services/provider-runtime/README.md`
  - define public invocation surface, routing ownership, and forbidden responsibilities
- `adapters/provider-codex/README.md`
  - define Codex driver contract and non-goals
- `adapters/provider-claude/README.md`
  - define Claude driver contract and non-goals
- `adapters/provider-local-llm/README.md`
  - define local-LLM driver contract and non-goals
- `docs/repo-topology.md`
  - show runtime-to-driver arrows and routing ownership explicitly
