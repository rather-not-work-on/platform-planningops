---
title: plan: MONDAY Agent Memory Wave C Job Surface Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next monday memory slice after deterministic consolidation: a queue-friendly consolidation job surface and first evaluation-seed artifacts.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-b-consolidation-packet.md
  - ./2026-03-25-monday-agent-memory-implementation-spec-and-wbs.md
---

# plan: MONDAY Agent Memory Wave C Job Surface Packet

## Purpose

Turn the in-process consolidation hook into a reusable job surface that a future queue or worker system can call without depending on `MissionOrchestrator`.

## Scope

Wave C should add:

- a standalone memory consolidation job entrypoint
- deterministic input/output packet shape
- a regression that proves the job can replay consolidation against a prepared memory root
- a first machine-readable report that can later feed evaluation and scheduling

Wave C should not yet add:

- real queue admission for memory jobs
- a durable scheduler lane for memory work
- full evaluation dashboards
- LLM-based extraction

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/src/agent_memory_consolidation_job.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/run_agent_memory_consolidation_job.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_run_agent_memory_consolidation_job.sh`

## Acceptance Gates

- the job surface can run without `MissionOrchestrator`
- it accepts explicit mission, run, session, and outcome payloads
- it emits a deterministic report with summary/promotion/open-loop outcomes
- it reuses the same consolidation rules as the in-process path
- no-memory callers remain unaffected

## Codex Prompt

```text
Continue the monday memory-aware agent harness.

Current state:
- retrieval, writeback, and deterministic consolidation already exist
- consolidation currently runs through an optional MissionOrchestrator seam

Implement Wave C only:
1. extract consolidation into a queue-friendly job surface
2. add a standalone script entrypoint that reads a job packet and writes a report
3. add deterministic tests for the job surface
4. keep the implementation repo-local and storage-local
5. do not add a real queue yet
```
