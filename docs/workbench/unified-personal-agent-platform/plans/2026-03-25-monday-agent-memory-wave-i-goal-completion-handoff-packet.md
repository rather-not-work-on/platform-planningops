---
title: plan: MONDAY Agent Memory Wave I Goal-Completion Handoff Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next planningops slice after scheduler-evidence reflection: goal-completed memory reflection actions must bridge into supervisor handoff artifacts and monday goal-completion queue admission.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-h-control-plane-reflection-packet.md
  - ./2026-03-25-monday-agent-memory-wave-f-completion-packet.md
---

# plan: MONDAY Agent Memory Wave I Goal-Completion Handoff Packet

## Purpose

Let `planningops` close the memory reflection loop after `goal_achieved`: the control plane should turn a completed monday memory scheduler report into one validated supervisor handoff bundle, one applied goal transition, and one monday goal-completion scheduled delivery admission.

## Scope

Wave I should add:

- one planningops-owned bridge from a `goal_completed` reflection action into supervisor handoff artifacts
- apply-mode goal transition closure when the source reflection action still carries `goal_transition_report_path: -`
- monday goal-completion scheduled admission through the canonical supervisor delivery helper path
- deterministic cross-repo regression coverage using the real monday memory scheduler report flow

Wave I should not yet add:

- automatic operator-message delivery for non-terminal memory reflection decisions
- batching across multiple completed memory worker outcomes
- control-plane-owned transport execution or monday queue mutation beyond canonical admission

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_reflection_goal_completion_handoff_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_reflection_goal_completion_handoff_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_reflection_goal_completion_handoff_cycle.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/contracts/reflection-cycle-orchestration-contract.md`

## Acceptance Gates

- the bridge accepts one `goal_completed` reflection action artifact and fails closed for other action kinds
- apply-mode runs create a real goal transition report when the source action has no transition artifact yet
- the bridge emits valid supervisor handoff artifacts plus a monday goal-completion admission report
- the monday queue row for the admitted goal-completion delivery is created with `schedule_key=recurring-delivery`
- the active-goal registry transitions from the reflected memory goal to `achieved`

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane reflection chain.

Current state:
- monday memory scheduler already emits completed worker outcomes
- planningops can already evaluate monday scheduler evidence into a goal-completed reflection action
- monday already owns goal-completion scheduled delivery admission

Implement Wave I only:
1. add a planningops bridge from a goal-completed reflection action into supervisor handoff artifacts
2. reuse the canonical monday goal-completion admission path instead of adding a new transport flow
3. auto-apply the goal transition in apply mode when the reflection action does not already carry a transition report
4. add one cross-repo regression that starts from the real monday memory scheduler path and ends at a queued goal-completion delivery item
```
