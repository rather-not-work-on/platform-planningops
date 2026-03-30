---
title: audit: MONDAY Agent Harness Reference Traceability Map
type: audit
date: 2026-03-23
updated: 2026-03-23
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Maps the external oh-my-* reference projects to concrete MONDAY wave1 sub-issues so research findings can be applied without importing foreign runtime ownership into planningops.
related_docs:
  - ../plans/2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ./2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ../plans/2026-03-23-monday-agent-harness-wave1-implementation-issue-pack.md
  - ../plans/2026-03-23-monday-agent-harness-wave1-sub-issue-decomposition.md
  - ../plans/2026-03-23-monday-harness-capability-contract-draft.md
---

# audit: MONDAY Agent Harness Reference Traceability Map

## Purpose

Turn the external reference study into implementation guidance.

This map answers one question only:

Which concrete MONDAY sub-issues should absorb which ideas from:

- `oh-my-openagent`
- `oh-my-claudecode`
- `oh-my-codex`

## Boundary Reminder

The references are pattern sources, not import targets.

Use them to shape:

- monday runtime behavior
- monday artifact discipline
- monday operator ergonomics

Do not use them to:

- move runtime ownership into planningops
- justify vendoring a foreign harness whole
- bypass monday-native contracts

## Traceability Table

| Reference Pattern | Best Source | MONDAY Sub-Issue Targets | Adoption Mode | Notes |
| --- | --- | --- | --- | --- |
| explicit staged execution lifecycle | `oh-my-claudecode` | `MH10A`,`MH10C`,`MH40A`,`MH40B` | adapt | keep the phase model, not the repo/plugin structure |
| mission clarification before execution | `oh-my-claudecode` | `MH10B` | adapt | preserve user-gated boundaries and ambiguity handling |
| team worker role separation | `oh-my-openagent` + `oh-my-claudecode` | `MH30A`,`MH30C` | adapt | monday should keep repo-native role names |
| background worker orchestration runtime | `oh-my-openagent` | `MH30A`,`MH30C` | adapt | runtime composition idea is useful; exact worker engine is not |
| tool-call lineage and auditable mutation path | `oh-my-openagent` | `MH30B`,`MH40C` | adopt/adapt | strong fit for replay-backed evidence |
| session persistence and resumability | `oh-my-openagent` | `MH20A`,`MH20B`,`MH20C` | adapt | monday needs equivalent artifact discipline |
| replay-first diagnosis | `oh-my-openagent` | `MH20B`,`MH40C`,`MH50A` | adopt | best direct architecture match |
| evidence-first completion | mixed | `MH40A`,`MH40C`,`MH50A`,`MH50B`,`MH50C` | adopt | this should become a monday invariant |
| advisor / operator surface | `oh-my-claudecode` | `MH50D`,`MH60B` | adapt | operator guidance is useful; plugin-specific shape is not |
| lightweight codex-native ergonomics | `oh-my-codex` | `MH10B`,`MH30B` | defer/selective adapt | use only for thin wrapper ergonomics, not architecture |
| skill and command modularity | `oh-my-claudecode` + `oh-my-openagent` | later than wave1 | defer | useful, but not required to land wave1 runtime core |
| multi-model routing and provider strategy | `oh-my-openagent` | later than wave1 | defer | belongs after runtime core and evidence surfaces stabilize |

## What to Copy Closely

These are the closest architectural fits and should influence implementation strongly:

- replay-backed evidence publication
- resumable session state
- explicit team-phase lifecycle
- auditable tool lineage

These patterns align with monday's execution-plane role and PlanningOps' control-plane boundary.

## What to Redesign Heavily

These ideas are useful but should be reimplemented in monday-native form:

- worker role naming
- operator/advisor shell
- task queue shapes
- CLI entrypoints
- skill package layout

The foreign repos solve similar problems, but inside different assumptions.

## What to Reject

Reject these moves even if they look convenient:

- vendoring the full harness into planningops
- treating plugin metadata as canonical runtime contracts
- copying upstream directory layout as if it were an interface
- using prompt-only completion with no replay/evidence lineage

## Wave 1 Priority Lens

For wave1, the reference priorities should be:

1. `oh-my-openagent` for session, replay, lineage, and execution discipline
2. `oh-my-claudecode` for staged team lifecycle and operator-facing stop/handoff logic
3. `oh-my-codex` for thin ergonomics only

That means:

- most of `MH20`, `MH30`, and `MH40` should lean on `oh-my-openagent` patterns
- most of `MH10` and `MH50D` should lean on `oh-my-claudecode` patterns
- almost none of wave1 should depend materially on `oh-my-codex`

## Hand-Off Guidance for monday

If this map is handed to the monday repo, the implementation guidance should be:

1. start with `MH10A`, `MH20B`, and `MH20A`
2. implement replay and session rules before operator sugar
3. land sealed evidence before any control-plane projection
4. keep planningops consumption out of scope until `MH50*`

## Promotion Note

If a future canonical monday document is written, this audit should not be promoted verbatim.

Instead, promote:

- the capability contract
- the artifact map
- the issue pack or sub-issue breakdown

This traceability map should remain supporting analysis.
