---
title: audit: MONDAY Agent Harness Reference Gap Analysis
type: audit
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Compares MONDAY's current runtime direction against oh-my-claudecode, oh-my-openagent, and oh-my-codex, then classifies which harness patterns should be adopted, adapted, deferred, or rejected.
related_docs:
  - ../plans/2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ../plans/2026-03-16-plan-deepagents-core-skillctl-and-sandbox-rollout-plan.md
  - ../../../initiatives/unified-personal-agent-platform/00-governance/uap-monday-identity.meta.md
  - ../../../initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-skeleton-ready-implementation-pack.md
  - ../../../../planningops/adr/adr-0001-ralph-loop-harness-topology.md
---

# audit: MONDAY Agent Harness Reference Gap Analysis

## Objective

Evaluate three external agent-harness references against the current `monday` direction and produce one adoption matrix that preserves the existing boundary:

- `platform-planningops` remains the development orchestration and governance layer
- `monday` becomes the execution harness owner

This audit is not asking whether upstream harnesses are impressive. It is asking which pieces fit `M.O.N.D.A.Y.` as an execution repo and which pieces should remain outside the system.

## Inputs

### Internal inputs

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-23-monday-agent-harness-reference-assimilation-plan.md`
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-16-plan-deepagents-core-skillctl-and-sandbox-rollout-plan.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-monday-identity.meta.md`
- `docs/initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/runtime-skeleton-ready-implementation-pack.md`
- `planningops/adr/adr-0001-ralph-loop-harness-topology.md`

### External references

- `oh-my-claudecode`
- `oh-my-openagent`
- `oh-my-codex`

Reference snapshot date: **2026-03-23**

## Current MONDAY Baseline

The current internal direction already implies several constraints:

- `monday` is the correct execution-repo owner for harness evolution
- `platform-planningops` must not become a runtime host
- `deepagents` and `skillctl` work already move MONDAY toward a repo-owned planner/runtime surface
- existing monday runtime planning freezes package boundaries such as:
  - `agent-kernel`
  - `orchestrator`
  - `executor-ralph-loop`
  - `messaging-adapter`
  - gateway-facing adapters

That means the question is not “should we add a harness somewhere?”  
The real question is “which reference-harness patterns should MONDAY absorb into its own architecture?”

## Fit Classification

Classification meanings:

- `adopt`: build into MONDAY with minimal conceptual change
- `adapt`: keep the idea, redesign the implementation to match MONDAY boundaries
- `defer`: useful, but not first-wave critical
- `reject`: conflicts with MONDAY or planningops ownership boundaries

## Capability Matrix

| capability | current MONDAY state | strongest reference | decision | why |
|---|---|---|---|---|
| explicit staged team lifecycle | partial | `oh-my-claudecode` | adopt | MONDAY needs a first-class execution phase model, not just implicit planner/executor hops |
| worker role taxonomy | partial | `oh-my-openagent` | adopt | role-based delegation is more stable than model-specific delegation |
| session state artifacts | weak | `oh-my-openagent` | adopt | long-running autonomy needs durable run/session state |
| replay logs | weak | `oh-my-openagent` | adopt | post-run diagnosis and resumability need replayable logs |
| clarification / interview mode | absent | `oh-my-claudecode` | adapt | MONDAY should clarify vague goals before planning, but with MONDAY-specific UX and contracts |
| advisor workers | absent | `oh-my-claudecode` | adapt | architecture/review/docs advisors fit MONDAY, but must not bypass executor boundaries |
| persistent repair loop | partial | `oh-my-openagent` | adopt | MONDAY needs verify-repair completion, not single-pass execution |
| skill auto-load / precedence | partial | `oh-my-claudecode` | adapt | integrate with `skillctl`, not plugin conventions |
| lightweight Codex-native wrapper | weak | `oh-my-codex` | defer | useful for ergonomics, but not the core architecture priority |
| tmux worker runtime | absent | `oh-my-claudecode`, `oh-my-openagent` | adapt | good for real local worker concurrency, but must be optional and bounded |
| background agent fanout | weak | `oh-my-openagent` | adapt | useful once session state and worker controls exist |
| hash-anchored edit discipline | absent | `oh-my-openagent` | defer | valuable for high-trust edits, but not the first correctness bottleneck in MONDAY |
| model auto-routing | partial | all three | adapt | MONDAY should route by role/policy, not copy upstream model maps |
| HUD/live observability | weak | `oh-my-claudecode` | defer | useful later; evidence artifacts matter before live HUD polish |
| slash/magic keyword UX | absent | all three | reject | upstream command vocabulary is not a stable MONDAY surface |
| full upstream harness vendoring | absent | all three | reject | direct import would collapse ownership boundaries and create dependency drag |

## Reference-by-Reference Assessment

## A. `oh-my-openagent`

### Best fit areas

- worker specialization
- persistent execution model
- session and replay artifacts
- strong runtime/tool surface
- background agent orientation

### MONDAY interpretation

This is the best source for **runtime architecture patterns**.

MONDAY should learn from its:

- worker categorization
- durable execution semantics
- operational tooling
- session-oriented design

MONDAY should not inherit:

- branding
- upstream command model
- upstream provider/runtime assumptions

### Final classification

- architecture patterns: `adopt/adapt`
- runtime implementation: `reject as dependency`

## B. `oh-my-claudecode`

### Best fit areas

- phase-based team orchestration
- clarification mode
- advisor surface
- skill lifecycle model

### MONDAY interpretation

This is the best source for **execution lifecycle design**.

The single most important pattern is the explicit team pipeline. MONDAY should convert that into a contractable phase model such as:

`clarify -> plan -> design -> execute -> verify -> repair -> publish-evidence`

MONDAY should not inherit:

- plugin-specific assumptions
- Claude-specific slash surface
- direct command vocabulary as the public MONDAY interface

### Final classification

- phase model: `adopt`
- command surface: `reject`

## C. `oh-my-codex`

### Best fit areas

- thin Codex-native wrapper thinking
- simple orchestration ergonomics
- lightweight configuration patterns

### MONDAY interpretation

This is useful as a **local ergonomics reference**, not as the primary architecture source.

It helps answer:

- how should a Codex-friendly MONDAY surface feel?
- what should stay thin and local instead of becoming framework-heavy?

It does not answer:

- how to build the full harness runtime
- how to manage long-running multi-agent execution

### Final classification

- ergonomics ideas: `defer/adapt`
- architecture dependency: `reject`

## MONDAY Gap Summary

## Highest-priority missing capabilities

1. explicit team-phase execution contract
2. durable session state
3. replay log format
4. worker role taxonomy
5. verify/repair completion loop
6. clarification mode before planning

## Medium-priority missing capabilities

1. advisor workers
2. tmux or subprocess worker pool
3. skill auto-resolution and precedence UX
4. runtime operator status surface

## Low-priority missing capabilities

1. HUD polish
2. Codex-specific wrapper ergonomics
3. anchored editing discipline

## Recommended Assimilation Order

## Wave A: Runtime skeleton closure

Deliver first:

- worker role taxonomy
- team-phase contract
- session state schema
- replay log schema

Rationale:

Without these four, MONDAY cannot safely absorb the more impressive external harness behaviors.

## Wave B: Completion semantics

Deliver next:

- verify/repair loop
- bounded retry policy
- evidence publishing at phase boundaries

Rationale:

This is the minimum needed for “persistent autonomy” without hiding failure.

## Wave C: Interaction improvements

Deliver after Wave B:

- clarification/interview mode
- advisor workers
- tool-router policy
- optional tmux worker runtime

Rationale:

These improve quality and throughput, but they should sit on top of stable session and evidence primitives.

## Wave D: Ergonomics and polish

Deliver last:

- Codex-thin wrapper UX
- operator HUD
- richer local worker controls

Rationale:

These matter, but only after the harness semantics are trustworthy.

## Boundary Audit Result

## What planningops should do

- keep the boundary explicit
- define harness capability contracts
- define evidence and readiness expectations
- validate MONDAY outputs
- avoid runtime ownership creep

## What planningops should not do

- host worker runtime code
- embed external harness runtimes
- become the place where agent execution loops live
- mirror upstream command surfaces

## What monday should do

- absorb the reusable architecture patterns
- implement the actual runtime
- own worker/session/tool/runtime behavior
- remain the single execution-plane repo

## Verdict

- `oh-my-openagent`: best architecture reference for runtime composition
- `oh-my-claudecode`: best lifecycle reference for staged team execution
- `oh-my-codex`: best lightweight reference for Codex-facing ergonomics

### Final decision

MONDAY should use all three as **reference inputs**, but it should build one repo-owned harness architecture instead of composing upstream systems.

The strongest next design move is:

- build a MONDAY capability contract around staged phases, session state, replay logs, and worker taxonomy

The strongest anti-goal is:

- never let `platform-planningops` turn into the harness just because it already owns the plans
