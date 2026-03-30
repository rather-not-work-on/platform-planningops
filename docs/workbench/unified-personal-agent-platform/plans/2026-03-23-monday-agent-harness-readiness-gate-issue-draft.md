---
title: plan: MONDAY Agent Harness Readiness Gate Issue Draft
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Drafts the first planningops-side doctor and gate rollout over monday MH50 projections without violating the runtime-private boundary.
related_docs:
  - ./2026-03-23-monday-agent-harness-projection-contract-candidate.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ./2026-03-23-monday-agent-harness-wave1-projection-seed-packet.md
---

# plan: MONDAY Agent Harness Readiness Gate Issue Draft

## Intent

Prepare the first `planningops` doctor and gate issue over monday-published projection surfaces.

This remains a draft until monday projection filenames and field sets stay stable across repeated runs.

## Scope

PlanningOps should consume only:

- `completion-summary.json`
- `readiness-projection.json`
- `verification-projection.json`
- `operator-handoff-summary.json`

PlanningOps should not consume:

- replay logs
- session state
- worker snapshots
- verification verdict sidecars
- repair-loop sidecars

## Proposed Checks

### Doctor

The doctor should report:

- whether projection files exist
- whether `runId` and `sessionId` agree across all projections
- whether readiness and handoff semantics agree
- whether verification and completion verdicts agree
- whether a blocked run names an actionable next actor and next step

### Gate

The first gate should fail closed when:

- required projection files are missing
- projections disagree on run lineage
- `readinessStatus=ready` while `handoffStatus=required`
- `finalStatus=succeeded` while `verificationVerdict!=pass`
- `finalStatus=blocked` while `handoffStatus!=required`

## Suggested Output Surfaces

If promoted, planningops should produce:

- one validation report over monday projections
- one doctor summary over that validation report
- one shell gate entrypoint for fail-closed readiness enforcement

## Deliberate Deferrals

Do not include yet:

- replay freshness heuristics
- monday worker inventory checks
- task or tool-level lineage validation
- operator-channel delivery validation

Those remain monday-owned runtime concerns.

## Ready-to-Open Issue Shape

- repo: `rather-not-work-on/platform-planningops`
- parent pack: `MH60`
- depends on: stable `MH50A`, `MH50B`, `MH50C`, `MH50D`
- component: `projection-readiness-gate`
- workflow state: `backlog until monday projection stability is demonstrated`

## Exit Condition

This draft becomes actionable only when monday can supply:

- one sample artifact set with all four projections
- one repeated run proving the same field set
- one explicit invariant list shared by all four projections
