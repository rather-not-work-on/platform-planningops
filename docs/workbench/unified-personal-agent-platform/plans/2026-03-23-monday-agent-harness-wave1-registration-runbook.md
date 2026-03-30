---
title: plan: MONDAY Agent Harness Wave 1 Registration Runbook
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines how to register and start the MONDAY Agent harness wave1 issue cards in the correct order, with stop conditions and checkpoint rules that preserve the runtime-versus-control-plane boundary.
tags:
  - uap
  - monday
  - planningops
  - harness
  - runbook
  - issue-registration
related_docs:
  - ./2026-03-23-monday-agent-harness-wave1-opening-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-evidence-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-projection-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-sub-issue-decomposition.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-traceability-map.md
---

# plan: MONDAY Agent Harness Wave 1 Registration Runbook

## Purpose

Provide one bounded operational sequence for opening and starting MONDAY Agent harness wave1 work.

This runbook is intentionally narrow:

- it tells operators which issue packet to use
- it tells them when to stop opening new issues
- it prevents planningops from taking runtime ownership by accident

## Primary Rule

Register monday issues first.

Do not start planningops-side `MH60*` work until monday runtime artifact shapes are stable through `MH50*`.

## Inputs

Use these documents in order:

1. [MONDAY Agent Harness Wave 1 Opening Seed Packet](./2026-03-23-monday-agent-harness-wave1-opening-seed-packet.md)
2. [MONDAY Agent Harness Wave 1 Evidence Seed Packet](./2026-03-23-monday-agent-harness-wave1-evidence-seed-packet.md)
3. [MONDAY Agent Harness Wave 1 Projection Seed Packet](./2026-03-23-monday-agent-harness-wave1-projection-seed-packet.md)

Supporting references:

- [MONDAY Runtime Artifact Map Draft](./2026-03-23-monday-runtime-artifact-map-draft.md)
- [MONDAY PlanningOps Evidence Projection Contract Draft](./2026-03-23-monday-planningops-evidence-projection-contract-draft.md)
- [MONDAY Agent Harness Reference Traceability Map](../audits/2026-03-23-monday-agent-harness-reference-traceability-map.md)

## Registration Sequence

### Batch 1: Runtime Identity and State Backbone

Open in this exact order:

1. `MH10A`
2. `MH10B`
3. `MH10C`
4. `MH20A`
5. `MH20B`
6. `MH20C`

Checkpoint after batch 1:

- phase vocabulary is explicit
- run/session identity is stable
- session state and replay log exist
- worker snapshot points only to known replay events

### Batch 2: Evidence Backbone

Open only after batch 1 is accepted:

1. `MH30A`
2. `MH30B`
3. `MH30C`
4. `MH40A`
5. `MH40B`
6. `MH40C`

Checkpoint after batch 2:

- worker role taxonomy exists
- tool lineage is replay-backed
- verification and repair semantics exist
- execution evidence bundle is sealed and internally consistent

### Batch 3: Projection and Control-Plane Bridge

Open only after batch 2 is stable:

1. `MH50A`
2. `MH50B`
3. `MH50C`
4. `MH50D`

Open only after `MH50*` shapes are stable:

5. `MH60A`
6. `MH60B`

Checkpoint after batch 3:

- projections are derived from sealed evidence only
- no monday mutable artifact is being treated as control-plane truth
- planningops contract candidate reads projections only

## Stop Conditions

Stop opening new issues when any of these happen:

- artifact filenames are still changing weekly
- replay lineage does not survive repeated runs
- `MH40C` evidence bundle shape is unstable
- projections are computed from mutable state instead of sealed evidence
- planningops work starts to reference monday-private runtime internals

If any stop condition is hit, return to the issue pack and update scope before opening more cards.

## Anti-Drift Rules

- do not open `MH60A` or `MH60B` early
- do not merge planningops-side schemas before monday projection shape stabilizes
- do not collapse replay, state, and evidence into one file
- do not treat reference repos as implementation sources of truth

## Minimal Evidence Expected From monday Before PlanningOps Starts

Before `MH60A`, monday should be able to show:

- `execution-evidence-bundle.json`
- `completion-summary.json`
- `readiness-projection.json`
- `verification-projection.json`
- `operator-handoff-summary.json`

All five should agree on:

- `run_id`
- final/blocked semantics
- evidence lineage

## Exit Condition

This runbook is complete when:

- all wave1 monday cards are registered in order
- `MH60*` is still held until monday artifact stability exists
- the next action is implementation in `monday`, not more planning depth in `planningops`
