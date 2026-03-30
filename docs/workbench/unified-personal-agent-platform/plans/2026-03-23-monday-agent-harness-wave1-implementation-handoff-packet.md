---
title: plan: MONDAY Agent Harness Wave 1 Implementation Handoff Packet
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Provides one concise handoff packet that a monday execution owner can use to start MONDAY Agent harness wave1 implementation without rereading the full planning chain.
tags:
  - uap
  - monday
  - planningops
  - harness
  - handoff
related_docs:
  - ./2026-03-23-monday-agent-harness-wave1-registration-runbook.md
  - ./2026-03-23-monday-agent-harness-wave1-opening-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-evidence-seed-packet.md
  - ./2026-03-23-monday-agent-harness-wave1-projection-seed-packet.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-traceability-map.md
---

# plan: MONDAY Agent Harness Wave 1 Implementation Handoff Packet

## Purpose

Give one monday execution owner the minimum packet needed to begin work.

This packet answers only:

- what to start now
- what not to start yet
- what evidence to bring back

## Execution Owner Brief

Implement the first monday-owned harness backbone without moving runtime ownership into `platform-planningops`.

The rule is simple:

- monday owns runtime state, replay, evidence, and projection generation
- planningops waits until projection shapes stabilize

## Start Now

Open and execute these issues first:

1. `MH10A`
2. `MH10B`
3. `MH10C`
4. `MH20A`
5. `MH20B`
6. `MH20C`

Then move to:

7. `MH30A`
8. `MH30B`
9. `MH30C`
10. `MH40A`
11. `MH40B`
12. `MH40C`

Only after that, open:

13. `MH50A`
14. `MH50B`
15. `MH50C`
16. `MH50D`

## Do Not Start Yet

Do not start these until monday projection shapes are stable:

- `MH60A`
- `MH60B`

Do not let planningops consume:

- `session-state.json`
- `worker-snapshot.json`
- `team-phase-status.json`
- raw replay logs as control-plane truth

## Required monday Artifact Backbone

By the end of the monday side of wave1, these artifacts should exist:

- `artifacts/runtime/team-phase-status.json`
- `artifacts/runtime/session-state.json`
- `artifacts/runtime/replay-log.jsonl`
- `artifacts/runtime/worker-snapshot.json`
- `artifacts/runtime/execution-evidence-bundle.json`
- `artifacts/runtime/completion-summary.json`
- `artifacts/runtime/readiness-projection.json`
- `artifacts/runtime/verification-projection.json`
- `artifacts/runtime/operator-handoff-summary.json`

## Success Conditions

The monday side is ready to hand back when all of these are true:

- phase transitions are explicit and forbidden shortcuts fail closed
- run/session identity is stable
- replay is append-only
- tool actions are attributable to worker/phase/task lineage
- verification and repair are machine-readable
- sealed evidence exists
- projections are derived from sealed evidence only

## Failure / Stop Conditions

Stop and rescope if:

- artifact filenames are still changing weekly
- replay and session lineage contradict each other
- evidence bundle fields are unstable between runs
- projections require mutable runtime state to compute

## Reference Priority

When choosing which external reference to lean on:

1. prefer `oh-my-openagent` for replay, session, lineage, and evidence patterns
2. prefer `oh-my-claudecode` for phase lifecycle and blocked/handoff logic
3. treat `oh-my-codex` as optional thin ergonomics only

## Return Packet to PlanningOps

When monday reaches stable `MH50*` outputs, return with:

- one sample run artifact set
- one description of stable filenames and field sets
- one list of invariants guaranteed across the projection files

That is the earliest point where planningops should begin `MH60A`.
