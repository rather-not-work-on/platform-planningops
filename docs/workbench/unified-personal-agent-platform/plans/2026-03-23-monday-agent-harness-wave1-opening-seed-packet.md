---
title: plan: MONDAY Agent Harness Wave 1 Opening Seed Packet
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Provides ready-to-file opening issue cards for the first monday-owned MONDAY Agent harness wave so implementation can begin from the highest-leverage dependency chain.
tags:
  - uap
  - monday
  - harness
  - issue-seed
  - backlog
related_docs:
  - ./2026-03-23-monday-agent-harness-wave1-implementation-issue-pack.md
  - ./2026-03-23-monday-agent-harness-wave1-sub-issue-decomposition.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ./2026-03-23-monday-session-replay-evidence-draft.md
  - ./2026-03-23-monday-harness-capability-contract-draft.md
---

# plan: MONDAY Agent Harness Wave 1 Opening Seed Packet

## Purpose

Turn the first wave of monday harness work into issue cards that can be registered immediately.

This packet intentionally covers only the opening dependency chain:

- phase vocabulary
- mission and run identity
- team-phase status
- session state
- replay log
- worker snapshot

Later cards should be generated from the sub-issue decomposition only after this opening chain is accepted.

## Registration Order

1. `MH10A`
2. `MH10B`
3. `MH10C`
4. `MH20A`
5. `MH20B`
6. `MH20C`

## Issue Card: `MH10A`

## Planning Context
- plan_item_id: `MH10A`
- parent_pack_id: `MH10`
- target_repo: `rather-not-work-on/monday`
- component: `phase-contract`
- workflow_state: `ready-implementation`
- execution_order: `10`
- depends_on: `-`

## Problem Statement
- MONDAY does not yet have one machine-readable team-phase vocabulary and transition validator, so later runtime artifacts cannot encode stable lifecycle semantics.

## Output
- phase id vocabulary and transition validator for `clarify -> plan -> design -> execute -> verify -> repair -> publish_evidence -> done`

## Interfaces and Dependencies
- `2026-03-23-monday-team-phase-contract-draft.md`
- monday runtime phase executor or equivalent orchestration layer

## Acceptance Criteria
- [ ] one canonical phase id set exists in monday runtime code
- [ ] forbidden shortcuts such as `execute -> done` fail closed
- [ ] repo-local tests cover valid and invalid transition graphs

## Definition of Done
- [ ] Repo-local tests pass
- [ ] transition validation is machine-readable, not prompt-only
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH10B`

## Planning Context
- plan_item_id: `MH10B`
- parent_pack_id: `MH10`
- target_repo: `rather-not-work-on/monday`
- component: `mission-intake`
- workflow_state: `ready-implementation`
- execution_order: `20`
- depends_on: `MH10A`

## Problem Statement
- MONDAY lacks a stable mission intake record with deterministic `run_id` and `session_id`, so replay, evidence, and projection artifacts cannot share one reliable lineage root.

## Output
- mission intake record surface with `mission_id`, `run_id`, `session_id`, and autonomy classification

## Interfaces and Dependencies
- `MH10A`
- `2026-03-23-monday-harness-capability-contract-draft.md`
- monday mission entrypoint and runtime startup path

## Acceptance Criteria
- [ ] one mission intake surface emits stable identifiers before phase execution starts
- [ ] one dry-run lifecycle preserves the same identifiers across phase transitions
- [ ] repo-local tests cover identity generation and propagation

## Definition of Done
- [ ] Repo-local tests pass
- [ ] mission/run/session identity is emitted before mutable runtime artifacts are written
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH10C`

## Planning Context
- plan_item_id: `MH10C`
- parent_pack_id: `MH10`
- target_repo: `rather-not-work-on/monday`
- component: `phase-status`
- workflow_state: `ready-implementation`
- execution_order: `30`
- depends_on: `MH10A, MH10B`

## Problem Statement
- Even with phase ids and stable run identity, MONDAY still lacks a runtime-owned team-phase status artifact that operators and later artifact writers can read consistently.

## Output
- `artifacts/runtime/team-phase-status.json` writer and reader

## Interfaces and Dependencies
- `MH10A`
- `MH10B`
- `2026-03-23-monday-runtime-artifact-map-draft.md`

## Acceptance Criteria
- [ ] one phase status artifact is emitted and updated coherently through a dry-run lifecycle
- [ ] the artifact carries `run_id`, `session_id`, current phase, and transition timestamp data
- [ ] repo-local tests cover phase status consistency and forbidden transition handling

## Definition of Done
- [ ] Repo-local tests pass
- [ ] `team-phase-status.json` is runtime-owned and not projected as planningops truth
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH20A`

## Planning Context
- plan_item_id: `MH20A`
- parent_pack_id: `MH20`
- target_repo: `rather-not-work-on/monday`
- component: `session-state`
- workflow_state: `ready-implementation`
- execution_order: `40`
- depends_on: `MH10C`

## Problem Statement
- MONDAY cannot resume or diagnose interrupted runs safely because there is no runtime-owned session state artifact with explicit phase, task, and attempt information.

## Output
- `artifacts/runtime/session-state.json`

## Interfaces and Dependencies
- `MH10C`
- `2026-03-23-monday-session-replay-evidence-draft.md`
- `2026-03-23-monday-runtime-artifact-map-draft.md`

## Acceptance Criteria
- [ ] one session state artifact records `run_id`, `session_id`, current phase, attempt budget, and task pointers
- [ ] session load/save roundtrip passes without losing identity or phase state
- [ ] repo-local tests cover resumable and blocked session cases

## Definition of Done
- [ ] Repo-local tests pass
- [ ] `session-state.json` is treated as mutable runtime state only
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH20B`

## Planning Context
- plan_item_id: `MH20B`
- parent_pack_id: `MH20`
- target_repo: `rather-not-work-on/monday`
- component: `replay-log`
- workflow_state: `ready-implementation`
- execution_order: `50`
- depends_on: `MH10C`

## Problem Statement
- MONDAY has no append-only replay backbone, so later evidence bundles and projections would have to trust mutable state instead of auditable history.

## Output
- `artifacts/runtime/replay-log.jsonl`

## Interfaces and Dependencies
- `MH10C`
- `2026-03-23-monday-session-replay-evidence-draft.md`
- `2026-03-23-monday-agent-harness-reference-traceability-map.md`

## Acceptance Criteria
- [ ] one append-only replay log records phase transitions and runtime events with `run_id` lineage
- [ ] replay append invariants are enforced by repo-local tests
- [ ] replay events are attributable to phase and action type even before worker topology is fully implemented

## Definition of Done
- [ ] Repo-local tests pass
- [ ] replay history is append-only and not silently rewritten
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH20C`

## Planning Context
- plan_item_id: `MH20C`
- parent_pack_id: `MH20`
- target_repo: `rather-not-work-on/monday`
- component: `worker-snapshot`
- workflow_state: `ready-implementation`
- execution_order: `60`
- depends_on: `MH20A, MH20B`

## Problem Statement
- MONDAY still lacks a compact worker state surface that points back to replay lineage, making runtime inspection expensive and contradiction detection weak.

## Output
- `artifacts/runtime/worker-snapshot.json`

## Interfaces and Dependencies
- `MH20A`
- `MH20B`
- `2026-03-23-monday-runtime-artifact-map-draft.md`

## Acceptance Criteria
- [ ] one worker snapshot artifact records latest worker state and last replay event reference
- [ ] snapshot-to-replay pointer validation fails closed on unknown event ids
- [ ] repo-local tests cover valid and contradictory worker snapshot cases

## Definition of Done
- [ ] Repo-local tests pass
- [ ] `worker-snapshot.json` never points to unknown replay events
- [ ] no planningops boundary violation is introduced

## Handoff Note

After these six issues are registered, the next packet should cover:

- `MH30A`
- `MH30B`
- `MH30C`
- `MH40A`
- `MH40B`
- `MH40C`

Do not open `MH60*` planningops issues yet.
