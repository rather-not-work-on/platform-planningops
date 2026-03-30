---
title: plan: MONDAY PlanningOps Evidence Projection Contract Draft
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the derived evidence surfaces that monday may publish for planningops consumption without transferring agent harness ownership into the control plane.
related_docs:
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ./2026-03-23-monday-session-replay-evidence-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
---

# plan: MONDAY PlanningOps Evidence Projection Contract Draft

## Purpose

Define the narrow set of monday-published evidence projections that `platform-planningops` may consume as control-plane inputs.

This draft exists to preserve the boundary:

- `monday` owns runtime state
- `planningops` consumes only sealed or derived evidence

## Boundary Rule

PlanningOps may validate and gate only stable projections.

PlanningOps must not directly consume:

- mutable session state
- mutable worker snapshots
- internal prompt memory
- in-flight task queues
- runtime-private orchestration metadata

## Source of Truth Model

The source of truth for runtime behavior remains inside `monday`.

The source of truth for control-plane readiness remains inside `planningops`.

The bridge between them should be one small projection layer published by `monday`.

## Allowed Projection Surfaces

MONDAY should eventually publish four control-plane-facing projections.

## 1. Completion Summary

Purpose:

- provide one stable machine-readable statement of terminal run outcome

Suggested path:

- `artifacts/runtime/completion-summary.json`

Minimum fields:

- `run_id`
- `session_id`
- `mission_id`
- `final_phase`
- `final_status`
- `verification_verdict`
- `completed_at_utc`
- `evidence_bundle_path`

## 2. Readiness Projection

Purpose:

- expose whether the run is usable for downstream automation or operator promotion

Suggested path:

- `artifacts/runtime/readiness-projection.json`

Minimum fields:

- `run_id`
- `readiness_status`
- `reason`
- `blocking_conditions`
- `required_evidence_refs`
- `generated_at_utc`

## 3. Verification Projection

Purpose:

- summarize whether declared success criteria were actually checked

Suggested path:

- `artifacts/runtime/verification-projection.json`

Minimum fields:

- `run_id`
- `verification_verdict`
- `verification_report_refs`
- `failed_checks`
- `repair_attempts`
- `generated_at_utc`

## 4. Operator Handoff Summary

Purpose:

- make blocked or user-gated stops legible to the control plane and operators

Suggested path:

- `artifacts/runtime/operator-handoff-summary.json`

Minimum fields:

- `run_id`
- `handoff_status`
- `handoff_reason`
- `next_required_actor`
- `recommended_next_step`
- `blocking_question_set`
- `generated_at_utc`

## Projection Derivation Rules

Each projection must be derived from monday-owned evidence, not invented independently.

Allowed sources:

- `execution-evidence-bundle.json`
- sealed verification outputs
- replay-backed completion metadata

Forbidden sources:

- live worker memory only
- transient in-process state
- unlogged prompt text with no artifact lineage

## Projection Quality Rules

Each projection must be:

- machine-readable
- immutable after publication for the same run stamp
- attributable to exactly one `run_id`
- internally self-consistent
- reproducible from published evidence

## PlanningOps Validation Rule

PlanningOps may validate:

- field presence
- lineage consistency
- freshness
- verdict/readiness coherence
- path existence for referenced stable artifacts

PlanningOps must not validate:

- monday-internal scheduling heuristics
- prompt wording choices
- worker-private scratchpad contents

## Required Cross-Projection Invariants

These must agree across all projections for the same run:

- `run_id`
- `session_id` when present
- `verification_verdict`
- readiness vs blocking semantics

Examples of hard failures:

- `completion-summary.final_status=complete` but `verification-projection.verification_verdict=fail`
- `readiness_status=ready` while `operator-handoff-summary.handoff_status=required`
- `evidence_bundle_path` missing or unreadable

## Ownership Split

`monday` owns:

- projection generation
- evidence lineage
- artifact publication

`planningops` owns:

- schemas for control-plane gates, if promoted
- doctor/gate semantics over published projections
- readiness and promotion policy

## Promotion Strategy

Recommended order:

1. implement projections in monday docs as runtime-owned outputs
2. stabilize field sets and filenames
3. promote one planningops-side contract for readiness consumption
4. add planningops doctor/gate only after repeated runtime shape stability

## Immediate Next Steps

Use this draft to create:

1. a monday runtime artifact map that includes projection outputs
2. one planningops-side readiness contract candidate
3. one monday issue pack for projection publication and validation wiring
