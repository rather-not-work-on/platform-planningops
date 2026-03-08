---
doc_id: uap-monday-runtime-skeleton-ready-implementation-pack
title: feat: monday Runtime Skeleton Ready-Implementation Pack
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
  - blueprint
summary: Freezes the monday runtime package topology, dependency manifest, file plan, and verification pack required before workspace scaffolding begins.
related_docs:
  - ./2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ../20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
  - ../../../30-execution-plan/uap-runtime-skeleton-wave1-blueprint-pack.execution-plan.md
  - ../../../../../../planningops/contracts/implementation-readiness-gate-contract.md
---

# feat: monday Runtime Skeleton Ready-Implementation Pack

## Purpose

Freeze the implementation blueprint for the `monday` runtime before any package workspace or scaffold code is added.

This pack is intentionally design-first:
- current Python validation harness remains in place
- new runtime packages are introduced as a separate workspace layer
- import direction and contract ownership are fixed before file creation

## Current Baseline

The current `monday` repository contains:
- `contracts/`
- `config/`
- `scripts/`
- `docs/adr/`
- `docs/runbook/`
- `runtime-artifacts/`

It does **not** yet contain:
- `packages/`
- `apps/`
- workspace manifests for a TypeScript runtime skeleton

The immediate consequence is that wave 2 must add runtime packages without collapsing existing Python validation tooling into application logic.

## Interface Contract Refs

### Shared contracts
- `rather-not-work-on/platform-contracts:schemas/c1-run-lifecycle.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c2-subtask-handoff.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c3-executor-result.schema.json`
- `rather-not-work-on/platform-contracts:schemas/c8-plan-to-github-projection.schema.json`

### monday-owned contracts
- `rather-not-work-on/monday:contracts/executor-worker-handoff-map.json`
- `rather-not-work-on/monday:contracts/runtime-handoff-evidence.schema.json`
- `rather-not-work-on/monday:contracts/runtime-scheduler-evidence.schema.json`
- `rather-not-work-on/monday:contracts/runtime-integration-evidence.schema.json`

### Governing planning contracts
- `planningops/contracts/implementation-readiness-gate-contract.md`
- `planningops/contracts/control-plane-boundary-contract.md`

## Target Package Topology

### Keep as-is in wave 2
- `contracts/`
- `config/`
- `scripts/`
- `docs/adr/`
- `docs/runbook/`
- `runtime-artifacts/`

### Add in wave 2
- `packages/contract-bindings`
- `packages/agent-kernel`
- `packages/executor-ralph-loop`
- `packages/orchestrator`
- `packages/provider-client-adapter`
- `packages/o11y-client-adapter`
- `packages/messaging-adapter`

### Explicitly defer
- `apps/control-plane`
- executor Rust split
- messaging provider-specific adapters beyond the first runtime boundary

## Dependency Manifest

### Layering
1. `contract-bindings`
2. `agent-kernel`, `provider-client-adapter`, `o11y-client-adapter`, `messaging-adapter`
3. `executor-ralph-loop`
4. `orchestrator`

### Allowed dependencies
- `contract-bindings`
  - may depend on generated/shared schema consumers only
  - must not depend on runtime packages
- `agent-kernel`
  - may depend on `contract-bindings`
  - must not depend on provider implementation details
- `provider-client-adapter`
  - may depend on `contract-bindings`
  - may call `platform-provider-gateway`
  - must not contain orchestration policy
- `o11y-client-adapter`
  - may depend on `contract-bindings`
  - may call `platform-observability-gateway`
  - must not own replay policy
- `messaging-adapter`
  - may depend on `contract-bindings`
  - must not create run state
- `executor-ralph-loop`
  - may depend on `contract-bindings`
  - may depend on `provider-client-adapter`
  - may depend on `o11y-client-adapter`
  - must not depend on `orchestrator`
- `orchestrator`
  - may depend on `contract-bindings`
  - may depend on `agent-kernel`
  - may depend on `executor-ralph-loop`
  - may depend on `messaging-adapter`
  - must not interpret executor internal state beyond shared contracts

### Forbidden edges
- `orchestrator -> provider-client-adapter`
- `orchestrator -> o11y-client-adapter`
- `agent-kernel -> provider implementation`
- `messaging-adapter -> executor-ralph-loop`
- `scripts/ -> packages/*` as a source of architectural truth

## File Plan

### Root additions
- `package.json`
- `pnpm-workspace.yaml`
- `tsconfig.base.json`

### Package additions
- `packages/contract-bindings/package.json`
- `packages/contract-bindings/src/index.ts`
- `packages/contract-bindings/README.md`
- `packages/agent-kernel/package.json`
- `packages/agent-kernel/src/index.ts`
- `packages/agent-kernel/src/subtask_delegator.ts`
- `packages/agent-kernel/README.md`
- `packages/executor-ralph-loop/package.json`
- `packages/executor-ralph-loop/src/index.ts`
- `packages/executor-ralph-loop/src/ralph_loop_executor.ts`
- `packages/executor-ralph-loop/README.md`
- `packages/orchestrator/package.json`
- `packages/orchestrator/src/index.ts`
- `packages/orchestrator/src/mission_orchestrator.ts`
- `packages/orchestrator/README.md`
- `packages/provider-client-adapter/package.json`
- `packages/provider-client-adapter/src/index.ts`
- `packages/provider-client-adapter/src/provider_client.ts`
- `packages/provider-client-adapter/README.md`
- `packages/o11y-client-adapter/package.json`
- `packages/o11y-client-adapter/src/index.ts`
- `packages/o11y-client-adapter/src/timeline_emitter_client.ts`
- `packages/o11y-client-adapter/README.md`
- `packages/messaging-adapter/package.json`
- `packages/messaging-adapter/src/index.ts`
- `packages/messaging-adapter/README.md`

### Root updates
- `README.md`
- `docs/repo-topology.md`
- `contracts/README.md`
- `config/README.md`
- `scripts/README.md`

### Explicit non-goals for wave 2
- moving existing Python validation scripts into package runtime code
- generating runtime artifacts into tracked Git paths
- adding control-plane UI/app code

## Verification Plan

Wave 2 implementation is not allowed to enter `ready-implementation` unless all of the following are satisfied:
- `python3 scripts/validate_handoff_mapping.py`
- `python3 scripts/integrate_planningops_handoff.py --run-id <run-id>`
- `bash scripts/test_scheduler_queue.sh`
- `python3 scripts/validate_contract_pin.py`
- `bash scripts/test_contract_pin_validation.sh`
- `bash scripts/test_module_readmes.sh`
- workspace bootstrap check:
  - `pnpm install --frozen-lockfile=false`
  - `pnpm -r exec tsc --noEmit`

## Module README Deltas

The implementation wave must update or add:
- root `README.md` to describe the new workspace layer and keep Python scripts classified as validation tooling
- `packages/*/README.md` for every added runtime package
- `docs/repo-topology.md` to include `packages/` as a first-class boundary once scaffolding lands
- `scripts/README.md` to clarify that scripts remain harnesses, not runtime source

## Ready-Implementation Exit Criteria

This pack is sufficient for `ready-implementation` only if:
- package names are final
- dependency direction is final
- root workspace tooling choice is final
- file additions are explicit
- README delta list is explicit
- no additional shared-contract decision is required to start scaffolding

## Working Defaults

- runtime workspace language: TypeScript on Node.js
- workspace manager: `pnpm`
- current Python scripts stay repo-local and are not rewritten in this wave
