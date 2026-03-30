---
title: plan: MONDAY Agent Memory Wave D Queue Admission Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next monday memory slice after the standalone consolidation job surface: deterministic scheduler-queue admission artifacts for background memory work.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-c-job-surface-packet.md
  - ./2026-03-25-monday-agent-memory-implementation-spec-and-wbs.md
---

# plan: MONDAY Agent Memory Wave D Queue Admission Packet

## Purpose

Turn the standalone memory consolidation job into an explicit monday-owned scheduled queue item so background memory work is admitted through the same queue policy surface as other runtime work.

## Scope

Wave D should add:

- a monday-local queue admission helper for memory consolidation job packets
- repo-local runtime-artifact copies of admitted job inputs
- deterministic queue work-item artifacts and queue-item refs
- apply and dry-run regression coverage

Wave D should not yet add:

- scheduler execution of memory consolidation queue items
- queue-native worker outcome evidence for memory jobs
- durable evaluation dashboards
- non-deterministic extraction or promotion logic

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/enqueue_memory_consolidation_work_item.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_enqueue_memory_consolidation_work_item.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/README.md`

## Acceptance Gates

- queue admission accepts the standalone memory consolidation job input packet
- admission writes a repo-local payload artifact and work-item artifact under `runtime-artifacts/`
- apply mode seeds the monday SQLite queue store with a valid queue item
- dry-run mode emits the same artifacts and report without mutating the queue store
- queue item, work-item, and report all point at `scripts/run_agent_memory_consolidation_job.ts`

## Codex Prompt

```text
Continue the monday memory-aware agent harness.

Current state:
- deterministic memory consolidation already exists
- a standalone consolidation job packet and TypeScript runner already exist

Implement Wave D only:
1. add a monday-local helper that admits a consolidation job packet into the scheduled queue store
2. persist repo-local runtime-artifact copies of the job payload and work-item
3. emit a deterministic machine-readable admission report
4. add apply and dry-run regression coverage
5. do not yet extend the scheduler cycle to execute memory queue items
```
