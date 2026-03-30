---
title: plan: MONDAY Agent Memory Wave A Kickoff Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the first monday runtime-memory implementation wave to the existing TypeScript workspace and Python validation harness, with concrete file targets, PR slices, and acceptance gates.
related_docs:
  - ./2026-03-25-monday-agent-memory-implementation-priority-memo.md
  - ./2026-03-25-monday-agent-memory-implementation-spec-and-wbs.md
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
---

# plan: MONDAY Agent Memory Wave A Kickoff Packet

## Purpose

Convert the memory spec and WBS into a first execution packet that matches the actual `monday` repo shape.

This packet is intentionally narrower than the full memory program:

- implement only `W01-W04`
- stay inside the existing `monday` repo and workspace
- do not start compaction workers, retrieval ranking, or background consolidation yet

## Repo Reality

The current `monday` repo is not a blank slate.

It already has:

- a TypeScript workspace under `packages/*`
- repo-owned contract bindings in `packages/contract-bindings`
- runtime orchestration code in `packages/orchestrator`
- a Python validation and smoke harness under `scripts/`
- canonical local evidence under `runtime-artifacts/`
- canonical harness artifacts under `runtime-artifacts/agent-harness/`

That means Wave A should fit this structure rather than inventing a separate service.

## Stack Pin

Wave A should use the existing `monday` stack:

- TypeScript workspace for core runtime interfaces and domain models
- Python scripts only for validation and smoke helpers where that pattern already exists
- repo-local artifact output under `runtime-artifacts/`
- swappable storage interfaces, but no mandatory live Postgres dependency in the first PR

Do not:

- create a new Kotlin or Spring service
- create a second standalone memory repo
- move runtime ownership into `platform-planningops`

## Existing Surfaces To Reuse

Wave A should build on these existing files:

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/contract-bindings/src/agent_harness.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/src/agent_harness_runtime.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/docs/runbook/agent-harness-wave1-kickoff.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/README.md`

The memory baseline should extend the existing harness vocabulary instead of replacing it.

## Wave A Scope

Wave A covers only:

- `W01` Repo Bootstrap
- `W02` Schema Design
- `W03` Domain Models
- `W04` Repository Layer

Wave A explicitly does not cover:

- retrieval engine behavior
- candidate promotion logic
- compaction workers
- background consolidation jobs
- end-to-end memory-aware answer generation

## Target Package Layout

Recommended placement inside `monday`:

### `packages/contract-bindings`

Add memory-facing shared contracts:

- `src/agent_memory.ts`
- exported type unions and document interfaces
- storage contract enums
- lineage metadata types

This package should define:

- memory types
- scope keys
- version and supersede metadata
- repository-facing DTO shapes

### `packages/orchestrator`

Add runtime-memory interfaces and first concrete local implementations:

- `src/agent_memory_store.ts`
- `src/agent_memory_models.ts`
- `src/agent_memory_paths.ts`
- `src/agent_memory_local_store.ts`

This package should define:

- exact store interfaces
- semantic store interfaces
- artifact store interfaces
- local file-backed or fixture-backed implementations sufficient for deterministic tests

### `scripts/`

Add validation or smoke helpers only if needed for the new storage contract:

- avoid building business logic primarily in Python
- prefer TypeScript for runtime behavior and Python only for validation glue already consistent with repo patterns

### `runtime-artifacts/`

Do not commit runtime outputs.

If Wave A needs local smoke outputs, keep them under:

- `runtime-artifacts/agent-harness/`
- `runtime-artifacts/validation/`
- `/tmp`

## Wave A Data Contract

The first wave should define these memory documents, but implementations may be local and thin:

- `SessionMemory`
- `UserProfileStable`
- `UserProfileVolatile`
- `ProjectState`
- `Task`
- `OpenLoop`
- `Decision`
- `KnowledgeChunk`
- `SummaryMemory`
- `ToolLog`
- `ArtifactRef`
- `WorkflowExample`

Every mutable memory type must carry:

- `sourceRefs`
- `confidence`
- `version`
- `supersedesId`
- `validFrom`
- `validTo`
- `createdAtUtc`
- `updatedAtUtc`

## Recommended PR Split

### PR 1: `W01`

Goal:

- introduce the memory package and export boundaries without storage behavior

Changes:

- add `agent_memory.ts` contracts in `packages/contract-bindings`
- wire exports
- add package README notes if needed

Done when:

- typecheck passes
- memory contracts are importable from `packages/orchestrator`

### PR 2: `W02`

Goal:

- pin the schema and persistence contract even if the first backend is local-only

Changes:

- add schema documentation for exact and semantic records
- add migration or schema-stub plan for future relational backend
- define on-disk layout or local fixture shape for deterministic testing

Done when:

- storage schema decisions are documented
- test fixtures can serialize every Wave A memory type

### PR 3: `W03`

Goal:

- add domain models and validation helpers

Changes:

- DTOs
- validation functions
- constructors and guards for lineage metadata

Done when:

- malformed memory payloads fail closed
- valid sample payloads compile and validate

### PR 4: `W04`

Goal:

- add repository interfaces and first concrete implementations

Changes:

- `append`, `get`, `list`, `upsert`, `supersede`, and typed search interfaces
- deterministic local implementations
- integration-style tests around scope isolation and supersede behavior

Done when:

- repositories can persist and read all Wave A memory types in tests
- supersede behavior preserves lineage rather than overwriting blindly

## Acceptance Gates

Wave A should be considered complete only if these conditions hold.

### Contract Gate

- new memory contracts compile and export cleanly
- existing harness contracts remain backward-compatible

### Repository Gate

- scope isolation works across `tenant_id`, `user_id`, `project_id`, and `thread_id`
- writes are idempotent where repeated callbacks are expected
- supersede behavior preserves prior record lineage

### Runtime Ownership Gate

- no `platform-planningops` runtime mutation path is introduced
- no control-plane code becomes the primary storage owner

### Debuggability Gate

- memory mutations are structured and inspectable in tests
- failure cases are machine-readable

## Suggested Test Additions

Add new tests near the existing `monday` validation style.

TypeScript-side:

- package-level unit tests for memory DTO validation
- repository integration tests for scope and supersede behavior

Shell or smoke-side:

- one regression entrypoint that proves the new memory package can seed deterministic local records

Wave A does not need a live database smoke.

## Stop Conditions

Pause and rescope if any of these appear during Wave A:

- Codex starts introducing retrieval ranking logic before repository interfaces are stable
- storage implementation depends on a live external service before local tests exist
- memory contracts duplicate the existing `agent_harness` identity fields inconsistently
- `planningops` starts reading mutable runtime memory as control-plane truth

## Codex Prompt For Wave A

Use this instead of the generic memory prompt when opening the first `monday` implementation PR.

```text
Implement monday runtime-memory Wave A inside the existing monday repo.

Use the current repo shape:
- TypeScript workspace under packages/*
- contract surface in packages/contract-bindings
- runtime implementations in packages/orchestrator
- Python only for validation glue where the repo already uses it

Implement only:
- W01 Repo Bootstrap
- W02 Schema Design
- W03 Domain Models
- W04 Repository Layer

Target files and packages:
- packages/contract-bindings/src/agent_memory.ts
- packages/orchestrator/src/agent_memory_models.ts
- packages/orchestrator/src/agent_memory_store.ts
- packages/orchestrator/src/agent_memory_paths.ts
- packages/orchestrator/src/agent_memory_local_store.ts

Required memory types:
- SessionMemory
- UserProfileStable
- UserProfileVolatile
- ProjectState
- Task
- OpenLoop
- Decision
- KnowledgeChunk
- SummaryMemory
- ToolLog
- ArtifactRef
- WorkflowExample

Hard constraints:
- keep run_id, session_id, mission_id semantics aligned with existing agent_harness contracts
- preserve lineage metadata everywhere
- no silent overwrite of corrected memory
- no new service language or framework
- no live database dependency required in the first wave
- tests must cover scope isolation, idempotent writes, and supersede behavior

Deliverables:
- memory contract types
- domain models and validators
- repository interfaces
- deterministic local store implementation
- tests
- README or runbook notes documenting Wave A storage decisions

Do not implement retrieval ranking, compaction workers, promotion jobs, or background consolidation yet.
```

## Next Step After Wave A

Only after Wave A is merged should the next packet open:

- retrieval contract implementation
- exact-first context packing
- candidate-write and promote rules

That keeps the memory rollout aligned with the existing `monday` harness progression instead of creating a second parallel runtime.
