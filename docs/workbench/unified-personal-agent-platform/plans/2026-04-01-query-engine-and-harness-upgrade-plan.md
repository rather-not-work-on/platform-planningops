---
title: plan: Query Engine and Harness Upgrade Plan
type: plan
date: 2026-04-01
updated: 2026-04-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines a repo-specific upgrade plan for the planningops query engine and harness surfaces using public clean-room harness research patterns rather than exposed proprietary source.
related_docs:
  - ./2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ./2026-03-23-monday-agent-harness-projection-contract-candidate.md
  - ./2026-03-14-autonomous-scheduler-queue-control-plane-plan.md
---

# plan: Query Engine and Harness Upgrade Plan

## Guardrail

This plan does not rely on exposed proprietary source. It uses only:

- publicly available clean-room harness research and rewrite patterns
- current `planningops` contracts, scripts, fixtures, and artifact families

The external reference is useful mainly because it shows a thin query surface, explicit session/config state, and a CLI-shaped runtime shell. We should reuse those ideas, not the original leaked implementation lineage.

## Why This Plan Exists

`planningops` already has the raw ingredients of a strong runtime control plane:

- stamped federated CI artifacts
- tmp checkpoint reconciliation
- monday harness projection contracts
- doctor/gate/validate script families
- scheduler and provider readiness surfaces

What it lacks is a coherent internal split between:

- a read-side query engine for indexing, selecting, and diagnosing artifact state
- a write-side harness runtime for running checks, checkpointing, reconciling, and emitting artifacts

Right now those concerns are mixed across many one-off scripts and deep ladder families, especially in:

- `planningops/scripts/federation/federated_ci_summary.py`
- `planningops/scripts/federation/reconcile_federated_ci_summary_tmp.py`
- `planningops/contracts/federated-ci-summary-contract.md`
- `planningops/contracts/monday-agent-harness-projection-contract.md`

## Current Problems

### 1. Query logic is distributed instead of modeled

We can reconstruct artifact state, but only by knowing which script family and which file shape to call. There is no first-class query model for:

- run family
- run id
- check domain
- lifecycle status
- latest vs stamped
- checkpoint vs finalized state

### 2. Harness lifecycle is implemented as script choreography

The current system behaves like a harness but does not expose a common harness abstraction. The result is duplicated logic around:

- check registration
- required check bookkeeping
- failure classification
- tmp checkpoint restoration
- status promotion
- stamped vs latest write rules

### 3. Projection ladders are over-specialized

The monday projection family shows a strong contract discipline, but the recursive `status-bundle-status-bundle...` ladder is too literal. The system needs a generic recursive engine rather than another round of suffix-specific scripts.

### 4. Operator visibility is file-path aware instead of intent aware

We can inspect artifacts if we already know their family, naming rule, and storage layout. We cannot yet ask higher-level questions like:

- what is the latest broken federated family by domain?
- which checks were restored from tmp instead of completed cleanly?
- which monday projection ladder node is the highest healthy materialized surface?
- which artifact bundles are pass-complete but missing readiness sidecars by contract?

## External Patterns Worth Adopting

From the public clean-room reference, the useful ideas are:

- a thin query engine object with explicit config
- session-aware state with transcript compaction and persistence hooks
- CLI-first read surface for summary, manifest, routing, and loop modes
- explicit separation between inventory building and runtime submission

For `planningops`, that translates into:

- one typed query layer over our artifact and contract inventories
- one typed harness layer over our check and checkpoint lifecycle
- one CLI surface that exposes both in a predictable way

## Target Architecture

## Query Engine V2

Introduce a read-side engine that materializes a typed artifact index instead of forcing callers to know file naming by hand.

Core objects:

- `ArtifactRecord`
  - family, run_id, lane, domain, check_name, status, verdict, timestamps, paths
- `CheckpointRecord`
  - tmp file path, stamped file path, latest file path, restore status, reconcile count
- `ProjectionRecord`
  - contract family, ladder depth, canonical source, resolved output, validation output
- `RunQuery`
  - filters over family, date, verdict, status, domain, health, and restoration state

Capabilities:

- enumerate run families
- resolve latest stamped bundle for a family
- diff tmp checkpoint against finalized summary
- answer health questions over contracts and harness outputs
- render JSON, Markdown, and compact terminal summaries from the same query result

Proposed CLI surface:

- `python3 planningops/scripts/query_engine.py runs --family federated-ci-runtime-gates`
- `python3 planningops/scripts/query_engine.py checks --run-id federated-ci-runtime-gates-20260319-rerun26`
- `python3 planningops/scripts/query_engine.py reconcile-status --summary <path> --checkpoint <path>`
- `python3 planningops/scripts/query_engine.py projection-health --family monday-agent-harness`

## Harness Runtime V2

Introduce a write-side harness core that makes check execution and artifact emission explicit.

Core objects:

- `RunSpec`
  - run id, family, required checks, deterministic routing rule, output roots
- `CheckSpec`
  - name, domain, producer command, expected artifacts, failure semantics
- `RunState`
  - initialized, running, interrupted, restored, complete, failed
- `CheckpointState`
  - tmp payload, stamped payload, latest payload, reconcile report
- `ArtifactWritePlan`
  - what gets written to tmp, stamped, latest, validation, and conformance trees

Capabilities:

- initialize a run from a single spec
- append checks through a shared state machine
- finalize with one verdict computation path
- reconcile tmp state as a first-class recovery mode
- emit validation reports and conformance outputs from one contract-aware writer

## Query Engine Workstreams

### QE-1. Artifact Catalog

Build a cataloger that scans:

- `planningops/artifacts/ci`
- `planningops/artifacts/validation`
- `planningops/artifacts/conformance`
- `runtime-artifacts/agent-harness`

and returns typed records rather than path strings.

Deliverables:

- `planningops/scripts/query_engine.py`
- `planningops/query_engine/models.py`
- fixture-backed catalog tests

### QE-2. Query DSL and CLI

Standardize filters and projections:

- by family
- by run id
- by domain
- by status/verdict
- by restored vs clean-complete
- by contract family

Deliverables:

- stable CLI subcommands
- JSON output mode for automation
- Markdown summary mode for workbench packets and audits

### QE-3. Diagnostic Views

Add operator-grade reports for:

- interrupted or restored runs
- missing required checks
- drift between stamped and latest
- projection ladder depth and health
- backlog of unresolved tmp reconciliations

## Harness Workstreams

### H-1. Common Run State Model

Refactor `federated_ci_summary.py` around reusable runtime objects instead of subcommand-local dictionaries.

Immediate goal:

- move verdict, failure classification, missing check logic, and stamped/latest writes behind a common runtime core

### H-2. First-Class Checkpoint Reconcile

Absorb `reconcile_federated_ci_summary_tmp.py` into the harness state machine.

Immediate goal:

- represent tmp reconciliation as a run transition, not as an auxiliary one-off script

This should produce:

- consistent restore reports
- consistent restored check accounting
- one contract for healthy vs restored vs interrupted vs failed runs

### H-3. Projection Ladder Collapse

Replace suffix-specific projection ladders with one generic recursive projection engine.

Instead of separate script families for each ladder suffix, model:

- projection input artifact
- nesting depth
- schema pair
- resolve function
- validate function
- doctor/gate rules

Immediate goal:

- stop generating more `status-bundle-status-bundle...` scripts
- move current families behind one parameterized engine

### H-4. Unified Doctor/Gate Surface

Create one harness doctor/gate framework that runs over specs.

Target commands:

- `python3 planningops/scripts/harness_doctor.py --family federated-ci-runtime-gates --require-pass`
- `bash planningops/scripts/harness_gate.sh --family monday-agent-harness-projection`

This lets us keep the contract rigor without preserving the current script explosion.

## Recommended Rollout Order

### Phase 0. Inventory Freeze

- freeze current federated CI and monday harness families as baseline fixtures
- tag which script families are canonical, legacy, or generated debt
- define the minimal schema every queryable artifact must expose

### Phase 1. Query Engine Read Side

- build the catalog and query CLI without changing producers
- use current artifact trees as-is
- prove that operator questions can be answered without path-specific knowledge

### Phase 2. Federated CI Harness Core

- refactor federated CI summary/finalize/reconcile onto `RunSpec` and `RunState`
- keep output files backward compatible
- switch tests from script-shape assertions to state-model assertions where possible

### Phase 3. Monday Projection Generalization

- replace ladder-specific resolver/validator generation with one recursive engine
- preserve current output paths until compatibility gates pass

### Phase 4. Cross-Family Operator Shell

- expose one top-level operator surface for query, diagnose, and gate workflows
- make workbench packet generation depend on query views instead of path-specific manual archaeology

## Success Criteria

- a new engineer can answer common artifact health questions through query commands alone
- federated CI finalize and tmp reconcile share one runtime state model
- monday harness projection no longer requires suffix-specific script multiplication
- new harness families can be declared mostly from specs instead of copied script skeletons
- workbench packet generation becomes read-side automation over typed artifact records

## Risks

- over-abstracting too early and breaking stable artifact contracts
- replacing script families without preserving current file names and gate expectations
- mixing read-side query concerns into write-side harness execution again

## Guardrails

- keep stamped artifact names backward compatible during the whole rollout
- preserve current schema validation checkpoints until the new runtime core proves parity
- migrate federated CI first, then projection ladders, not both at once
- do not expand the projection ladder family further before the generic engine lands

## First Execution Packet After This Plan

The first implementation packet should target only two things:

- query-side artifact catalog and CLI for federated CI families
- harness-side extraction of common run/finalize/reconcile state from federated CI summary scripts

That gives us the highest leverage with the lowest migration risk.
