---
title: plan: MONDAY Agent Memory Wave H Control-Plane Reflection Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next planningops slice after monday memory reflection export: the control-plane reflection runner must accept monday scheduler evidence directly for completed memory jobs.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-g-reflection-packet.md
  - ./2026-03-25-monday-agent-memory-wave-f-completion-packet.md
---

# plan: MONDAY Agent Memory Wave H Control-Plane Reflection Packet

## Purpose

Let `planningops` start the reflection cycle from monday scheduler evidence for completed memory consolidation jobs without reopening monday queue internals or requiring a separate worker-outcome handoff artifact.

## Scope

Wave H should add:

- one planningops-owned reflection-cycle path that accepts either a monday worker outcome artifact or a monday scheduler report
- deterministic control-plane regression coverage using the real monday memory queue execution path
- contract and README updates that pin the scheduler-evidence start point as part of the canonical reflection runner

Wave H should not yet add:

- automatic delivery-cycle execution for memory reflection outcomes
- a new memory-specific reflection decision vocabulary
- scheduler-native planningops batching over multiple memory work items

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_worker_outcome_reflection_cycle_scheduler_report.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/contracts/reflection-cycle-orchestration-contract.md`

## Acceptance Gates

- the planningops reflection runner accepts `--scheduler-report-json` as an alternative to `--outcome-json`
- scheduler-report mode uses `monday/scripts/export_scheduler_worker_outcome_reflection_packet.py` instead of re-deriving packet fields inline
- the cycle report preserves monday-owned `worker_outcome_ref` as `source_outcome_ref`
- the real monday memory queue path produces a `goal_achieved` reflection decision through the planningops cycle runner

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops reflection chain.

Current state:
- monday memory scheduler runs already emit completed worker-outcome evidence
- monday can already export a reflection packet from scheduler evidence
- planningops can already run a reflection cycle from a raw worker outcome

Implement Wave H only:
1. extend the planningops reflection-cycle runner so it accepts monday scheduler evidence directly
2. keep raw worker-outcome mode working exactly as-is
3. add one cross-repo regression using the real monday memory queue path
4. do not add delivery-cycle automation for memory outcomes yet
```
