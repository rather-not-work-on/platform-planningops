---
title: plan: MONDAY Session and Replay Evidence Draft
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Drafts the monday-owned session state and replay evidence surfaces needed for resumable multi-agent execution without moving runtime ownership into platform-planningops.
related_docs:
  - ./2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-interface-wiring-pack.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
---

# plan: MONDAY Session and Replay Evidence Draft

## Purpose

Define the minimum monday-owned artifact surfaces required to support:

- resumable agent execution
- post-run diagnosis
- phase-aware repair loops
- stable operator evidence

This draft exists because the current gap analysis shows that MONDAY is still weak in:

- durable session state
- replay log structure
- stable execution evidence beyond one-off runtime outputs

## Boundary

The core rule is unchanged:

- `monday` owns session and replay artifacts
- `platform-planningops` may only consume stable derived evidence or readiness projections

PlanningOps must not become the storage home for active harness session state.

## Problem Statement

Without a clear session and replay model, MONDAY cannot safely support:

- interrupted execution
- bounded resume
- worker coordination across phases
- operator diagnosis after autonomous changes
- trustworthy verify/repair loops

## Required Artifact Classes

MONDAY should eventually expose at least four artifact classes.

## 1. Session State

Purpose:

- represent the current run/session snapshot
- support resume and operator inspection

Suggested path:

- `artifacts/runtime/session-state.json`

Minimum fields:

- `session_id`
- `run_id`
- `mission_id`
- `status`
- `current_phase`
- `phase_attempt`
- `attempt_budget`
- `started_at_utc`
- `updated_at_utc`
- `active_worker_roles`
- `pending_tasks`
- `completed_tasks`
- `blocked_reason`

## 2. Replay Log

Purpose:

- provide append-only execution history
- reconstruct what happened without trusting mutable in-memory state

Suggested path:

- `artifacts/runtime/replay-log.jsonl`

Minimum event fields:

- `timestamp_utc`
- `session_id`
- `run_id`
- `event_id`
- `event_type`
- `phase`
- `worker_role`
- `action`
- `artifact_ref`
- `summary`

## 3. Worker Snapshot

Purpose:

- record the latest known state of each active worker without scanning the full replay stream

Suggested path:

- `artifacts/runtime/worker-snapshot.json`

Minimum fields:

- `session_id`
- `run_id`
- `workers[]`
  - `role`
  - `state`
  - `assigned_task_id`
  - `last_event_id`
  - `updated_at_utc`

## 4. Published Evidence Bundle

Purpose:

- expose the stable post-run surface that downstream systems may inspect

Suggested path:

- `artifacts/runtime/execution-evidence-bundle.json`

Minimum fields:

- `session_id`
- `run_id`
- `final_phase`
- `final_status`
- `verification_verdict`
- `verification_report_refs`
- `replay_log_path`
- `session_state_path`
- `worker_snapshot_path`
- `output_artifact_refs`

## Artifact Relationship Model

```text
session-state.json
    ├─ references current phase + task pointers
    ├─ references worker-snapshot.json
    └─ references replay-log.jsonl

replay-log.jsonl
    └─ append-only history of transitions and worker actions

worker-snapshot.json
    └─ latest per-worker derived state

execution-evidence-bundle.json
    └─ stable published summary for operators and downstream control-plane readers
```

## Mutability Rules

## Mutable

- `session-state.json`
- `worker-snapshot.json`

These may be rewritten as the run progresses.

## Append-only

- `replay-log.jsonl`

This must never be rewritten in place except for explicit archival/compaction workflows.

## Immutable after publish

- `execution-evidence-bundle.json`

After publish, this should be treated as immutable evidence for that completed run/session.

## Phase Integration Rules

The session model must align with the team-phase contract.

Required mappings:

- `current_phase` in session state must be one of the approved phase ids
- replay events must carry the same phase id vocabulary
- verification and repair events must be distinguishable from execution events
- `publish_evidence` must freeze refs to the replay/session/snapshot surfaces used to justify completion

## Resume Rules

Resume is allowed only when:

- a readable `session-state.json` exists
- the referenced replay log exists
- `current_phase` is not terminal
- the session is not marked irrecoverably blocked

Resume must fail closed when:

- replay history is missing
- replay history contradicts session state
- worker snapshot points to unknown replay events
- the attempt budget is already exhausted

## Contradiction Rules

MONDAY should treat these mismatches as hard failures:

- `session_state.run_id != replay_event.run_id`
- `worker_snapshot.last_event_id` not present in replay stream
- `execution_evidence_bundle.session_id != session_state.session_id`
- `execution_evidence_bundle.replay_log_path` missing or unreadable

## PlanningOps Consumption Rule

PlanningOps should not consume live mutable artifacts directly.

Allowed later:

- read one published evidence bundle
- read a readiness projection derived from the evidence bundle
- read explicit validation reports derived from stable outputs

Forbidden:

- using `session-state.json` as the canonical control-plane status
- using `worker-snapshot.json` as a governance SoT
- interpreting raw replay events inside planningops business logic

## Suggested Future MONDAY-Owned Contracts

Likely candidates for `monday/contracts/`:

- `team-session-state.schema.json`
- `team-replay-event.schema.json`
- `worker-snapshot.schema.json`
- `execution-evidence-bundle.schema.json`

## Suggested Future PlanningOps-Governed Contracts

Likely candidates for `planningops/contracts/`:

- session-evidence readiness contract
- replay/evidence publication invariants
- operator-facing diagnosis contract

## Retention and Archival Direction

Recommended default behavior:

- active mutable session artifacts stay in runtime-local storage
- replay logs are archived by run/session
- published evidence bundle becomes the long-lived pointer surface

This keeps operational detail in `monday` while still exposing stable evidence upward.

## Non-Goals

- define the final storage backend
- define the final UI or CLI for replay inspection
- define all observability sink payloads
- define cross-repo artifact transport

## Promotion Path

If this draft holds, promotion should happen in two steps:

1. `monday` freezes the runtime-owned artifact schemas
2. `planningops` freezes the governance surfaces that depend on published evidence only

## Immediate Next Step

Use this draft and the team-phase draft to create one MONDAY capability contract covering:

- phase-aware session state
- replay consistency
- evidence publishing
- resume safety
