---
title: plan: MONDAY Runtime Artifact Map Draft
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Maps monday-owned runtime artifacts by class, mutability, lineage, and control-plane visibility so harness implementation can proceed without blurring runtime and planningops responsibilities.
related_docs:
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ./2026-03-23-monday-session-replay-evidence-draft.md
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ./2026-03-23-monday-agent-harness-wave1-implementation-issue-pack.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
---

# plan: MONDAY Runtime Artifact Map Draft

## Purpose

Define one runtime artifact taxonomy for `monday` so implementation work can distinguish:

- live runtime state
- append-only replay data
- sealed evidence
- planningops-facing derived projections

## Boundary

Artifact ownership is split by function, not by convenience.

- `monday` owns all runtime artifacts
- `planningops` may consume only the derived projections and later validation outputs

No runtime artifact in this map should become control-plane truth just because it is easy to read.

## Artifact Classes

MONDAY runtime artifacts should fall into four classes.

## 1. Live Runtime State

Purpose:

- represent the current execution snapshot
- support resume and runtime coordination

Suggested artifacts:

- `artifacts/runtime/session-state.json`
- `artifacts/runtime/worker-snapshot.json`
- `artifacts/runtime/team-phase-status.json`

Mutability:

- mutable

PlanningOps visibility:

- forbidden as canonical input

## 2. Append-Only Replay Surfaces

Purpose:

- preserve action lineage and transition history

Suggested artifacts:

- `artifacts/runtime/replay-log.jsonl`
- `artifacts/runtime/team-phase-transitions.jsonl`

Mutability:

- append-only

PlanningOps visibility:

- indirect only through sealed evidence or projection refs

## 3. Sealed Evidence Surfaces

Purpose:

- justify final or blocked outcomes with stable references

Suggested artifacts:

- `artifacts/runtime/execution-evidence-bundle.json`
- `artifacts/runtime/completion-summary.json`

Mutability:

- immutable after publication

PlanningOps visibility:

- allowed

## 4. Derived Control-Plane Projections

Purpose:

- present narrow, stable summaries for control-plane validation

Suggested artifacts:

- `artifacts/runtime/readiness-projection.json`
- `artifacts/runtime/verification-projection.json`
- `artifacts/runtime/operator-handoff-summary.json`

Mutability:

- immutable after publication for the same run stamp

PlanningOps visibility:

- allowed

## Ownership and Residency Table

| Artifact | Owner | Class | Mutability | Primary Consumer |
| --- | --- | --- | --- | --- |
| `session-state.json` | `monday` | live runtime state | mutable | runtime resume logic |
| `worker-snapshot.json` | `monday` | live runtime state | mutable | runtime operator/debug path |
| `team-phase-status.json` | `monday` | live runtime state | mutable | runtime orchestration |
| `replay-log.jsonl` | `monday` | append-only replay | append-only | runtime diagnosis and evidence publication |
| `team-phase-transitions.jsonl` | `monday` | append-only replay | append-only | runtime phase audit |
| `execution-evidence-bundle.json` | `monday` | sealed evidence | immutable | operators and downstream projections |
| `completion-summary.json` | `monday` | sealed evidence | immutable | operators and planningops gates |
| `readiness-projection.json` | `monday` | derived projection | immutable | planningops readiness path |
| `verification-projection.json` | `monday` | derived projection | immutable | planningops validation path |
| `operator-handoff-summary.json` | `monday` | derived projection | immutable | planningops/operator blocked path |

## Required Lineage Rules

Every artifact published after `execute` should be attributable to:

- one `run_id`
- one `session_id`
- one current or final phase
- one evidence lineage chain

At minimum:

- projections must point to sealed evidence
- sealed evidence must point to replay/session/snapshot surfaces
- replay events must point to worker/task/tool lineage where applicable

## Visibility Rules

### Runtime-Private

These stay runtime-private even if stored on disk:

- live task queues
- in-process worker scratchpads
- partial reasoning buffers
- prompt assembly internals

### Operator-Visible

These may be operator-visible:

- completion summary
- evidence bundle
- operator handoff summary

### PlanningOps-Visible

These are the only target surfaces planningops should later validate:

- completion summary
- readiness projection
- verification projection
- operator handoff summary

## Mutability and Promotion Rules

- mutable artifacts may change while the run is active
- append-only artifacts may only grow
- sealed evidence may not be rewritten once published for a run stamp
- derived projections may be regenerated only as a new stamped publication, not silently rewritten in place with contradictory content

## Anti-Patterns

The implementation should reject these patterns:

- using `session-state.json` as a readiness gate input
- deriving `ready=true` from replay history without sealed evidence
- publishing projections that do not carry stable run lineage
- mixing mutable runtime state and sealed evidence in one file
- letting planningops schemas reach into monday-private artifacts

## Suggested Directory Shape

```text
artifacts/runtime/
  session-state.json
  worker-snapshot.json
  team-phase-status.json
  replay-log.jsonl
  team-phase-transitions.jsonl
  execution-evidence-bundle.json
  completion-summary.json
  readiness-projection.json
  verification-projection.json
  operator-handoff-summary.json
```

Optional stamped publication shape:

```text
artifacts/runtime/history/<run_id>/
  session-state.json
  worker-snapshot.json
  replay-log.jsonl
  execution-evidence-bundle.json
  readiness-projection.json
```

## Immediate Next Steps

Use this map to:

1. scope `MH20`, `MH40`, and `MH50` implementation boundaries
2. define monday-side artifact naming and residency rules
3. keep future planningops contracts limited to projection surfaces only
