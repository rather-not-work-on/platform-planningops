---
title: plan: MONDAY Agent Harness Wave 1 Evidence Seed Packet
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Provides ready-to-file issue cards for the second MONDAY Agent harness wave1 batch, covering worker topology, tool lineage, task coordination, verification, repair, and sealed evidence publication.
tags:
  - uap
  - monday
  - harness
  - issue-seed
  - evidence
  - backlog
related_docs:
  - ./2026-03-23-monday-agent-harness-wave1-opening-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-sub-issue-decomposition.md
  - ./2026-03-23-monday-agent-harness-wave1-implementation-issue-pack.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-traceability-map.md
---

# plan: MONDAY Agent Harness Wave 1 Evidence Seed Packet

## Purpose

Provide the next ready-to-file issue cards after the opening seed packet.

This packet covers the chain that turns runtime state into trustworthy sealed evidence:

- worker topology
- tool lineage
- task coordination
- verification
- repair
- evidence publication

## Registration Order

1. `MH30A`
2. `MH30B`
3. `MH30C`
4. `MH40A`
5. `MH40B`
6. `MH40C`

## Issue Card: `MH30A`

## Planning Context
- plan_item_id: `MH30A`
- parent_pack_id: `MH30`
- target_repo: `rather-not-work-on/monday`
- component: `worker-topology`
- workflow_state: `ready-implementation`
- execution_order: `70`
- depends_on: `MH20A, MH20C`

## Problem Statement
- MONDAY cannot coordinate multi-worker execution safely because there is no explicit worker role taxonomy or deterministic assignment model.

## Output
- worker role taxonomy and task assignment model

## Interfaces and Dependencies
- `MH20A`
- `MH20C`
- `2026-03-23-monday-harness-capability-contract-draft.md`

## Acceptance Criteria
- [ ] one explicit worker role vocabulary exists for planner/implementer/verifier/repairer or equivalent monday-native roles
- [ ] task assignment resolves deterministically for the same runtime inputs
- [ ] repo-local tests cover worker role resolution and invalid assignment cases

## Definition of Done
- [ ] Repo-local tests pass
- [ ] worker roles are machine-readable and replay-compatible
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH30B`

## Planning Context
- plan_item_id: `MH30B`
- parent_pack_id: `MH30`
- target_repo: `rather-not-work-on/monday`
- component: `tool-lineage`
- workflow_state: `ready-implementation`
- execution_order: `80`
- depends_on: `MH20B, MH30A`

## Problem Statement
- MONDAY still has no auditable mutation path that ties tool actions back to worker, phase, and task lineage.

## Output
- replay events that record tool invocation lineage for mutation-capable actions

## Interfaces and Dependencies
- `MH20B`
- `MH30A`
- `2026-03-23-monday-agent-harness-reference-traceability-map.md`

## Acceptance Criteria
- [ ] every mutation-capable tool event records worker role, phase id, task id, and tool action lineage
- [ ] repo-local tests fail when required lineage fields are missing
- [ ] replay events remain append-only after lineage enrichment

## Definition of Done
- [ ] Repo-local tests pass
- [ ] tool lineage is replay-backed and not stored only in transient memory
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH30C`

## Planning Context
- plan_item_id: `MH30C`
- parent_pack_id: `MH30`
- target_repo: `rather-not-work-on/monday`
- component: `task-coordination`
- workflow_state: `ready-implementation`
- execution_order: `90`
- depends_on: `MH30A, MH30B`

## Problem Statement
- MONDAY does not yet link task receipt, execution, and completion coherently across workers, so orphan completions and unverifiable task states are possible.

## Output
- task receipt/completion linkage model integrated with worker and replay lineage

## Interfaces and Dependencies
- `MH30A`
- `MH30B`
- monday task queue or equivalent mission decomposition layer

## Acceptance Criteria
- [ ] task receipt and completion records share stable task identity
- [ ] repo-local tests catch orphan completion and double-completion cases
- [ ] task state remains attributable to worker and replay lineage

## Definition of Done
- [ ] Repo-local tests pass
- [ ] task coordination state is consistent with replay history
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH40A`

## Planning Context
- plan_item_id: `MH40A`
- parent_pack_id: `MH40`
- target_repo: `rather-not-work-on/monday`
- component: `verification`
- workflow_state: `ready-implementation`
- execution_order: `100`
- depends_on: `MH30B, MH30C`

## Problem Statement
- MONDAY cannot justify success or failure yet because verification verdicts are not emitted as one machine-readable runtime surface.

## Output
- explicit verification verdict surface with pass/fail and failure taxonomy

## Interfaces and Dependencies
- `MH30B`
- `MH30C`
- `2026-03-23-monday-team-phase-contract-draft.md`

## Acceptance Criteria
- [ ] one verification verdict surface exists for candidate outputs
- [ ] pass/fail and blocked semantics are distinguishable
- [ ] repo-local tests cover success, repairable failure, and blocked verification cases

## Definition of Done
- [ ] Repo-local tests pass
- [ ] verification semantics are machine-readable and phase-aware
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH40B`

## Planning Context
- plan_item_id: `MH40B`
- parent_pack_id: `MH40`
- target_repo: `rather-not-work-on/monday`
- component: `repair-loop`
- workflow_state: `ready-implementation`
- execution_order: `110`
- depends_on: `MH40A`

## Problem Statement
- Even with verification verdicts, MONDAY has no bounded repair accounting, so self-correction can become untracked or unbounded.

## Output
- verify-repair attempt accounting with retry budget enforcement

## Interfaces and Dependencies
- `MH40A`
- `2026-03-23-monday-session-replay-evidence-draft.md`

## Acceptance Criteria
- [ ] repair attempts increment explicit counters tied to run and phase lineage
- [ ] retry budget exhaustion fails closed
- [ ] repo-local tests cover successful repair, repeated failure, and exhausted budget cases

## Definition of Done
- [ ] Repo-local tests pass
- [ ] repair attempts are visible in runtime artifacts and replay history
- [ ] no planningops boundary violation is introduced

## Issue Card: `MH40C`

## Planning Context
- plan_item_id: `MH40C`
- parent_pack_id: `MH40`
- target_repo: `rather-not-work-on/monday`
- component: `sealed-evidence`
- workflow_state: `ready-implementation`
- execution_order: `120`
- depends_on: `MH20A, MH20B, MH20C, MH40A, MH40B`

## Problem Statement
- MONDAY still lacks one sealed evidence surface that freezes the runtime outcome and points back to the session, snapshot, replay, and verification lineage used to justify it.

## Output
- `artifacts/runtime/execution-evidence-bundle.json`

## Interfaces and Dependencies
- `MH20A`
- `MH20B`
- `MH20C`
- `MH40A`
- `MH40B`
- `2026-03-23-monday-runtime-artifact-map-draft.md`

## Acceptance Criteria
- [ ] one execution evidence bundle is published after verification or blocked termination
- [ ] the bundle references session, replay, worker snapshot, and verification lineage consistently
- [ ] repo-local tests catch contradictory lineage and missing artifact refs

## Definition of Done
- [ ] Repo-local tests pass
- [ ] the evidence bundle is immutable after publication for a run stamp
- [ ] no planningops boundary violation is introduced

## Handoff Note

After this packet, the next packet should cover:

- `MH50A`
- `MH50B`
- `MH50C`
- `MH50D`

Do not open `MH60*` planningops issues until `MH50*` shapes are stable.
