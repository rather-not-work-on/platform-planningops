---
title: plan: MONDAY Team-Phase Contract Draft
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Drafts the staged execution contract that MONDAY Agent should use for multi-agent work, including phase semantics, transition rules, ownership, and evidence expectations.
related_docs:
  - ./2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-interface-wiring-pack.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-skeleton-ready-implementation-pack.md
---

# plan: MONDAY Team-Phase Contract Draft

## Purpose

Define the staged execution contract that `monday` should use for team-style multi-agent work.

This is not yet a canonical contract. It is a workbench draft that clarifies:

- the allowed phase model
- phase transition rules
- what evidence each phase must produce
- what `planningops` may consume versus what remains runtime-internal

## Boundary

- `monday` owns phase execution behavior
- `platform-planningops` owns only the governance and gate expectations around those phases

Therefore:

- phase runtime state belongs in `monday`
- phase evidence projections may later be validated by planningops-owned gates
- planningops must not become the executor of these phases

## Proposed Canonical Phase Set

MONDAY should expose one default lifecycle for complex multi-agent work:

1. `clarify`
2. `plan`
3. `design`
4. `execute`
5. `verify`
6. `repair`
7. `publish_evidence`
8. `done`

### Optional fast path

For trivial tasks, MONDAY may allow:

`plan -> execute -> verify -> publish_evidence -> done`

but only when the task is explicitly classified as low-risk and no clarification/design phase is required.

## Phase Semantics

## `clarify`

Purpose:

- resolve ambiguity
- extract missing constraints
- decide whether autonomous execution is allowed

Outputs:

- clarified objective
- explicit assumptions
- unresolved questions list

Exit rule:

- may advance only if ambiguity is below the configured threshold
- must stop or request user input if the task crosses a user-gated boundary

## `plan`

Purpose:

- create an actionable execution plan
- identify worker roles and dependencies
- shape work into bounded tasks

Outputs:

- task graph or ordered task set
- worker assignment intent
- success criteria

Exit rule:

- may advance only if at least one executable task exists and success criteria are explicit

## `design`

Purpose:

- resolve architecture, interface, or UX choices before code mutation

Outputs:

- accepted design notes
- boundary decisions
- implementation constraints

Exit rule:

- may advance only if design blockers are resolved or explicitly deferred

## `execute`

Purpose:

- perform the actual implementation or repo mutation work

Outputs:

- code/doc/config changes
- execution logs
- worker result summaries

Exit rule:

- may advance only if execution produced candidate outputs for verification

## `verify`

Purpose:

- determine whether execution outputs satisfy declared success criteria

Outputs:

- test/build/lint/contract evidence
- pass/fail verdict
- failure taxonomy when failing

Exit rule:

- pass -> `publish_evidence`
- fail with repairable cause -> `repair`
- fail with blocked cause -> stop with machine-readable blocked status

## `repair`

Purpose:

- apply bounded corrective action after failed verification

Outputs:

- repair attempt summary
- updated candidate outputs
- retry counter increment

Exit rule:

- returns to `verify`
- must stop when attempt budget is exhausted

## `publish_evidence`

Purpose:

- freeze the outcome into stable artifacts for operators and downstream systems

Outputs:

- machine-readable completion summary
- pointers to verification evidence
- phase transcript/replay references

Exit rule:

- may advance only if the published evidence is internally consistent and complete

## `done`

Purpose:

- terminal success state

Outputs:

- no new runtime behavior
- stable references only

## Allowed Transitions

```text
clarify -> plan
plan -> design
plan -> execute
design -> execute
execute -> verify
verify -> repair
verify -> publish_evidence
repair -> verify
publish_evidence -> done
```

## Forbidden Transitions

- `execute -> done`
- `execute -> publish_evidence`
- `repair -> done`
- `clarify -> execute`
- `plan -> done`

These shortcuts remove the verification guarantee and should be rejected by default.

## Phase Ownership Model

| concern | owner |
|---|---|
| phase execution runtime | `monday` |
| phase transition enforcement | `monday` |
| verification evidence generation | `monday` |
| downstream governance checks | `platform-planningops` |
| cross-repo readiness policy | `platform-planningops` |

## Worker Role Expectations

The phase contract assumes role-based workers, not provider-named workers.

Minimum role taxonomy:

- `orchestrator`
- `planner`
- `designer`
- `executor`
- `verifier`
- `repairer`
- `advisor`

MONDAY may map those roles to concrete models or local runtimes, but the phase contract should stay role-first.

## Evidence Expectations Per Phase

| phase | minimum evidence |
|---|---|
| `clarify` | assumptions, ambiguity verdict |
| `plan` | task list or task graph |
| `design` | decision note or explicit no-design-needed marker |
| `execute` | mutation summary and worker result refs |
| `verify` | pass/fail verdict plus validation refs |
| `repair` | retry number and repair summary |
| `publish_evidence` | final evidence bundle refs |

## Proposed Future MONDAY-Owned Artifacts

These should live in `monday`, not in `planningops`:

- `artifacts/runtime/team-phase-status.json`
- `artifacts/runtime/team-phase-transitions.jsonl`
- `artifacts/runtime/team-execution-summary.json`
- `artifacts/runtime/team-verification-report.json`

## Proposed Future PlanningOps-Governed Surfaces

PlanningOps should later govern only stable derived expectations such as:

- phase order invariants
- required evidence fields
- forbidden transition rules
- readiness projection semantics

PlanningOps should not govern:

- tmux session behavior
- in-memory worker coordination
- internal retry loop mechanics beyond exposed evidence

## Default Stop Conditions

MONDAY must stop and expose blocked status when:

- clarification reveals user-gated choices
- attempt budget is exhausted
- verification fails with non-repairable cause
- required evidence cannot be produced
- worker runtime becomes unavailable in a way that prevents trustworthy continuation

## Non-Goals

- define provider routing policy in this draft
- define tmux-specific lifecycle details
- define UI/CLI command syntax
- define all worker personas

## Promotion Path

If this draft stabilizes, split it into:

1. a `monday`-owned runtime contract for phase execution
2. a `planningops`-owned governance/gate contract for evidence and readiness

## Immediate Next Step

Use this phase draft together with the session/replay evidence draft to define one MONDAY capability contract around:

- staged execution
- resumability
- operator diagnosis
- evidence-first completion
