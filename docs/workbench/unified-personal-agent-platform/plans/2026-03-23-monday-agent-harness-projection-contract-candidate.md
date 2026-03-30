---
title: plan: MONDAY Agent Harness Projection Contract Candidate
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures the now-implemented monday MH50 projection field set so planningops can prepare projection-only validation without reaching into monday runtime-private state.
related_docs:
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ./2026-03-23-monday-agent-harness-wave1-projection-seed-packet.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-agent-harness-wave1-implementation-handoff-packet.md
---

# plan: MONDAY Agent Harness Projection Contract Candidate

## Goal

Freeze the first control-plane-facing candidate surface that `planningops` may later validate.

This candidate is based on the implemented `monday` MH50 publication layer, not on the earlier abstract draft alone.

## Boundary

PlanningOps may consume only these monday-published projections:

- `runtime-artifacts/agent-harness/completion-summary.json`
- `runtime-artifacts/agent-harness/readiness-projection.json`
- `runtime-artifacts/agent-harness/verification-projection.json`
- `runtime-artifacts/agent-harness/operator-handoff-summary.json`

PlanningOps must not consume directly:

- `runtime-artifacts/agent-harness/session-state.json`
- `runtime-artifacts/agent-harness/worker-snapshot.json`
- `runtime-artifacts/agent-harness/replay-log.jsonl`
- `runtime-artifacts/agent-harness/verification-verdict.json`
- `runtime-artifacts/agent-harness/repair-loop-state.json`

## Implemented Producer Shape

The current monday implementation publishes projections from:

- sealed evidence bundle
- verification verdict
- optional repair-loop state

The projections are written immutably per run stamp and fail closed when rewritten with contradictory content.

## Candidate Field Set

### Completion Summary

Required fields:

- `missionId`
- `runId`
- `sessionId`
- `finalPhase`
- `finalStatus`
- `verificationVerdict`
- `completedAtUtc`
- `evidenceBundlePath`

### Readiness Projection

Required fields:

- `missionId`
- `runId`
- `sessionId`
- `readinessStatus`
- `reason`
- `verificationVerdict`
- `blockingConditions`
- `requiredEvidenceRefs`
- `generatedAtUtc`
- `evidenceBundlePath`

Current readiness statuses:

- `ready`
- `blocked`
- `not_ready`

### Verification Projection

Required fields:

- `missionId`
- `runId`
- `sessionId`
- `verificationVerdict`
- `verificationReportRefs`
- `failedChecks`
- `repairAttempts`
- `generatedAtUtc`
- `evidenceBundlePath`

### Operator Handoff Summary

Required fields:

- `missionId`
- `runId`
- `sessionId`
- `finalStatus`
- `verificationVerdict`
- `handoffStatus`
- `handoffReason`
- `nextRequiredActor`
- `recommendedNextStep`
- `blockingQuestionSet`
- `generatedAtUtc`
- `evidenceBundlePath`

Current handoff statuses:

- `not_required`
- `required`

## Cross-Projection Invariants

The monday implementation now enforces these invariants:

- all four projections agree on `runId`
- all four projections agree on `sessionId`
- all four projections agree on `verificationVerdict`
- all four projections agree on `evidenceBundlePath`
- `finalStatus=succeeded` implies `verificationVerdict=pass`
- `readinessStatus=ready` implies `handoffStatus=not_required`
- `finalStatus=blocked` implies `handoffStatus=required`
- `reasonCode=missing_question_set` implies non-empty `blockingQuestionSet`

## Control-Plane Consumption Rule

PlanningOps-side validation may check only:

- field presence
- allowed enum values
- shared lineage agreement
- freshness
- projection-to-projection coherence

PlanningOps-side validation must not check:

- task-level replay lineage
- worker snapshot details
- repair-loop internal history
- monday prompt or tool internals

## Promotion Preconditions

Promote this candidate only after:

- repeated monday-local runs preserve the same projection filenames
- repeated monday-local runs preserve the same required field set
- monday projection publication remains sealed-evidence-only

## Immediate Follow-On

Use this candidate to author:

1. one planningops-side readiness/verification schema set over projection surfaces only
2. one doctor/gate issue draft that consumes the readiness and handoff projections only
