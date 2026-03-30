---
title: plan: MONDAY Agent Memory Wave F Completion Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next monday memory slice after scheduler execution: completed worker-outcome evidence and queue-row closure for successful background memory jobs.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-e-scheduler-execution-packet.md
  - ./2026-03-25-monday-agent-memory-wave-d-queue-admission-packet.md
---

# plan: MONDAY Agent Memory Wave F Completion Packet

## Purpose

Close the scheduler lifecycle for successful agent-memory background work by emitting worker-outcome evidence and transitioning queue rows from `leased` to `completed`.

## Scope

Wave F should add:

- monday-owned worker-outcome artifact emission for successful memory consolidation cycles
- queue-store completion transitions for successful memory jobs
- regression coverage that proves the queue row closes and evidence is written

Wave F should not yet add:

- planningops reflection export for memory worker outcomes
- dead-letter or retry policies for memory jobs
- automatic admission from every runtime run
- evaluation dashboards

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/run_scheduled_queue_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_run_scheduled_queue_cycle_memory_work_items.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/README.md`

## Acceptance Gates

- successful memory queue execution writes a valid `runtime-queue-worker-outcome` artifact
- the corresponding queue row becomes `completed`
- the completed queue row exposes `completion_evidence_ref`
- existing delivery work-item scheduler regressions remain green

## Codex Prompt

```text
Continue the monday memory-aware agent harness.

Current state:
- memory consolidation can be admitted into the scheduler queue
- scheduler execution can run the admitted memory work item
- queue rows still stay leased after successful execution

Implement Wave F only:
1. emit a valid completed worker-outcome artifact for successful memory jobs
2. update the local queue store from leased -> completed
3. keep the change scoped to the memory work-item path
4. add deterministic regression coverage
5. do not yet add retry/dead-letter automation for memory jobs
```
