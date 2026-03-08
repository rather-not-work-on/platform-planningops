---
doc_id: uap-provider-gateway-runtime-skeleton-ready-implementation-pack
title: feat: platform-provider-gateway Runtime Skeleton Ready-Implementation Pack
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - provider
  - gateway
  - blueprint
summary: Freezes the provider gateway service and adapter topology, dependency manifest, file plan, and verification pack required before workspace scaffolding begins.
related_docs:
  - ../../../30-execution-plan/uap-runtime-skeleton-wave1-blueprint-pack.execution-plan.md
  - ../../../../../../planningops/contracts/implementation-readiness-gate-contract.md
---

# feat: platform-provider-gateway Runtime Skeleton Ready-Implementation Pack

## Purpose

Freeze the implementation blueprint for `platform-provider-gateway` before any provider runtime packages are scaffolded.

The repository already owns:
- provider invocation evidence contracts
- routing policy examples
- local smoke and launcher tooling

The next wave must add runtime packages without burying policy inside scripts or coupling the gateway directly to planningops control logic.

## Current Baseline

The current repository contains:
- `contracts/`
- `config/`
- `scripts/`
- `docs/runbook/`
- `runtime-artifacts/`

It does **not** yet contain:
- `services/provider-runtime`
- `adapters/provider-codex`
- `adapters/provider-claude`
- `adapters/provider-local-llm`
- workspace manifests for a TypeScript runtime layer

## Interface Contract Refs

### Shared contracts
- `rather-not-work-on/platform-contracts:schemas/c4-provider-invocation.schema.json`

### Repo-owned contracts and config
- `rather-not-work-on/platform-provider-gateway:contracts/c4-provider-invocation-artifact.schema.json`
- `rather-not-work-on/platform-provider-gateway:config/provider-reason-taxonomy.json`
- `rather-not-work-on/platform-provider-gateway:config/contract-pin.json`

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
- `services/provider-runtime`
- `adapters/provider-codex`
- `adapters/provider-claude`
- `adapters/provider-local-llm`

### Explicitly defer
- provider-specific cost optimization logic
- remote deployment packaging
- direct planningops-specific execution logic inside this repo

## Dependency Manifest

### Layering
1. `contracts/` and `config/`
2. `adapters/provider-codex`, `adapters/provider-claude`, `adapters/provider-local-llm`
3. `services/provider-runtime`

### Allowed dependencies
- provider adapters
  - may depend on shared/provider contract bindings
  - may depend on static config readers
  - must not import each other
  - must not implement orchestration policy
- `services/provider-runtime`
  - may depend on provider contracts
  - may depend on routing config
  - may depend on adapter packages
  - owns routing, fallback selection, and normalized invocation result mapping

### Forbidden edges
- `config/ -> services/provider-runtime`
- `scripts/ -> services/provider-runtime` as the source of architectural truth
- `services/provider-runtime -> planningops`
- `adapters/provider-* -> planningops`
- `adapters/provider-* -> runtime-artifacts/`

## File Plan

### Root additions
- `package.json`
- `pnpm-workspace.yaml`
- `tsconfig.base.json`

### Package additions
- `services/provider-runtime/package.json`
- `services/provider-runtime/src/index.ts`
- `services/provider-runtime/src/provider_runtime.ts`
- `services/provider-runtime/src/provider_port.ts`
- `services/provider-runtime/README.md`
- `adapters/provider-codex/package.json`
- `adapters/provider-codex/src/index.ts`
- `adapters/provider-codex/src/driver.ts`
- `adapters/provider-codex/README.md`
- `adapters/provider-claude/package.json`
- `adapters/provider-claude/src/index.ts`
- `adapters/provider-claude/src/driver.ts`
- `adapters/provider-claude/README.md`
- `adapters/provider-local-llm/package.json`
- `adapters/provider-local-llm/src/index.ts`
- `adapters/provider-local-llm/src/driver.ts`
- `adapters/provider-local-llm/README.md`

### Root updates
- `README.md`
- `docs/repo-topology.md`
- `contracts/README.md`
- `config/README.md`
- `scripts/README.md`
- `docs/runbook/README.md`

### Explicit non-goals for wave 2
- moving smoke scenarios out of `scripts/`
- embedding LiteLLM launch behavior inside adapter packages
- writing runtime outputs into tracked Git paths

## Verification Plan

Wave 2 implementation is not allowed to enter `ready-implementation` unless all of the following are satisfied:
- `python3 scripts/litellm_gateway_smoke.py --scenario primary_success`
- `python3 scripts/litellm_gateway_smoke.py --scenario primary_fail_fallback_success`
- `python3 scripts/validate_provider_smoke_evidence.py --report runtime-artifacts/smoke/<run-id>-primary_success.json`
- `python3 scripts/validate_contract_pin.py`
- `bash scripts/test_provider_guardrails.sh`
- `bash scripts/test_module_readmes.sh`
- workspace bootstrap check:
  - `pnpm install --frozen-lockfile=false`
  - `pnpm -r exec tsc --noEmit`

## Module README Deltas

The implementation wave must update or add:
- root `README.md` to describe the new service/adapter layer
- `services/provider-runtime/README.md`
- `adapters/provider-codex/README.md`
- `adapters/provider-claude/README.md`
- `adapters/provider-local-llm/README.md`
- `docs/repo-topology.md` to include `services/` and `adapters/` as first-class boundaries once scaffolding lands
- `scripts/README.md` to keep scripts classified as repeatable harness and launcher tooling

## Ready-Implementation Exit Criteria

This pack is sufficient for `ready-implementation` only if:
- runtime service and adapter package names are final
- routing ownership is final
- provider adapter import direction is final
- file additions are explicit
- README delta list is explicit
- no additional shared-contract change is required before scaffolding

## Working Defaults

- runtime workspace language: TypeScript on Node.js
- workspace manager: `pnpm`
- existing Python scripts remain smoke and launcher tooling in this wave
