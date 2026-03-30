---
title: plan: MONDAY Agent Harness Reference Assimilation
type: plan
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines how to use oh-my-claudecode, oh-my-openagent, and oh-my-codex as reference architectures for MONDAY Agent without collapsing platform-planningops into an execution harness.
related_docs:
  - ../../../../planningops/adr/adr-0001-ralph-loop-harness-topology.md
  - ../../../initiatives/unified-personal-agent-platform/00-governance/uap-monday-identity.meta.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-skeleton-ready-implementation-pack.md
  - ./2026-03-16-plan-deepagents-core-skillctl-and-sandbox-rollout-plan.md
---

# plan: MONDAY Agent Harness Reference Assimilation

## Overview

This plan reframes three external projects as **reference inputs for `monday`**, not as integration targets for `platform-planningops`.

The boundary is explicit:

- `platform-planningops` is the development orchestration layer and control plane
- `monday` is the execution plane and the correct home for an agent harness

Therefore:

- no full harness should be imported into `platform-planningops`
- external harnesses should be studied, decomposed, and selectively reimplemented inside `monday`
- `platform-planningops` should only encode the contracts, gates, and evidence surfaces that `monday` must satisfy

## Snapshot Date

This analysis is based on the public repository state observed on **March 23, 2026**:

- [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)
- [code-yeongyu/oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)
- [junghwaYang/oh-my-codex](https://github.com/junghwaYang/oh-my-codex)

## Decision

### Chosen approach

Adopt a **reference-driven assimilation** strategy:

1. study external harnesses as architecture references
2. extract reusable patterns
3. map those patterns onto `monday` runtime ownership
4. express required boundaries and gates in `platform-planningops`
5. avoid vendoring or direct runtime embedding inside `platform-planningops`

### Explicit non-goals

- importing `oh-my-openagent` or `oh-my-claudecode` into `platform-planningops`
- turning `platform-planningops` into a tmux worker runtime, session host, or multi-agent execution shell
- copying external command surfaces and magic keywords as-is
- inheriting upstream model-routing assumptions without `monday`-specific constraints

## Why This Boundary Is Correct

## `platform-planningops` owns

- contracts
- boundary rules
- readiness and gate semantics
- evidence schemas
- rollout plans and verification policy

In short: **what must be true**

## `monday` owns

- worker runtime
- team orchestration
- session lifecycle
- tool routing
- retry/completion loops
- replay and local state artifacts
- provider/tool execution policy

In short: **how work gets done**

This matches the existing identity and topology docs:

- `M.O.N.D.A.Y.` is already the canonical agent identity
- `platform-planningops` is already positioned as the organization-level planning/control repository
- `monday` already has the right execution-repo role for harness evolution

## Reference Repository Analysis

## A. `oh-my-openagent`

### Observed structure

The repository is product-scale and runtime-heavy. Public structure includes:

- `.opencode/`
- `.sisyphus/rules/`
- `bin/`
- `docs/`
- `packages/`
- `script/`
- `signatures/`
- `src/`
- `tests/`
- `uvscripts/`
- `AGENTS.md`

### What it is good at

- large harness composition
- discipline-agent orchestration
- background workers
- edit discipline
- strong runtime/tooling surface
- session-centric execution environment

### What MONDAY should learn from it

- worker specialization categories instead of model-specific handoff logic
- session/replay/state artifact discipline
- structured tool surface with explicit routing
- persistence loops that do not stop at the first incomplete result
- strong runtime utilities around diagnostics, background work, and interactive terminals

### What MONDAY should not copy literally

- upstream command semantics
- upstream provider assumptions
- full runtime topology
- project branding, keywords, or agent personas

## B. `oh-my-claudecode`

### Observed structure

The repository presents a plugin-first, team-first orchestration shape with public emphasis on:

- teams
- staged pipeline execution
- skill management
- hooks
- documentation
- tmux CLI workers

### Most useful pattern

Its clearest transferable idea is the explicit staged pipeline:

`team-plan -> team-prd -> team-exec -> team-verify -> team-fix`

This is valuable because it converts “multi-agent” from a vague concept into a contractable execution lifecycle.

### What MONDAY should learn from it

- phase-based team orchestration
- pre-execution clarification/interview mode for vague tasks
- operator-facing worker status surface
- advisory worker pattern for architecture, review, and UI feedback
- skill auto-loading and skill lifecycle discipline

### What MONDAY should not copy literally

- slash-command vocabulary
- Claude-specific environment assumptions
- plugin packaging model

## C. `oh-my-codex`

### Observed structure

It appears to be a lighter Codex-oriented orchestration wrapper with emphasis on:

- `.codex/skills`
- orchestration shortcuts
- model routing
- agent catalog
- lightweight config-driven execution

### What MONDAY should learn from it

- Codex-native ergonomics
- thinner wrapper patterns
- small, understandable orchestration layers

### What MONDAY should not assume

- that a thin wrapper is sufficient for the full MONDAY runtime
- that Codex-centric defaults generalize to a federated execution platform

## Assimilation Matrix

| Capability | Best reference | Adoption strategy in `monday` |
|---|---|---|
| staged multi-agent lifecycle | `oh-my-claudecode` | reimplement as MONDAY team phases |
| worker specialization model | `oh-my-openagent` | adapt into MONDAY role taxonomy |
| session and replay artifacts | `oh-my-openagent` | implement repo-owned run/session state |
| Codex-native thin wrapper | `oh-my-codex` | use for local CLI ergonomics only |
| skill lifecycle and auto-load | `oh-my-claudecode` | adapt into MONDAY skill registry and resolution |
| persistent completion loop | `oh-my-openagent` | reimplement with MONDAY gate/evidence rules |
| magic keyword UX | mixed | reject as canonical surface; keep explicit commands |

## Target MONDAY Harness Shape

## Proposed runtime topology inside `monday`

```text
monday/
  agents/
    orchestrator/
    planner/
    executor/
    verifier/
    fixer/
    advisors/
  skills/
    bundled/
    vendor/
    registry/
  runtimes/
    local/
    tmux/
    subprocess/
  sessions/
    active/
    archived/
  replay/
    jsonl/
  tools/
    router/
    policies/
  contracts/
    harness/
  config/
    harness-runtime.json
    worker-pool.json
    skill-registry.json
```

## Canonical execution phases

MONDAY should prefer one explicit lifecycle:

1. `clarify`
2. `plan`
3. `design`
4. `execute`
5. `verify`
6. `repair`
7. `publish-evidence`

This should be the runtime analogue of the team/staged pipeline patterns seen upstream, but adapted to MONDAY’s run contracts and queue semantics.

## Required MONDAY capabilities

- explicit worker role taxonomy
- deterministic handoff metadata
- run/session artifact persistence
- replayable action log
- skill resolution with precedence
- tool policy boundary
- completion loop with evidence gating
- operator inspection surface
- safe interruption/resume behavior

## `platform-planningops` Follow-through

`platform-planningops` should not host the harness, but it should add or refine:

- harness capability contract
- worker-state evidence schema
- session replay evidence schema
- team-phase completion contract
- harness readiness gate
- adoption scorecard for external-reference parity

This keeps planningops in the role of **governance and verification**, not runtime ownership.

## Phased Rollout

## Phase 1: Reference capture

- document the external references and extracted patterns
- define MONDAY-owned target capabilities
- freeze boundary: planningops governs, monday executes

## Phase 2: MONDAY harness skeleton

- add MONDAY-native runtime directories and config
- introduce worker roles and phase lifecycle
- land session/replay artifacts
- keep feature scope local and non-production by default

## Phase 3: Skill and tool discipline

- implement skill registry and precedence
- add tool-router policy
- make unsafe tool execution fail-closed

## Phase 4: Evidence-driven autonomy

- attach phase completion to verification evidence
- add repair loop semantics
- expose operator-facing status and interruption controls

## Phase 5: PlanningOps governance closure

- promote stable workbench decisions into canonical contracts
- add readiness gates and validation suites
- keep MONDAY harness evolution bounded by explicit contracts

## Adoption Rules

## Allowed

- architecture borrowing
- lifecycle borrowing
- state/evidence pattern borrowing
- role taxonomy borrowing
- UX pattern borrowing after renaming and boundary adaptation

## Forbidden

- repo vendoring into `platform-planningops`
- direct copy of command surface as canonical interface
- uncontrolled model/provider routing imported from upstream
- hidden runtime side effects outside MONDAY evidence contracts

## Success Criteria

This plan is successful only if:

- `platform-planningops` remains a control plane repository
- `monday` becomes the only harness owner
- external references accelerate MONDAY design without dictating it
- future MONDAY harness phases can be validated by planningops-owned contracts
- no planningops-local runtime execution layer is introduced by convenience

## Immediate Next Steps

1. create a MONDAY-focused gap analysis against the three references
2. define a MONDAY harness capability matrix
3. draft a MONDAY team-phase contract
4. define session/replay artifact schemas
5. convert the stable parts into canonical planningops contracts only after MONDAY-side ownership is clear

## Final Principle

Use the external harnesses as **reference architectures**, not as **dependencies**.

The correct operating model is:

- `platform-planningops` defines the protocol
- `monday` implements the machine
