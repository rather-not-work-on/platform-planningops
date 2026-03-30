---
title: plan: MONDAY Harness Capability Contract Draft
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the monday-owned agent harness capability boundary that combines staged execution, worker orchestration, session persistence, replay evidence, and planningops-facing projections.
related_docs:
  - ./2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ./2026-03-23-monday-session-replay-evidence-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-interface-wiring-pack.md
---

# plan: MONDAY Harness Capability Contract Draft

## Purpose

Define the minimum capability contract that `monday` should eventually satisfy as the execution-plane agent harness for the unified personal agent platform.

This draft combines the previously separated workbench drafts into one higher-order contract surface:

- staged team-phase execution
- worker orchestration
- session persistence
- replay and evidence publication
- operator control
- planningops-facing derived projections

## Core Boundary

The boundary remains strict:

- `monday` owns runtime behavior
- `platform-planningops` owns governance, readiness, and control-plane validation

Therefore:

- MONDAY must implement the machine
- PlanningOps must define the protocol
- PlanningOps must not become a hidden runtime harness

## Design Principle

The harness contract should be:

- reference-informed, not vendor-imported
- phase-aware, not prompt-only
- evidence-first, not assertion-first
- resumable, not fire-and-forget
- operator-legible, not opaque

## Capability Families

MONDAY should expose nine capability families.

## 1. Mission Intake and Task Classification

Purpose:

- normalize incoming user intent
- classify execution risk
- determine whether autonomous execution is allowed

Minimum expectations:

- stable mission identifier
- risk classification
- user-gated boundary detection
- explicit execution mode selection

Required outputs:

- mission record
- assumptions list
- autonomy classification

## 2. Team-Phase Execution Lifecycle

Purpose:

- drive complex work through one bounded lifecycle

Default required phases:

1. `clarify`
2. `plan`
3. `design`
4. `execute`
5. `verify`
6. `repair`
7. `publish_evidence`
8. `done`

Contract rule:

- phase transitions must be machine-readable
- forbidden shortcuts must fail closed
- completion without verification is invalid

## 3. Worker Topology and Coordination

Purpose:

- allow multiple workers or roles to collaborate without losing responsibility boundaries

Minimum expectations:

- explicit worker role taxonomy
- task assignment surface
- per-worker state reporting
- bounded retry and reassignment semantics

Suggested role families:

- planner
- implementer
- verifier
- repairer
- operator-advisor

## 4. Tool Routing and Execution Discipline

Purpose:

- let workers act through auditable tool surfaces rather than hidden free-form mutation

Minimum expectations:

- tool invocation records in replay history
- clear success/failure status per tool action
- tool-level artifact references
- refusal path when a requested action crosses policy boundaries

Contract rule:

- nontrivial repo mutation must be attributable to a worker, a phase, and a tool call lineage

## 5. Session State Persistence

Purpose:

- support resume, diagnosis, and operator inspection

Minimum artifacts:

- `session-state.json`
- `worker-snapshot.json`

Required fields include:

- `session_id`
- `run_id`
- `mission_id`
- `current_phase`
- `status`
- `attempt_budget`
- `active_worker_roles`

Contract rule:

- live session state is monday-owned runtime data, not planningops state

## 6. Replay Log and Evidence Publication

Purpose:

- reconstruct what happened
- justify why the system believes the run is complete or blocked

Minimum artifacts:

- `replay-log.jsonl`
- `execution-evidence-bundle.json`

Contract rule:

- replay must be append-only
- published evidence must be immutable after publication
- evidence must point back to replay/session/snapshot surfaces

## 7. Verification and Repair Loop

Purpose:

- enforce evidence-backed completion
- support bounded self-correction

Minimum expectations:

- explicit verification verdicts
- failure taxonomy
- repair attempt accounting
- stop condition when retry budget is exhausted

Contract rule:

- `verify -> repair -> verify` loop is allowed
- `execute -> done` is forbidden

## 8. Operator Control and Intervention

Purpose:

- keep the system inspectable and interruptible by humans

Minimum expectations:

- readable status summary
- blocked-state explanation
- resume eligibility signal
- explicit handoff surface when autonomy stops

Operator controls should eventually support:

- inspect
- pause
- resume
- abort
- publish current evidence

## 9. PlanningOps-Facing Derived Projections

Purpose:

- expose stable derived surfaces that the control plane may validate

Allowed PlanningOps consumption:

- published evidence bundle
- readiness projection
- contract validation reports
- explicit status summaries derived from immutable or sealed outputs

Forbidden PlanningOps consumption:

- raw mutable session state as canonical status
- direct orchestration of worker internals
- runtime memory ownership

## Capability Mapping to Reference Sources

The external references should guide implementation patterns, not ownership.

| Capability family | Best reference | Adoption mode |
| --- | --- | --- |
| mission intake and runtime composition | `oh-my-openagent` | adapt |
| staged team lifecycle | `oh-my-claudecode` | adapt |
| codex-native runtime ergonomics | `oh-my-codex` | defer/selective adapt |
| session and replay discipline | `oh-my-openagent` | adapt |
| operator-facing evidence surfaces | mixed | reimplement |

## Required Failure Semantics

MONDAY should fail closed when:

- phase transition lineage is missing
- replay history contradicts session state
- worker state points at unknown task or event ids
- verification evidence is missing for a claimed success
- published evidence does not match the run being reported

The harness should stop and escalate instead of silently continuing.

## Non-Goals

This contract does not require PlanningOps to:

- host runtime worker sessions
- own prompt templates for monday internals
- store mutable monday memory
- decide intra-run worker scheduling

This contract also does not require MONDAY to copy upstream reference projects structurally.

## Promotion Path

The likely promotion order is:

1. promote the phase contract into monday-owned canonical docs
2. promote the session/replay artifact contract into monday-owned canonical docs
3. promote one control-plane-facing evidence projection contract into PlanningOps
4. implement validation gates only after runtime artifact ownership is stable

## Immediate Next Steps

Use this draft to create:

1. a monday-side capability matrix with `must / should / later`
2. a monday runtime artifact taxonomy doc
3. a planningops-facing evidence projection contract
4. an issue pack for phased harness implementation
