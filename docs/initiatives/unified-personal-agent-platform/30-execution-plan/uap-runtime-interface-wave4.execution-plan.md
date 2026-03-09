---
doc_id: uap-runtime-interface-wave4
title: feat: UAP Runtime Interface Wave 4 Execution Plan
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
tags:
  - uap
  - interfaces
  - runtime
  - planningops
summary: Freezes the typed runtime port and interface wiring wave that follows scaffold/build-baseline completion across monday, provider, observability, and contracts.
related_docs:
  - ../../../workbench/unified-personal-agent-platform/plans/runtime-interface-wave4-issue-pack.md
  - ./uap-runtime-skeleton-wave1-blueprint-pack.execution-plan.md
  - ../../../../planningops/contracts/node-workspace-bootstrap-contract.md
  - ../../../../planningops/contracts/control-plane-boundary-contract.md
---

# feat: UAP Runtime Interface Wave 4 Execution Plan

## Purpose

Turn the runtime skeletons from "directories and buildable packages" into "typed boundaries with fixed import direction".

Wave 4 exists because wave 2 and wave 3 already solved:
- package/service scaffolding
- local workspace bootstrap
- repo-local CI and evidence ownership

The next uncertainty is no longer file creation. The next uncertainty is whether each repo exposes the right ports so later LiteLLM, Langfuse, and worker-runtime code can land without re-cutting topology.

## Starting State

The current baseline across execution repos is:
- `monday`
  - runtime packages exist
  - orchestrator, executor, kernel, and adapters compile
  - methods still exchange placeholder inputs or inline shapes
- `platform-provider-gateway`
  - runtime service and three provider adapters exist
  - invocation request/result types are minimal
  - driver/runtime boundaries are not yet fully explicit
- `platform-observability-gateway`
  - telemetry service, replay worker, buffer, and sink exist
  - current signatures are string-based placeholders
  - ingest/buffer/sink ports are not yet fixed
- `platform-contracts`
  - current `C1` to `C5` and `C8` cover scaffold-level shared vocabulary
  - no new shared schema is yet proven necessary

## Cross-Repo Interface Freeze

### monday owns mission and run semantics
- `MissionOrchestrator` owns run creation and dependency composition.
- `SubtaskDelegator` owns mission-to-subtask planning semantics.
- `RalphLoopExecutor` owns iteration, cancellation, and result shaping.
- `monday` may call provider and observability gateways only through repo-local adapter ports.

### provider gateway owns provider dispatch semantics
- `ProviderRuntime` owns routing, adapter lookup, fallback, and normalized provider result translation.
- provider drivers expose capability-specific execution only.
- provider drivers must not own routing policy or cross-provider fallback.

### observability gateway owns ingest and replay semantics
- `TelemetryGateway` owns ingest validation and first-write decisions.
- `ReplayWorker` owns replay sequencing and retry reason handling.
- `LangfuseSink` owns sink delivery behavior only.
- sink and buffer implementations must not become the public ingest contract.

### platform-contracts stays reactive
- shared schema additions are disallowed until wave 4 repo packs prove a real cross-repo payload gap
- repo-local typed ports remain repo-local unless at least two repos need the same public envelope

## Wave 4 Deliverables

| Item | Output | Owner | Goal |
| --- | --- | --- | --- |
| `I10` | `30-execution-plan/uap-runtime-interface-wave4.execution-plan.md` | `platform-planningops` | Freeze wave ordering, evidence, and interface ownership rules |
| `I11` | `20-repos/monday/30-execution-plan/runtime-interface-wiring-pack.md` | `monday` | Freeze executor/orchestrator/kernel/adapter typed ports |
| `I12` | `20-repos/platform-provider-gateway/30-execution-plan/runtime-interface-wiring-pack.md` | `platform-provider-gateway` | Freeze runtime-driver routing interfaces |
| `I13` | `20-repos/platform-observability-gateway/30-execution-plan/runtime-interface-wiring-pack.md` | `platform-observability-gateway` | Freeze ingest/buffer/replay/sink interfaces |
| `I14` | `20-repos/platform-contracts/30-execution-plan/runtime-interface-contract-gap-matrix.md` | `platform-contracts` | Record whether new shared contracts are required |
| `I15` | `planningops/artifacts/validation/runtime-interface-wave4-readiness-report.json` | `platform-planningops` | Verify all wave 4 packs are implementation-ready |
| `I16` | `docs/workbench/unified-personal-agent-platform/plans/runtime-behavior-wave5-implementation-issue-pack.md` | `platform-planningops` | Project the next executable runtime-behavior backlog |

## Path and Evidence Rules

### Canonical docs
- cross-repo execution docs live under:
  - `docs/initiatives/unified-personal-agent-platform/30-execution-plan/`
- repo-scoped execution docs live under:
  - `docs/initiatives/unified-personal-agent-platform/20-repos/<repo>/30-execution-plan/`

### Validation evidence
- validation reports for this wave live under:
  - `planningops/artifacts/validation/`
- runtime-generated logs or trial outputs remain outside tracked Git paths unless a contract explicitly marks them as retained evidence

## Exit Criteria

Wave 4 is complete only when:
- all repo-scoped interface packs exist and validate
- the contract gap matrix explicitly says either `no gap` or `new shared contract required`
- the readiness review can project wave 5 without inventing new boundary names
- no repo-scoped file plan leaves port placement or import direction unresolved

## Replanning Triggers

Stop wave 4 and redefine before implementation if any of the following appears:
- a public port needs types not representable with existing shared contracts plus repo-local wrappers
- `monday` needs to import provider or observability concrete implementations directly
- provider drivers need cross-driver coordination logic
- observability buffer or sink must become a shared cross-repo dependency
- a new interface can only be described by changing the repo topology created in wave 2
