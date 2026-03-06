---
title: plan: Control Tower Ontology Memory and Federation Migration
type: plan
date: 2026-03-05
updated: 2026-03-05
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines a validated rollout to keep planningops as SoT/control tower, split core vs federation boundaries, migrate execution ownership to external repos, and operate 3-tier memory compaction.
---

# plan: Control Tower Ontology Memory and Federation Migration

## Overview
This plan validates and applies a single operating model:

1. `platform-planningops` is the org-level SoT + control tower (not a runtime implementation sink).
2. `planningops + Codex` acts as a meta-agent that designs and governs execution.
3. `monday` is the runtime execution agent.
4. `platform-contracts`, `platform-provider-gateway`, `platform-observability-gateway` are infrastructure/runtime execution repositories.
5. planningops must operate as a living ontology + memory system that links all repos while continuously compacting noise.

## Research Consolidation
### Current State (2026-03-05)
- `planningops/scripts/issue_loop_runner.py` is large (`1892` lines) and mixes orchestration, lock/watchdog, selection, execution, and feedback concerns.
- `planningops/scripts/repo_execution_adapters.py` is still colocated at scripts root with `issue_loop_runner` import coupling.
- cross-repo federation entrypoints were moved to `planningops/scripts/federation/` with root wrappers preserved.
- one-off split began with `planningops/scripts/oneoff/bootstrap_two_track_backlog.py` and root compatibility wrapper.
- quality gates now exist for issue quality and script roles.

### Open Cross-Repo Issues
- planningops tracker: `platform-planningops#92`
- contracts: `platform-contracts#1`
- provider: `platform-provider-gateway#1`
- observability: `platform-observability-gateway#1`
- runtime: `monday#2`

## Problem Statement
Despite recent boundary improvements, three strategic gaps remain:

1. `issue_loop_runner` + adapter layer is still too monolithic for long-term core/federation separation.
2. wrapper compatibility paths exist but deprecation timeline is not formalized.
3. memory lifecycle (capture -> distill -> archive -> rehydrate) is not yet contract-backed as a first-class operating loop.

## Goals
1. Split loop runtime into stable **core** modules and explicit **federation** boundary modules.
2. Publish wrapper deprecation timeline and enforce staged removal gates.
3. Lock cross-repo responsibility migration as issue-backed workstream with deterministic handoff evidence.
4. Introduce 3-tier memory architecture (L0/L1/L2) with compaction triggers and archive manifest.

## Non-Goals
- Rebuilding monday runtime internals in planningops.
- Introducing new project tracker tooling beyond GitHub Issues/Project in this phase.
- Full automated archive storage backend migration in one step.

## Ontology Model (Canonical Semantics)
### Entity Types
- `Initiative`: top-level strategic scope.
- `PlanItem`: execution unit with dependencies.
- `Contract`: normative interface/policy source.
- `RuntimeArtifact`: execution evidence emitted by runs.
- `RepositoryRole`: control-plane or execution-plane ownership.
- `MemoryRecord`: summarized/archived knowledge unit.

### Core Relations
- `Initiative contains PlanItem`
- `PlanItem references Contract`
- `PlanItem targets RepositoryRole`
- `Execution emits RuntimeArtifact`
- `MemoryRecord compacts PlanItem/Artifact history`

### Path Policy
- canonical knowledge: `docs/initiatives/**`, `planningops/contracts/**`, `planningops/adr/**`, `planningops/config/**`
- active working memory: `docs/workbench/**`, `planningops/artifacts/**`, open issues/todos
- federation runtime entrypoints: `planningops/scripts/federation/**`
- one-off scripts: `planningops/scripts/oneoff/**`

## Proposed Solution
## A. `issue_loop_runner` / adapter Core vs Federation Split
### Target Module Map
- `planningops/scripts/core/loop/selection.py`
- `planningops/scripts/core/loop/checkpoint_lock.py`
- `planningops/scripts/core/loop/replan_escalation.py`
- `planningops/scripts/core/loop/feedback_projection.py`
- `planningops/scripts/core/loop/runner.py`
- `planningops/scripts/federation/adapter_registry.py`
- `planningops/scripts/federation/adapter_hooks.py`
- `planningops/scripts/issue_loop_runner.py` (compat entrypoint wrapper)

### Separation Rule
- `core/*` cannot import repo-specific execution logic.
- `federation/*` can map repos to adapter implementations but cannot own core selection/lock policy.

## B. Wrapper Deprecation Timeline
### Timeline
1. `T0 (now)`: wrappers remain, emit no-op compatibility.
2. `T+14 days`: wrappers emit deprecation warning artifact (`planningops/artifacts/deprecation/*.json`).
3. `T+30 days`: CI fails new references to wrapper paths in docs/scripts.
4. `T+60 days`: wrappers removed after all call-sites moved.

### Initial Wrapper Scope
- `planningops/scripts/issue_loop_runner.py` (future wrapper after core split)
- `planningops/scripts/repo_execution_adapters.py` (future wrapper after federation registry split)
- existing wrapper set in federation/oneoff maps.

## C. Cross-Repo Responsibility Migration
### Responsibility Ledger
- contracts repo owns schema evolution + contract bundle publication evidence.
- provider repo owns provider smoke/runtime-profile evidence contracts.
- observability repo owns replay/backfill evidence contracts.
- monday repo owns handoff/scheduler runtime boundary contracts.
- planningops owns orchestration contracts, ontology links, and verification gates only.

### Issue-Driven Migration Chain
1. Execute `platform-contracts#1` -> publish pin/version artifact format.
2. Execute `platform-provider-gateway#1` + `platform-observability-gateway#1` -> align smoke/replay artifacts.
3. Execute `monday#2` -> lock handoff/scheduler evidence contract.
4. Reconcile all outputs in `platform-planningops#92`.

## D. 3-Tier Memory + Compaction Loop
### Memory Tiers
1. `L0 Short` (active): `docs/workbench/**`, `planningops/artifacts/**`, open issues/todos; TTL 7-14 days.
2. `L1 Mid` (operational canonical): contracts/ADR/config/canonical docs; quarterly retention + versioned updates.
3. `L2 Long` (archive): `docs/archive/**` + `planningops/archive-manifest/**` pointer/index.

### Compaction Loop
1. Capture (`L0`)
2. Validate (tests/contracts)
3. Distill (`core-summary` markdown)
4. Promote (`L1`) or Archive (`L2`)
5. Rehydrate on demand via archive manifest pointer

### Required New Artifacts
- `planningops/contracts/memory-tier-contract.md`
- `planningops/config/memory-tier-rules.json`
- `planningops/scripts/memory_compactor.py`
- `planningops/scripts/memory_archive.py`
- `planningops/scripts/memory_rehydrate.py`
- `planningops/scripts/test_memory_tier_contract.sh`

## SpecFlow Analysis
### Primary Flow
1. planner defines or updates plan item in planningops.
2. loop runner selects scoped item through core modules.
3. federation adapter delegates repo-specific execution hooks.
4. execution repo emits evidence artifacts.
5. planningops validates and links artifacts to ontology records.
6. memory compactor condenses stale L0 records to L1/L2.

### Edge Cases
- missing repo evidence schema -> block promotion to `done`.
- deprecation wrapper referenced by new code after `T+30` -> CI fail.
- L0 stale docs without compacted target -> CI fail (`stale_l0_uncompacted`).
- duplicated workbench topics >=3 without summary -> CI fail (`topic_compaction_required`).

## Implementation Phases
## Phase 0: Model Lock and Contracts (P0)
### Deliverables
- `planningops/contracts/control-tower-ontology-contract.md`
- `planningops/contracts/memory-tier-contract.md`
- `planningops/config/memory-tier-rules.json`
- update `planningops/contracts/control-plane-boundary-contract.md` with wrapper timeline

### Validation
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
- contract lint checks added to federated CI.

## Phase 1: Runner Core/Federation Split (P1)
### Deliverables
- extract `issue_loop_runner` modules into `scripts/core/loop/*`
- move adapter registry/hooks to `scripts/federation/*`
- keep `issue_loop_runner.py` and `repo_execution_adapters.py` as compatibility wrappers
- add tests:
  - `planningops/scripts/test_issue_loop_runner_core_contract.sh`
  - `planningops/scripts/test_federation_adapter_registry_contract.sh`

### Validation
- existing loop tests + new module boundary tests
- `test_validate_repo_boundaries_contract.sh` + script-role checks pass.

## Phase 2: Wrapper Deprecation Enforcement (P1)
### Deliverables
- `planningops/config/wrapper-deprecation-map.json`
- `planningops/scripts/validate_wrapper_deprecation.py`
- `planningops/scripts/test_validate_wrapper_deprecation_contract.sh`
- CI gate for new wrapper references after deprecation start date.

### Validation
- fail PRs adding legacy wrapper paths outside allowed compatibility matrix.

## Phase 3: Cross-Repo Responsibility Transfer (P1)
### Deliverables
- close or advance:
  - `platform-contracts#1`
  - `platform-provider-gateway#1`
  - `platform-observability-gateway#1`
  - `monday#2`
- update `platform-planningops#92` with evidence links and status sync.

### Validation
- `python3 planningops/scripts/federation/cross_repo_conformance_check.py --run-id migration-check`
- federated CI matrix pass on PR and main.

## Phase 4: Memory Compaction System (P2)
### Deliverables
- implement `memory_compactor.py`, `memory_archive.py`, `memory_rehydrate.py`
- add frontmatter keys:
  - `memory_tier`
  - `expires_on`
  - `compacted_into`
  - `archive_ref`
- add validators:
  - stale L0 detection
  - duplicate topic compaction trigger
  - missing summary/evidence close-block rule for completed issues

### Validation
- `bash planningops/scripts/test_memory_tier_contract.sh`
- `python3 planningops/scripts/memory_compactor.py --mode check --strict`

## Backlog Issue Split (with Dependencies)
1. `PO-CT-001` (planningops): Runner core/federation extraction scaffold
- depends_on: none
- files: `planningops/scripts/core/loop/*.py`, `planningops/scripts/federation/adapter_*.py`

2. `PO-CT-002` (planningops): Wrapper deprecation governance + CI gate
- depends_on: `PO-CT-001`
- files: `planningops/config/wrapper-deprecation-map.json`, `planningops/scripts/validate_wrapper_deprecation.py`

3. `PO-CT-003` (planningops): Memory tier contract + compaction scripts
- depends_on: `PO-CT-001`
- files: `planningops/contracts/memory-tier-contract.md`, `planningops/scripts/memory_*.py`

4. `PO-CT-004` (cross-repo): Responsibility transfer reconciliation tracker
- depends_on: `platform-contracts#1`, `platform-provider-gateway#1`, `platform-observability-gateway#1`, `monday#2`
- tracker: `platform-planningops#92`

## Acceptance Criteria
### Architecture
- [ ] `issue_loop_runner` concerns are split into core modules with explicit boundaries.
- [ ] adapter logic is isolated under federation modules.
- [ ] no new runtime implementation logic is added to planningops outside control-plane scope.

### Governance
- [ ] wrapper deprecation timeline is codified and CI-enforced.
- [ ] all cross-repo responsibility issues are linked and actively reconciled from planningops tracker.

### Memory
- [ ] L0/L1/L2 tiers are contract-defined and machine-validated.
- [ ] stale L0 artifacts cannot accumulate silently.
- [ ] archive manifest enables deterministic rehydrate flow.

## Success Metrics
- `planningops_runtime_impl_new_files = 0` (outside allowed boundary dirs)
- `wrapper_reference_new_count = 0` after deprecation gate start
- `cross_repo_responsibility_issue_link_rate = 100%`
- `stale_l0_uncompacted_count = 0` on main
- `workbench_topic_duplicate_without_summary_count = 0`

## Risks and Mitigations
1. Risk: over-fragmentation of runner modules may reduce maintainability.
- Mitigation: split by stable concerns only; keep orchestration facade module.

2. Risk: aggressive wrapper deprecation may break automation scripts.
- Mitigation: two-stage gate (`warn -> fail`) and compatibility map allowlist.

3. Risk: memory compaction may archive useful context prematurely.
- Mitigation: require `core-summary` before archive and keep `rehydrate` command path.

## Execution Commands (Initial)
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
bash planningops/scripts/test_validate_repo_boundaries_contract.sh
bash planningops/scripts/test_validate_script_roles_contract.sh
bash planningops/scripts/test_validate_issue_quality_contract.sh
python3 planningops/scripts/validate_issue_quality.py --strict
python3 planningops/scripts/federation/cross_repo_conformance_check.py --run-id pre-migration-baseline
```

## Immediate Next Step
- Convert `PO-CT-001~004` into GitHub issues (or project items) with explicit dependency links, then start Phase 0 contract lock before any additional runtime coding.
