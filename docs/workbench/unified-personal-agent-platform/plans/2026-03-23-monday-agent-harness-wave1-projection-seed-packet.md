---
title: plan: MONDAY Agent Harness Wave 1 Projection Seed Packet
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Provides ready-to-file issue cards for monday projection publication and the follow-on planningops contract/gate work that should begin only after monday runtime artifact shapes stabilize.
tags:
  - uap
  - monday
  - planningops
  - harness
  - projection
  - issue-seed
  - backlog
related_docs:
  - ./2026-03-23-monday-agent-harness-wave1-evidence-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-sub-issue-decomposition.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-traceability-map.md
---

# plan: MONDAY Agent Harness Wave 1 Projection Seed Packet

## Purpose

Provide the closing wave1 issue cards:

- monday-side projection publication
- planningops-side contract and gate preparation

This packet must start only after `MH40C` is stable.

## Registration Order

1. `MH50A`
2. `MH50B`
3. `MH50C`
4. `MH50D`
5. `MH60A`
6. `MH60B`

## Start Condition

Do not start this packet until:

- `execution-evidence-bundle.json` exists
- evidence lineage is stable across repeated runs
- monday artifact names are no longer drifting weekly

## Issue Card: `MH50A`

## Planning Context
- plan_item_id: `MH50A`
- parent_pack_id: `MH50`
- target_repo: `rather-not-work-on/monday`
- component: `completion-summary`
- workflow_state: `ready-implementation`
- execution_order: `130`
- depends_on: `MH40C`

## Problem Statement
- MONDAY still lacks one stable terminal summary that operators and downstream systems can read without understanding all runtime-private artifacts.

## Output
- `artifacts/runtime/completion-summary.json`

## Interfaces and Dependencies
- `MH40C`
- `2026-03-23-monday-planningops-evidence-projection-contract-draft.md`

## Acceptance Criteria
- [ ] one completion summary is published per run stamp
- [ ] the summary agrees with the execution evidence bundle on `run_id`, `session_id`, phase, and final status
- [ ] repo-local tests catch contradictory completion metadata

## Definition of Done
- [ ] Repo-local tests pass
- [ ] completion summary is immutable after publication for a run stamp
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH50B`

## Planning Context
- plan_item_id: `MH50B`
- parent_pack_id: `MH50`
- target_repo: `rather-not-work-on/monday`
- component: `readiness-projection`
- workflow_state: `ready-implementation`
- execution_order: `140`
- depends_on: `MH40C`

## Problem Statement
- MONDAY has no narrow readiness surface that a control plane could eventually validate without reading runtime-private state.

## Output
- `artifacts/runtime/readiness-projection.json`

## Interfaces and Dependencies
- `MH40C`
- `2026-03-23-monday-planningops-evidence-projection-contract-draft.md`

## Acceptance Criteria
- [ ] readiness projection is derived from sealed evidence only
- [ ] `ready`, `blocked`, and `not_ready` semantics are explicit and non-contradictory
- [ ] repo-local tests fail when readiness claims disagree with evidence lineage

## Definition of Done
- [ ] Repo-local tests pass
- [ ] readiness projection does not read mutable runtime state directly
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH50C`

## Planning Context
- plan_item_id: `MH50C`
- parent_pack_id: `MH50`
- target_repo: `rather-not-work-on/monday`
- component: `verification-projection`
- workflow_state: `ready-implementation`
- execution_order: `150`
- depends_on: `MH40C`

## Problem Statement
- MONDAY still lacks a stable surface summarizing verification outcomes in a way that downstream gates could eventually consume.

## Output
- `artifacts/runtime/verification-projection.json`

## Interfaces and Dependencies
- `MH40C`
- `MH50A`
- `2026-03-23-monday-planningops-evidence-projection-contract-draft.md`

## Acceptance Criteria
- [ ] verification projection summarizes verdict, failed checks, and repair attempts coherently
- [ ] the projection points back to sealed evidence or stable verification refs
- [ ] repo-local tests catch verdict drift between evidence bundle and verification projection

## Definition of Done
- [ ] Repo-local tests pass
- [ ] verification projection is stable enough for downstream validation
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH50D`

## Planning Context
- plan_item_id: `MH50D`
- parent_pack_id: `MH50`
- target_repo: `rather-not-work-on/monday`
- component: `handoff-projection`
- workflow_state: `ready-implementation`
- execution_order: `160`
- depends_on: `MH40C`

## Problem Statement
- Blocked or user-gated runs still need one stable operator handoff surface instead of ad hoc runtime messages.

## Output
- `artifacts/runtime/operator-handoff-summary.json`

## Interfaces and Dependencies
- `MH40C`
- `2026-03-23-monday-agent-harness-reference-traceability-map.md`

## Acceptance Criteria
- [ ] blocked or user-gated runs emit actionable handoff data
- [ ] handoff summaries never claim ready/complete semantics for blocked runs
- [ ] repo-local tests cover missing-question, user-gated, and blocked-runtime cases

## Definition of Done
- [ ] Repo-local tests pass
- [ ] operator handoff summary is evidence-backed and non-contradictory
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH60A`

## Planning Context
- plan_item_id: `MH60A`
- parent_pack_id: `MH60`
- target_repo: `rather-not-work-on/platform-planningops`
- component: `contract-candidate`
- workflow_state: `ready-contract`
- execution_order: `170`
- depends_on: `MH50A, MH50B, MH50C, MH50D`

## Problem Statement
- PlanningOps cannot safely validate monday outcomes until one promoted contract candidate exists that reads projection surfaces only.

## Output
- promoted projection contract candidate

## Interfaces and Dependencies
- `MH50A`
- `MH50B`
- `MH50C`
- `MH50D`
- `2026-03-23-monday-planningops-evidence-projection-contract-draft.md`

## Acceptance Criteria
- [ ] the contract candidate names only completion summary and projection surfaces
- [ ] no mutable monday runtime artifact is treated as control-plane truth
- [ ] repo-local contract checks cover lineage, freshness, and contradiction rules

## Definition of Done
- [ ] Repo-local tests pass
- [ ] the contract candidate reads projections only
- [ ] no planningops/runtime ownership collapse is introduced

## Issue Card: `MH60B`

## Planning Context
- plan_item_id: `MH60B`
- parent_pack_id: `MH60`
- target_repo: `rather-not-work-on/platform-planningops`
- component: `gate-design`
- workflow_state: `backlog`
- execution_order: `180`
- depends_on: `MH60A`

## Problem Statement
- Even with a contract candidate, PlanningOps still needs an explicit doctor/gate issue draft so readiness consumption can be introduced without ad hoc expansion.

## Output
- doctor/gate issue draft for readiness consumption

## Interfaces and Dependencies
- `MH60A`
- planningops federated doctor/gate conventions

## Acceptance Criteria
- [ ] one issue draft exists for doctor/gate introduction over monday projections
- [ ] gate inputs exclude runtime-private artifacts by construction
- [ ] repo-local tests or contract docs define the intended gate boundary

## Definition of Done
- [ ] Repo-local tests or docs pass
- [ ] the draft remains projection-only
- [ ] no planningops/runtime ownership collapse is introduced

## Close-Out Note

Once this packet is complete, wave1 planning should be considered fully seeded.

The next step after that is no longer planning depth. It is execution in `monday`, followed by shape-stability checks before promoting any planningops-side gate.
