---
title: plan: MONDAY Agent Memory Wave E Scheduler Execution Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next monday memory slice after queue admission: scheduler-native execution of admitted background memory consolidation work items.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-d-queue-admission-packet.md
  - ./2026-03-25-monday-agent-memory-wave-c-job-surface-packet.md
---

# plan: MONDAY Agent Memory Wave E Scheduler Execution Packet

## Purpose

Let monday scheduled queue execution run admitted agent-memory consolidation work items instead of stopping at admission-only artifacts.

## Scope

Wave E should add:

- scheduler-side normalization for memory consolidation work items
- a repo-owned execution wrapper for the TypeScript consolidation job
- scheduled queue regression coverage for one admitted memory work item
- machine-readable cycle reports that point at the underlying job report

Wave E should not yet add:

- worker-outcome transitions that mark memory work items completed
- planner-triggered automatic queue admission
- non-deterministic extraction or promotion logic
- evaluation dashboards

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/scheduler_memory_consolidation_work_items.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/run_agent_memory_consolidation_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/run_scheduled_queue_cycle.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_scheduler_memory_consolidation_work_items.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_run_scheduled_queue_cycle_memory_work_items.sh`

## Acceptance Gates

- scheduler queue can detect a memory consolidation work item from `work_payload_ref`
- queue execution runs the repo-owned wrapper, not raw ad hoc shell
- the wrapper executes `scripts/run_agent_memory_consolidation_job.ts` through the same local TypeScript runtime policy already used elsewhere in monday tests
- scheduler evidence remains schema-valid
- the underlying memory root is mutated by the scheduled run exactly once

## Codex Prompt

```text
Continue the monday memory-aware agent harness.

Current state:
- memory consolidation can be admitted into the monday scheduler queue
- admitted items currently stop at queue storage and are not executed by the scheduler cycle

Implement Wave E only:
1. add a scheduler-side memory work-item loader
2. add a repo-owned wrapper that runs the standalone consolidation job and emits a cycle report
3. wire scheduled queue execution so one dequeued memory work item actually runs
4. add deterministic regressions for the loader and scheduler execution path
5. do not yet add completion transitions or worker-outcome promotion for memory jobs
```
