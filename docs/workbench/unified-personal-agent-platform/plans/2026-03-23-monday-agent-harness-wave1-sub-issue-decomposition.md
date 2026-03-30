---
title: plan: MONDAY Agent Harness Wave 1 Sub-Issue Decomposition
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Breaks the MONDAY Agent Harness Wave 1 issue pack into implementation-ready sub-issues that can be registered directly in monday and later consumed by planningops promotion work.
tags:
  - uap
  - monday
  - planningops
  - harness
  - issue-decomposition
  - backlog
related_docs:
  - ./2026-03-23-monday-agent-harness-wave1-implementation-issue-pack.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ./2026-03-23-monday-session-replay-evidence-draft.md
---

# plan: MONDAY Agent Harness Wave 1 Sub-Issue Decomposition

## Goal

Convert `MH10` through `MH60` into implementation-ready sub-issues with one dominant output artifact or behavior each.

This document is the bridge between:

- design drafts
- the wave1 issue pack
- repo-local monday issue creation

## Decomposition Rules

- keep each sub-issue scoped to one dominant artifact or behavior
- keep runtime ownership inside `monday`
- do not let planningops-side work start before stable monday projections exist
- prefer testable vertical slices over abstract umbrella tasks

## Sub-Issue Matrix

| Key | Parent | Target Repo | Lane | Output | Depends On | Hard Gate |
| --- | --- | --- | --- | --- | --- | --- |
| `MH10A` | `MH10` | `rather-not-work-on/monday` | phase-contract | phase id vocabulary + transition validator | - | phase graph rejects forbidden transitions |
| `MH10B` | `MH10` | `rather-not-work-on/monday` | mission-intake | mission intake record + `run_id`/`session_id` generation | `MH10A` | stable identity survives one dry-run lifecycle |
| `MH10C` | `MH10` | `rather-not-work-on/monday` | phase-status | `team-phase-status.json` writer/reader | `MH10A`,`MH10B` | phase status stays coherent across one pass |
| `MH20A` | `MH20` | `rather-not-work-on/monday` | session-state | `session-state.json` baseline | `MH10C` | session load/save roundtrip passes |
| `MH20B` | `MH20` | `rather-not-work-on/monday` | replay-log | append-only `replay-log.jsonl` baseline | `MH10C` | replay append invariant passes |
| `MH20C` | `MH20` | `rather-not-work-on/monday` | worker-snapshot | `worker-snapshot.json` + replay pointer checks | `MH20A`,`MH20B` | snapshot points only to known events |
| `MH30A` | `MH30` | `rather-not-work-on/monday` | worker-topology | worker role taxonomy + assignment model | `MH20A`,`MH20C` | worker role resolution is deterministic |
| `MH30B` | `MH30` | `rather-not-work-on/monday` | tool-lineage | tool invocation lineage in replay events | `MH20B`,`MH30A` | every mutation-capable tool event has worker/phase/task lineage |
| `MH30C` | `MH30` | `rather-not-work-on/monday` | task-coordination | task receipt/completion linkage model | `MH30A`,`MH30B` | no orphan task completion remains |
| `MH40A` | `MH40` | `rather-not-work-on/monday` | verification | explicit verification verdict surface | `MH30B`,`MH30C` | pass/fail verdict is machine-readable |
| `MH40B` | `MH40` | `rather-not-work-on/monday` | repair-loop | bounded verify-repair attempt accounting | `MH40A` | retry budget exhaustion fails closed |
| `MH40C` | `MH40` | `rather-not-work-on/monday` | sealed-evidence | `execution-evidence-bundle.json` publication | `MH20A`,`MH20B`,`MH20C`,`MH40A`,`MH40B` | evidence bundle lineage is internally consistent |
| `MH50A` | `MH50` | `rather-not-work-on/monday` | completion-summary | `completion-summary.json` | `MH40C` | completion summary matches evidence bundle |
| `MH50B` | `MH50` | `rather-not-work-on/monday` | readiness-projection | `readiness-projection.json` | `MH40C` | ready/blocked semantics are coherent |
| `MH50C` | `MH50` | `rather-not-work-on/monday` | verification-projection | `verification-projection.json` | `MH40C` | verification projection matches verification lineage |
| `MH50D` | `MH50` | `rather-not-work-on/monday` | handoff-projection | `operator-handoff-summary.json` | `MH40C` | blocked runs emit actionable handoff data |
| `MH60A` | `MH60` | `rather-not-work-on/platform-planningops` | contract-candidate | promoted projection contract candidate | `MH50A`,`MH50B`,`MH50C`,`MH50D` | contract reads projections only |
| `MH60B` | `MH60` | `rather-not-work-on/platform-planningops` | gate-design | doctor/gate issue draft for readiness consumption | `MH60A` | gate inputs exclude runtime-private artifacts |

## Suggested Registration Order

1. `MH10A -> MH10B -> MH10C`
2. `MH20A` and `MH20B` in parallel after `MH10C`
3. `MH20C`
4. `MH30A -> MH30B -> MH30C`
5. `MH40A -> MH40B -> MH40C`
6. `MH50A`,`MH50B`,`MH50C`,`MH50D` in parallel
7. `MH60A -> MH60B`

## Repo Ownership Split

### monday-only

These sub-issues belong only in `monday`:

- `MH10A` to `MH50D`

### planningops-later

These sub-issues belong only in `platform-planningops`:

- `MH60A`
- `MH60B`

The split is deliberate. `MH60*` must not be opened as active implementation work until `MH50*` artifacts are stable.

## Issue Card Template

Use this skeleton when registering monday or planningops issues:

```markdown
## Planning Context
- plan_item_id: `<KEY>`
- parent_pack_id: `MH10|MH20|MH30|MH40|MH50|MH60`
- target_repo: `<owner/repo>`
- component: `<component>`
- workflow_state: `<ready-implementation|ready-contract|backlog>`
- execution_order: `<number>`
- depends_on: `<keys>`

## Problem Statement
- <single dominant problem>

## Output
- <artifact path or behavior surface>

## Interfaces and Dependencies
- <contracts, runtime surfaces, or sibling issues>

## Acceptance Criteria
- [ ] <artifact exists or behavior is implemented>
- [ ] <machine-readable validation path exists>
- [ ] <repo-local tests cover the dominant failure mode>

## Definition of Done
- [ ] Repo-local tests pass
- [ ] Evidence artifact or projection is emitted
- [ ] No planningops boundary violation is introduced
```

## Immediate Seed-Issue Candidates

If only three issues are opened first, open these:

1. `MH10A` because everything else depends on explicit phase vocabulary
2. `MH20B` because replay lineage is the backbone of later evidence
3. `MH40C` only after prerequisites exist, because sealed evidence is the first control-plane bridge

## Stop Conditions

Stop decomposition-driven implementation when:

- monday artifact filenames are still changing weekly
- verification semantics are not yet agreed
- projections are being derived from mutable state rather than sealed evidence

At that point, update the issue pack first instead of opening more sub-issues.
