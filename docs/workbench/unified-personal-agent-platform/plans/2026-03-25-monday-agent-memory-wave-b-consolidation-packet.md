---
title: plan: MONDAY Agent Memory Wave B Consolidation Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Converts the generic memory spec into the next monday implementation slice after Wave A: runtime writeback, candidate extraction, thread compaction, and optional background-style consolidation seams.
related_docs:
  - ./2026-03-25-monday-agent-memory-implementation-priority-memo.md
  - ./2026-03-25-monday-agent-memory-implementation-spec-and-wbs.md
  - ./2026-03-25-monday-agent-memory-wave-a-kickoff-packet.md
---

# plan: MONDAY Agent Memory Wave B Consolidation Packet

## Purpose

Absorb the generic implementation specification into the current repo reality after the first runtime-memory slices have already landed in `monday`.

This packet exists because the repo is no longer at a blank `W01-W04` starting point.

`monday` now already has:

- typed memory contracts
- deterministic local memory store
- exact-first retrieval and context-pack assembly
- mission-input enrichment for planner and executor
- mission writeback for `session_memory`, `tool_log`, and `artifact_ref`

The next meaningful slice is therefore not "introduce memory types" again.

It is:

- candidate extraction
- optional stable promotion
- thread compaction under orchestration control
- background-style consolidation seams

## Current State Snapshot

Implemented in `monday` today:

- Wave A local store and repository baseline
- exact-first retrieval + semantic context-pack
- planner and provider prompt memory injection
- mission-level memory writeback

Still intentionally thin:

- no live Postgres or `pgvector`
- no durable worker queue for memory jobs
- no broad heuristic extraction set
- no full evaluation harness
- no admin/debug inspection surface beyond local files

## Wave B Scope

Wave B should cover the first deterministic background-memory slice:

1. extract candidate memories from runtime turns and outcomes
2. optionally promote explicit stable preferences
3. compact thread history between turns
4. expose an optional consolidation port on the orchestrator
5. keep everything deterministic and repo-local

Wave B should not yet attempt:

- full semantic candidate extraction from arbitrary documents
- LLM-based summarization
- remote worker queues
- global memory eval dashboards
- cross-run learning beyond the local mission scope

## Mapping Back To The Generic WBS

This packet advances these generic workstreams:

- `W09` Write/Promotion Pipeline
- `W11` Compaction Pipeline
- part of `W12` Harness Integration
- first slice of `W13` Background Workers

## Repo Targets

Primary files should live in:

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/src/agent_memory_consolidation.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/src/mission_orchestrator.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/src/orchestrator_ports.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/run_agent_memory_consolidation_smoke.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_agent_memory_consolidation.sh`

Secondary touch points may include:

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/run_profiled_mission_runtime.ts`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/README.md`

## Recommended Deterministic Behavior

### Candidate Extraction

Start with deterministic heuristics only.

Good first patterns:

- explicit user preference sentences
- blocker or waiting phrases that can become `OpenLoop`
- repeated thread turns that should be compacted into `SummaryMemory`

### Stable Promotion

Only promote when the input is explicit enough.

Safe v1 examples:

- "I prefer concise markdown summaries."
- "Use bullet points for operator updates."

Promotion should:

- preserve lineage
- use existing supersede rules
- remain opt-in through a clear policy flag

### Compaction

Use between-turn compaction only.

The compaction layer should:

- create `SummaryMemory`
- link compacted turn ids
- retain newest unsummarized turns
- avoid compacting unresolved critical context into nothing

## Acceptance Gates

Wave B is complete only if:

- a runtime path can write session turns, tool logs, and artifact refs
- a runtime path can also trigger deterministic consolidation
- explicit preference extraction can create and optionally promote stable memory
- blocker extraction can create `OpenLoop` candidates
- thread compaction preserves lineage
- all new seams remain optional and do not break no-memory callers

## Codex Prompt For Wave B

Use this when handing Wave B to Codex:

```text
Continue the monday memory-aware agent harness.

Current state:
- typed memory contracts exist
- deterministic local memory store exists
- retrieval/context-pack exists
- mission input enrichment exists
- mission writeback exists for session/tool/artifact records

Implement Wave B only:
1. add deterministic memory consolidation
2. extract candidate memories from runtime turns/outcomes
3. optionally promote explicit stable preferences
4. compact session threads between turns
5. keep the seam optional in MissionOrchestrator
6. add targeted smoke tests and README updates

Constraints:
- stay inside the existing monday TypeScript workspace
- do not introduce new services
- keep provider integrations behind interfaces
- preserve lineage metadata
- avoid LLM-based extraction in this wave
- use deterministic heuristics and local-store tests only
```

## Why This Packet Exists

The generic implementation spec is still correct.

But the correct next move for the current repo is no longer `W01`.

It is the first real consolidation slice that turns read/write memory plumbing into a memory lifecycle.
