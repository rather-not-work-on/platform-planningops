---
title: plan: MONDAY Agent Harness Wave 1 Implementation Issue Pack
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the first executable implementation wave for monday-owned agent harness capabilities, covering team-phase execution, session and replay artifacts, evidence publication, and planningops-facing projections without collapsing repo boundaries.
tags:
  - uap
  - monday
  - planningops
  - harness
  - runtime
  - issue-pack
  - backlog
related_docs:
  - ./2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ./2026-03-23-monday-team-phase-contract-draft.md
  - ./2026-03-23-monday-session-replay-evidence-draft.md
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
---

# plan: MONDAY Agent Harness Wave 1 Implementation Issue Pack

## Preconditions

This issue pack is valid because:

- the reference-assimilation plan exists and fixes the repo boundary
- the gap analysis already classifies what to adopt, adapt, defer, and reject
- the team-phase, session/replay, capability, and planningops-projection drafts now exist as one coherent design set
- the next uncertainty is no longer architecture direction, but phased implementation order

## Goal

Land the first monday-owned harness wave without collapsing runtime ownership back into `platform-planningops`.

The rule for this wave is strict:

- `monday` implements mission intake, phase execution, worker state, session persistence, replay lineage, and evidence publication
- `planningops` does not host live runtime state
- `planningops` may only validate stable projections after monday artifact shapes stop moving

## Selected Rollout Order

This issue pack selects one dependency-safe order:

1. mission intake and team-phase skeleton
2. session state and replay artifact baseline
3. worker coordination and tool-lineage recording
4. verification, repair, and evidence publication
5. planningops-facing projection publication
6. planningops control-plane validation and readiness gates

## Wave 1 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `MH10` | 10 | `rather-not-work-on/monday` | `mission-intake` | `ready_implementation` | mission intake record + team-phase status skeleton |
| `MH20` | 20 | `rather-not-work-on/monday` | `runtime-state` | `ready_implementation` | `session-state.json`, `worker-snapshot.json`, `replay-log.jsonl` baseline |
| `MH30` | 30 | `rather-not-work-on/monday` | `worker-orchestrator` | `ready_implementation` | worker role taxonomy + task assignment and tool-lineage records |
| `MH40` | 40 | `rather-not-work-on/monday` | `verify-repair` | `ready_implementation` | verify/repair loop + `execution-evidence-bundle.json` |
| `MH50` | 50 | `rather-not-work-on/monday` | `projection-publisher` | `ready_implementation` | completion/readiness/verification/operator-handoff projections |
| `MH60` | 60 | `rather-not-work-on/platform-planningops` | `control-plane-contract` | `backlog` | promoted projection contract candidate + doctor/gate issue draft |

## Decomposition Rules

- `MH10` defines the machine-readable phase vocabulary and transition model, but must not yet claim canonical control-plane readiness semantics.
- `MH20` adds monday-owned runtime artifacts only. These files are runtime state, not control-plane truth.
- `MH30` records worker and tool lineage in replay history, but must not expose internal scratchpad content as an operator surface.
- `MH40` is the first step allowed to publish sealed evidence and terminal verdicts.
- `MH50` may publish control-plane-facing projections only from sealed evidence, never from live in-memory state.
- `MH60` may add planningops-side contracts only after `MH50` artifact shape stabilizes.

## Dependencies

- `MH20` depends on `MH10`
- `MH30` depends on `MH10`, `MH20`
- `MH40` depends on `MH20`, `MH30`
- `MH50` depends on `MH40`
- `MH60` depends on `MH50`

## Hold Rules

- do not let `planningops` consume `session-state.json` as canonical status
- do not publish `ready` projections before verify/repair semantics exist
- do not allow `execute -> done` shortcuts
- do not publish operator-facing success when replay lineage is missing
- do not freeze planningops schemas while monday artifact names and field sets are still moving

## Go / Hold Criteria by Stage

### `MH10` Go

- phase ids are explicit and machine-readable
- forbidden transitions fail closed
- mission and run identity are stable

### `MH20` Go

- session state is resumable
- replay log is append-only
- worker snapshot references known replay events

### `MH30` Go

- each tool action is attributable to worker, phase, and task lineage
- worker role taxonomy is explicit
- no hidden mutation path bypasses replay recording

### `MH40` Go

- verification verdicts are explicit
- repair attempts are counted
- sealed evidence bundle points back to replay/session/snapshot artifacts

### `MH50` Go

- completion summary, readiness projection, verification projection, and operator handoff summary all agree on `run_id`
- projections are derived from sealed evidence only
- blocked and ready states cannot contradict each other

### `MH60` Go

- monday projection shape has stayed stable long enough to be validated externally
- planningops-side schemas reflect projections only, not runtime-private state
- doctor/gate semantics consume published outputs rather than monday internals

## Explicit Non-Goals

- no vendor import of `oh-my-*` runtime code
- no planningops-owned worker scheduler
- no direct planningops ownership of monday prompt memory
- no canonical readiness promotion before monday publishes stable projections
- no UI or operator shell design work in this wave

## Expected Implementation Outputs

Inside `monday`, this wave should eventually produce:

- one mission intake surface
- one team-phase status surface
- one session state artifact
- one replay log artifact
- one worker snapshot artifact
- one sealed execution evidence bundle
- four planningops-facing derived projections

Inside `planningops`, this wave should eventually produce:

- one promoted evidence projection contract candidate
- one readiness validation/gate issue draft

## Validation Commands

```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile workbench
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
```

Expected sibling-repo validation during implementation:

```bash
cd ../monday
pnpm test
pnpm typecheck
```

## Decision Note

This wave is intentionally conservative.

It prefers:

- runtime ownership before control-plane validation
- replay-backed evidence before readiness claims
- derived projections before promoted gates

It rejects:

- doc-first readiness fiction
- control-plane takeover of runtime internals
- prompt-only agent behavior with no artifact lineage
