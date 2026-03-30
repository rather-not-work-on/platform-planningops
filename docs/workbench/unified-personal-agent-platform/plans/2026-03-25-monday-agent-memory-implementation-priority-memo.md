---
title: plan: MONDAY Agent Memory Implementation Priority Memo
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Compresses current memory research into a monday-owned implementation priority memo with strict planningops governance boundaries, a typed runtime memory contract, and a Codex-ready handoff shape.
related_docs:
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ../audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md
  - ../../../../planningops/contracts/memory-tier-contract.md
---

# plan: MONDAY Agent Memory Implementation Priority Memo

## Purpose

Compress current memory research into a practical implementation order for `monday`.

This memo answers four questions:

1. what matters now
2. what should be implemented immediately
3. what should be deferred
4. how to hand the work to Codex without producing a vague "memory system" rewrite

## Boundary

Two different memory domains now exist in the platform and must not be conflated.

### 1. `platform-planningops` memory

`platform-planningops` already has a repository-level document memory lifecycle through [memory-tier-contract.md](../../../../planningops/contracts/memory-tier-contract.md):

- `L0`: active working memory
- `L1`: canonical operational memory
- `L2`: historical archive

That contract governs document freshness, compaction, archive pointers, and repo-local retrieval.

### 2. `monday` runtime memory

`monday` needs a separate runtime memory contract for:

- session state
- durable retrieval
- typed long-term storage
- candidate versus promoted memory
- compaction and replay linkage
- evaluation of whether memory is helping execution

The main rule is:

- `monday` owns runtime memory formation, retrieval, compaction, and storage
- `platform-planningops` owns governance, validation requirements, and projection-only readiness gates

`platform-planningops` must not become a hidden runtime memory manager.

## What Matters Now

The strongest implementation priorities are below.

### 1. Typed memory beats "one vector store"

The official LangGraph and LangMem materials consistently separate short-term state from long-term memory and treat long-term memory as typed and namespaced rather than as one undifferentiated semantic bucket.

For `monday`, v1 should start with these runtime memory types:

| Memory type | Scope | Primary access mode | Notes |
| --- | --- | --- | --- |
| `SessionMemory` | `thread_id` | exact | current turn state and recent interaction history |
| `UserProfileStable` | `tenant_id/user_id` | exact | versioned facts promoted by confidence or explicit confirmation |
| `UserProfileVolatile` | `tenant_id/user_id` | semantic | recent preferences and soft context, decay-enabled |
| `ProjectState` | `tenant_id/project_id` | exact | durable mission and project continuity |
| `Task` / `OpenLoop` / `Decision` | `tenant_id/project_id/thread_id` | exact | explicit work continuity and control-plane-relevant execution state |
| `KnowledgeChunks` | `tenant_id/project_id` | semantic + keyword | raw chunk store with metadata retained |
| `SummaryMemory` | `thread_id` and `project_id` | exact + semantic | rolling thread/project summaries |
| `ToolLog` / `ArtifactRef` | `thread_id/run_id` | exact | append-only audit and evidence pointers |
| `WorkflowExamples` | `tenant_id/project_id` | semantic | successful few-shot exemplars and reusable execution patterns |

If the system starts with one pooled memory store, retrieval quality, deletion rules, and scope boundaries will drift almost immediately.

### 2. Retrieval quality matters more than clever write-time synthesis

Recent research signals suggest retrieval quality can move outcome quality more than increasingly sophisticated write-time memory construction.

This means v1 should keep `KnowledgeChunks` as raw chunks with metadata and embeddings instead of collapsing everything into aggressively distilled facts or summaries.

The safe baseline is:

- keep originals
- add derived summaries and promoted facts as sidecars
- rank retrieval quality above write-time elegance

### 3. Hot-path writes and background formation must be split

Official LangMem guidance explicitly distinguishes hot-path memory formation from background reflection and consolidation.

For `monday`, that means:

#### Hot path

Write immediately:

- raw session turns
- task status changes
- mission or decision changes
- tool logs
- hard constraints
- artifact references

#### Background

Reflect and consolidate after the turn:

- profile updates
- preference extraction
- workflow example distillation
- rolling summary updates
- candidate promotion or supersession

Do not make normal user responses wait on large memory consolidation passes.

### 4. Ingestion control is mandatory

Official Mem0 guidance is explicit that uncontrolled extraction produces clutter and poor retrieval.

`monday` v1 should therefore use a strict write path:

1. `always_write`
2. `candidate_write`
3. `promote_or_update`
4. `supersede_with_lineage`

The key rule is:

- never write a single uncertain fact straight into stable profile memory

Promotion should require one or more of:

- explicit user confirmation
- repeated evidence across turns
- high confidence extraction
- multi-source support
- recency superiority over the currently stored fact

### 5. Long context should be managed with compaction, not replay-only prompts

Official LangGraph and OpenAI Agents guidance both support managing long context through summarization and compaction.

`monday` v1 should define:

- `warn_threshold`
- `compact_threshold`
- `hard_cap`

Compaction output should be split into:

- `thread summary`
- `project summary`
- `recent unsummarized turns`

Compaction must preserve lineage to original records. Do not create a lossy summary-only system that drops source traceability.

### 6. Evaluation must be stage-wise, not only end-to-end

Recent streaming-memory evaluation work argues that memory systems need stage-level diagnosis, not just one final task score.

`monday` should ship with four evaluation layers:

- formation
- retrieval
- utilization
- forgetting and update

Otherwise the platform will not be able to distinguish:

- retrieval failure
- ranking failure
- stale-memory failure
- model utilization failure

## What Should Be Deferred

The following areas are promising, but they should be treated as `v2` experiments, not v1 baseline requirements.

### Defer to `v2`

- graph memory as a primary retrieval mechanism
- self-organizing memory topologies
- OS-style multi-tier virtual context systems
- aggressive write-time fact synthesis as the main storage format
- autonomous memory schema mutation

### Why defer

These ideas are useful research directions, but they add complexity before v1 has:

- typed stores
- scoped retrieval
- ingestion control
- compaction
- evaluation coverage

Until those basics are stable, advanced memory features mostly create harder debugging surfaces.

## Recommended `monday` v1 Contract

### Storage Contract

Every runtime memory record should declare:

- `memory_id`
- `memory_type`
- `tenant_id`
- `user_id`
- `project_id`
- `thread_id`
- `run_id`
- `session_id`
- `created_at`
- `updated_at`
- `confidence`
- `source_count`
- `lineage_refs`
- `promotion_state`

Recommended promotion states:

- `raw`
- `candidate`
- `promoted`
- `superseded`
- `archived`

### Retrieval Contract

Retrieval should run in this order:

1. exact fetch
2. semantic search
3. metadata filter
4. global rerank
5. context pack assembly

Global rerank should score at least:

- relevance
- recency
- confidence
- scope match
- explicit confirmation
- source count

Context packing should then separate:

- must include
- nice to include
- drop first

### Write Policy

#### Always-write

- raw turns
- tool logs
- task or decision changes
- artifact refs
- hard constraints

#### Candidate-write

- new facts
- inferred preferences
- entities
- workflow patterns

#### Promote or update

- stable profile facts
- rolling summaries
- reusable workflow examples

#### Delete and supersede

- never hard-delete originals without lineage metadata
- prefer supersede markers plus active-pointer updates

### Compaction Policy

Compaction should run between turns or in background jobs, not as an uncontrolled response-time tax.

Minimum v1 requirements:

- threshold-based compaction trigger
- thread summary replacement
- project summary rollup
- retention of recent unsummarized turns
- linkage back to original record ids
- explicit compaction artifact and status output

### PlanningOps Consumption Policy

`platform-planningops` should only validate projection surfaces derived from `monday` runtime memory.

Allowed:

- memory readiness reports
- compaction validation reports
- evaluation summaries
- projection-only status surfaces

Forbidden:

- direct control-plane mutation of runtime memory
- planningops-owned storage of monday mutable memory state
- using raw runtime memory rows as canonical control-plane truth

## Recommended Implementation Order

### Wave A: Contracts and storage primitives

Deliver:

- storage schema
- repository interfaces
- typed memory enums
- scoped key conventions
- append-only tool and evidence log surfaces

Success condition:

- `monday` can store and retrieve typed records deterministically by scope

### Wave B: Retrieval pipeline

Deliver:

- exact fetch layer
- semantic search layer
- metadata filtering
- global rerank
- context pack builder

Success condition:

- retrieval quality is measurable and explainable before fancy write-time synthesis exists

### Wave C: Controlled writes and promotion

Deliver:

- candidate memory path
- promotion policy
- update and supersede rules
- background formation job

Success condition:

- profile and summary memory stop drifting from noisy one-off turns

### Wave D: Compaction

Deliver:

- token threshold policy
- thread and project summaries
- compaction lineage
- between-turn compaction jobs

Success condition:

- prompt size stays bounded without deleting traceability

### Wave E: Evaluation harness

Deliver:

- formation fixtures
- retrieval fixtures
- utilization fixtures
- forgetting and update fixtures
- latency and token metrics

Success condition:

- memory failures are diagnosable by stage rather than guessed from one bad output

### Wave F: Defer-only experiments

Only after Waves A-E are stable:

- graph augmentation
- hierarchical memory experiments
- stronger synthesis or self-organization paths

## Codex Handoff Shape

Do not hand Codex a vague prompt like "build memory".

Give Codex an explicit contract:

```text
Build a memory-aware agent harness for monday.

Boundaries:
- monday owns runtime memory
- platform-planningops owns policy, evaluation requirements, and projection-only validation

Scopes:
- tenant_id
- user_id
- project_id
- thread_id

Memory types:
1) SessionMemory (exact, thread-scoped)
2) UserProfileStable (exact, versioned)
3) UserProfileVolatile (semantic, decay-enabled)
4) ProjectState / Task / OpenLoop / Decision (exact)
5) KnowledgeChunks (raw chunk + metadata + embeddings)
6) SummaryMemory (thread/project rolling summaries)
7) ToolLog / ArtifactRef (append-only)
8) WorkflowExamples (semantic retrieval)

Retrieval:
- exact fetch first
- semantic retrieval second
- metadata filter third
- global rerank fourth
- context pack last

Writes:
- always-write raw turns, tool logs, task/decision changes, artifact refs
- candidate-write new facts/preferences/entities
- promote only on confirmation or confidence policy
- never delete originals without lineage metadata

Compaction:
- support warn threshold, compact threshold, hard cap
- preserve source linkage
- compact between turns or in background jobs

Evaluation:
- formation tests
- retrieval tests
- utilization tests
- forgetting/update tests
- latency and token budget metrics

Deliverables:
- schema
- repository/service interfaces
- retrieval pipeline
- background promotion job
- compaction job
- evaluation harness
- README with architecture decisions
```

## Current Recommendation

If only one thing is done next, it should be this:

- build typed scoped stores and a retrieval-first harness before attempting graph memory or sophisticated memory synthesis

That is the highest-confidence v1 move across the official docs and the current research signal.

## Source Basis

Primary sources used for this memo:

- [LangGraph memory overview](https://docs.langchain.com/oss/python/langgraph/memory)
- [LangGraph add-memory guide](https://docs.langchain.com/oss/python/langgraph/add-memory)
- [LangMem conceptual guide](https://langchain-ai.github.io/langmem/concepts/conceptual_guide/)
- [Mem0 ingestion control guide](https://docs.mem0.ai/cookbooks/essentials/controlling-memory-ingestion)
- [Mem0 graph memory docs](https://docs.mem0.ai/platform/features/graph-memory)
- [OpenAI Agents Python sessions](https://openai.github.io/openai-agents-python/sessions/)
- [OpenAI Agents JS sessions](https://openai.github.io/openai-agents-js/guides/sessions/)
- [OpenReview: retrieval-vs-write memory signal](https://openreview.net/forum?id=cxYbqAtBIz)
- [OpenReview: StreamMemBench stage-wise evaluation](https://openreview.net/forum?id=i1gkKNMX0K)
- [MemGPT](https://arxiv.org/abs/2310.08560)
- [Oracle: database-first AI agent memory management](https://blogs.oracle.com/developers/comparing-file-systems-and-databases-for-effective-ai-agent-memory-management)

## Summary

The safe v1 posture is:

- typed memory, not one bucket
- retrieval-first quality, not write-time cleverness
- controlled ingestion, not automatic promotion
- compaction with lineage, not replay-only prompts
- stage-wise evaluation, not only end-to-end demos
- `monday` runtime ownership and `planningops` projection-only governance
