---
title: plan: MONDAY Agent Memory Implementation Spec and WBS
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Provides a Codex-ready implementation specification, work breakdown structure, and first execution prompt for monday runtime memory v1.
related_docs:
  - ./2026-03-25-monday-agent-memory-implementation-priority-memo.md
  - ./2026-03-23-monday-harness-capability-contract-draft.md
  - ./2026-03-23-monday-runtime-artifact-map-draft.md
  - ./2026-03-23-monday-planningops-evidence-projection-contract-draft.md
  - ../../../../planningops/contracts/memory-tier-contract.md
---

# plan: MONDAY Agent Memory Implementation Spec and WBS

## Purpose

Turn the memory research and priority memo into a Codex-ready packet that can be executed without another round of ambiguity reduction.

This document is intentionally implementation-shaped:

- implementation specification
- work breakdown structure
- execution rules
- first Codex prompt

## Boundary

This packet defines `monday` runtime memory, not `platform-planningops` document memory.

The split remains:

- `monday` owns runtime memory formation, retrieval, compaction, and storage
- `platform-planningops` owns governance, evaluation requirements, and projection-only validation

This must not be collapsed into a single "memory system" concept.

## Stack Pinning Rule

When this packet is handed to Codex, the implementation stack must be pinned explicitly.

For the current repo family, the default rule should be:

- prefer the existing `monday` repo-native runtime and storage conventions
- do not introduce a new Kotlin or Spring service boundary unless explicitly approved
- keep embeddings, vector search, and artifact storage behind swappable interfaces

If an operator wants a greenfield service in another language, that must be stated up front in the Codex prompt.

## 1. Goal

Build a memory-aware agent harness that:

- preserves session continuity
- maintains user and project memory across sessions
- retrieves only relevant context
- supports memory compaction
- exposes evaluation hooks for memory quality

## 2. In Scope

- thread-scoped session memory
- user profile memory: stable plus volatile
- project, task, open-loop, and decision memory
- knowledge chunk memory
- summary memory
- tool log and artifact reference memory
- workflow example memory
- retrieval pipeline
- write, promotion, and update pipeline
- compaction pipeline
- evaluation harness
- observability and admin or debug surfaces

## 3. Out of Scope for v1

- graph memory as the primary retrieval layer
- self-rewriting system prompts or procedural self-optimization
- automatic ontology generation
- full multi-agent coordination memory
- cross-tenant shared learning
- advanced privacy policy engines beyond scope isolation and simple filters

## 4. Design Principles

### 4.1 Event-log-first

- never store only distilled memories
- raw events and tool outputs must remain recoverable through lineage metadata

### 4.2 Exact before semantic

- hard constraints, active project state, open loops, and recent session turns are exact fetches
- semantic retrieval is used only where approximate similarity is actually useful

### 4.3 Candidate before promote

- new facts, preferences, and entities first land as candidates
- promotion to stable memory requires confidence or explicit confirmation

### 4.4 Version, do not overwrite blindly

- use `supersedes`, `version`, `valid_from`, `valid_to`, and `confidence`
- do not silently delete corrected memory without lineage

### 4.5 Compaction instead of replay

- long sessions should be summarized and compacted
- originals remain restorable through lineage metadata

### 4.6 Background consolidation

- session turn writes are synchronous
- profile consolidation, summary extension, and workflow distillation run asynchronously

### 4.7 Between-turn compaction as default

The default compaction mode should be between turns or in background jobs, not inline with streamed answer completion.

This follows the practical latency tradeoff signaled by the OpenAI Agents sessions guidance.

## 5. Proposed Architecture

### 5.1 Core Components

- Agent Harness
- Exact Store
- Semantic Store
- Artifact Store
- Background Memory Worker
- Compaction Worker
- Retrieval Engine
- Evaluation Harness

### 5.2 Recommended Baseline Stack

- Exact Store: PostgreSQL
- Semantic Store: PostgreSQL plus `pgvector`
- Artifact Store: S3 or MinIO-compatible object storage
- Cache: optional Redis
- Embeddings: configurable provider
- LLM: configurable provider
- App boundary: language-neutral storage and interface design even when implementation is repo-native

## 6. Memory Types

| Type | Scope | Storage | Access Pattern | Required Fields |
| --- | --- | --- | --- | --- |
| `SessionMemory` | tenant/user/project/thread | relational | exact | `id`, `tenant_id`, `user_id`, `project_id`, `thread_id`, `role`, `content`, `token_count`, `created_at`, `run_id`, `summary_id`, `metadata` |
| `UserProfileStable` | tenant/user | relational + versioned | exact + optional semantic | `id`, `tenant_id`, `user_id`, `key`, `value_json`, `confidence`, `source_refs`, `version`, `valid_from`, `valid_to`, `supersedes_id`, `metadata` |
| `UserProfileVolatile` | tenant/user/project | vector + metadata | semantic | `id`, `tenant_id`, `user_id`, `project_id`, `content`, `embedding`, `confidence`, `decay_score`, `last_used_at`, `metadata` |
| `ProjectState` | tenant/project | relational | exact | `id`, `tenant_id`, `project_id`, `current_state_json`, `updated_at`, `metadata` |
| `Task` | tenant/project | relational | exact | `id`, `tenant_id`, `project_id`, `title`, `status`, `owner`, `priority`, `due_at`, `metadata` |
| `OpenLoop` | tenant/project/thread | relational | exact | `id`, `tenant_id`, `project_id`, `thread_id`, `description`, `status`, `created_at`, `resolved_at`, `metadata` |
| `Decision` | tenant/project | relational | exact | `id`, `tenant_id`, `project_id`, `decision_text`, `rationale`, `source_refs`, `created_at`, `metadata` |
| `KnowledgeChunk` | tenant/user/project | vector + metadata | semantic | `id`, `tenant_id`, `user_id`, `project_id`, `source_type`, `source_ref`, `chunk_text`, `embedding`, `chunk_index`, `created_at`, `metadata` |
| `SummaryMemory` | tenant/user/project/thread | relational + optional vector | exact + semantic | `id`, `tenant_id`, `user_id`, `project_id`, `thread_id`, `summary_type`, `summary_text`, `source_refs`, `level`, `created_at`, `metadata` |
| `ToolLog` | tenant/user/project/thread/run | relational | exact | `id`, `run_id`, `tool_name`, `input_json`, `output_ref`, `status`, `created_at`, `metadata` |
| `ArtifactRef` | tenant/user/project/thread/run | relational | exact | `id`, `run_id`, `artifact_uri`, `artifact_type`, `checksum`, `created_at`, `metadata` |
| `WorkflowExample` | tenant/project/global-template | vector + metadata | semantic | `id`, `tenant_id`, `project_id`, `problem_type`, `steps_json`, `outcome`, `embedding`, `created_at`, `metadata` |

## 7. Storage Contract

### 7.1 Scope Keys

Every record must support these scope dimensions where applicable:

- `tenant_id`
- `user_id`
- `project_id`
- `thread_id`
- `run_id`

### 7.2 Lineage Metadata

Every mutable memory type must support:

- `source_refs`
- `confidence`
- `version`
- `supersedes_id`
- `valid_from`
- `valid_to`
- `created_at`
- `updated_at`

### 7.3 Required Guarantees

- multi-tenant isolation
- idempotent writes for repeated run callbacks
- strong lineage for updates and compaction
- no hard delete of important memory without an audit trail

## 8. Retrieval Contract

### 8.1 Inputs

- user query
- current scope: tenant, user, project, thread
- current run context
- token budget
- retrieval policy config

### 8.2 Retrieval Order

1. scope filter
   - narrow candidate space by `tenant_id`, `user_id`, `project_id`, and `thread_id`
2. mandatory exact fetch
   - recent unsummarized session turns
   - stable hard user constraints
   - active project state
   - open loops
   - unresolved decisions or tasks
3. typed semantic retrieval
   - volatile profile
   - knowledge chunks
   - summaries
   - workflow examples
4. global rerank
   - `relevance + recency + confidence + scope_match + usage_strength - contradiction_penalty`
5. context pack assembly
   - system constraints
   - project and task state
   - recent thread
   - retrieved memory snippets
   - workflow examples
   - optional summaries

### 8.3 Token Budget Rules

- never include large raw tool outputs directly when they exceed budget
- prefer artifact refs and distilled summaries
- prefer exact state over redundant historical detail

## 9. Write, Update, and Promotion Contract

### 9.1 Always-write

- session turns
- tool logs
- artifact refs
- task status changes
- decision changes
- project state changes

### 9.2 Candidate-write

- new preferences
- new facts
- new entities
- new inferred goals
- new open loops

### 9.3 Promote and consolidate

- candidate to stable profile
- session history to summary
- repeated action traces to workflow example
- corrected knowledge to superseding memory version

### 9.4 Update Rules

- prefer update or supersede over duplicate insert
- preserve previous memory version and mark it inactive with `valid_to`
- require a confidence threshold or explicit confirmation for promotion
- add `source_refs` for every promoted memory

## 10. Compaction Contract

### 10.1 Trigger Conditions

- session token count exceeds threshold
- message count exceeds threshold
- idle boundary reached
- explicit compaction requested

### 10.2 Compaction Output

- thread summary
- retained most recent `N` unsummarized turns
- summary linked to original source turn ids
- optional project summary extension

### 10.3 Compaction Rules

- run between turns, not inline with streamed answer completion
- preserve lineage to original events
- do not compact unresolved critical open loops into ambiguous summaries
- store summary level: `thread`, `episode`, or `project`

## 11. Harness Turn Loop

1. ingest user turn
2. append session event
3. extract candidate memories
4. retrieve context
5. build context pack
6. run model and tool loop
7. offload raw tool outputs to artifact storage
8. refresh context if memory mutated during tool execution
9. persist assistant turn
10. schedule background consolidation
11. compact if threshold exceeded

## 12. API Contract

### 12.1 Repository Interfaces

- `appendSessionTurn(input)`
- `listRecentSessionTurns(scope, limit)`
- `listUnsummarizedSessionTurns(scope, limit)`
- `createSummary(input)`
- `linkTurnsToSummary(turn_ids, summary_id)`
- `upsertProjectState(input)`
- `upsertTask(input)`
- `upsertOpenLoop(input)`
- `upsertDecision(input)`
- `createCandidateMemory(input)`
- `promoteCandidateMemory(input)`
- `supersedeMemory(input)`
- `searchKnowledge(input)`
- `searchVolatileProfile(input)`
- `searchWorkflowExamples(input)`
- `appendToolLog(input)`
- `appendArtifactRef(input)`

### 12.2 Service Interfaces

- `ingestTurn(input)`
- `buildContextPack(input)`
- `retrieveExactContext(input)`
- `retrieveSemanticContext(input)`
- `rerankMemoryHits(input)`
- `compactThread(input)`
- `scheduleBackgroundConsolidation(input)`
- `evaluateMemoryRun(input)`

## 13. Evaluation Contract

### 13.1 Test Categories

1. formation tests
   - was the right candidate memory extracted
   - was unsafe or low-confidence content rejected
2. retrieval tests
   - was the right memory retrieved for the given scope
   - were irrelevant memories excluded
3. utilization tests
   - did the model answer correctly using retrieved memory
   - did project and open-loop state affect the answer
4. update and forget tests
   - does corrected information supersede outdated memory
   - are stale volatile memories decayed or ignored
5. compaction tests
   - does compaction preserve critical context
   - can lineage be traced from summary to originals

### 13.2 Metrics

- retrieval `precision@k`
- retrieval `recall@k`
- memory utilization accuracy
- contradiction rate
- stale-memory usage rate
- average tokens per run
- average retrieval latency
- average compaction latency

## 14. Non-Functional Requirements

- deterministic tests for retrieval and promotion logic
- structured logs for every memory mutation
- admin or debug surfaces for per-scope memory inspection
- replayable run traces
- configurable thresholds for promotion and compaction
- swappable embedding and LLM providers
- safe fallback when vector search is unavailable

## 15. Deliverables

- database schema plus migrations
- domain models
- repository layer
- service layer
- retrieval engine
- compaction worker
- background consolidation worker
- evaluation suite
- admin or debug endpoints
- README with architecture rationale
- sample fixtures and example runs

---

# Work Breakdown Structure

| ID | Workstream | Tasks | Depends On | Done Criteria |
| --- | --- | --- | --- | --- |
| `W01` | Repo Bootstrap | initialize project, config, env loading, dependency wiring, test scaffold | none | project builds, tests run, config loads |
| `W02` | Schema Design | define tables, vector indexes, lineage fields, migrations | `W01` | migrations apply cleanly on empty DB |
| `W03` | Domain Models | define memory entities, DTOs, validation schemas, enums | `W02` | models compile and validate sample payloads |
| `W04` | Repository Layer | implement CRUD and search repositories for each memory type | `W03` | repository integration tests pass |
| `W05` | Session Memory | append turns, fetch recent turns, fetch unsummarized turns, summary linking | `W04` | thread restore and summary linkage tests pass |
| `W06` | Project State Memory | implement project, task, open-loop, and decision stores and services | `W04` | exact state retrieval tests pass |
| `W07` | Long-Term Memory | implement stable and volatile profile, knowledge chunks, workflow examples | `W04` | insert, search, update, and supersede tests pass |
| `W08` | Retrieval Engine | scope filter, exact fetch, semantic search, rerank, context packer | `W05`, `W06`, `W07` | retrieval contract tests pass |
| `W09` | Write and Promotion Pipeline | candidate extraction, confidence gating, promotion, supersede logic | `W07` | promotion and update regression tests pass |
| `W10` | Tool Log and Artifact Handling | raw output offload, artifact refs, tool log appenders | `W04` | large tool outputs no longer bloat prompt path |
| `W11` | Compaction Pipeline | thresholds, summary generation, lineage preservation, restore helpers | `W05`, `W10` | compaction tests pass and lineage is preserved |
| `W12` | Harness Integration | ingest, retrieve, run, persist, schedule consolidation | `W08`, `W09`, `W10`, `W11` | end-to-end conversation tests pass |
| `W13` | Background Workers | delayed consolidation, debounce, compaction scheduler | `W09`, `W11`, `W12` | background jobs execute idempotently |
| `W14` | Evaluation Harness | formation, retrieval, utilization, and forget tests, metrics collection | `W12` | evaluation suite runs in CI |
| `W15` | Observability and Admin | debug APIs, memory inspection views, structured logs, metrics | `W12` | operator can inspect memory state by scope |
| `W16` | Hardening and Docs | README, example configs, sample runs, failure modes, runbooks | `W14`, `W15` | docs are sufficient to run locally and debug |

---

# Codex Execution Rules

1. implement one WBS item per PR
2. do not invent extra memory types without explicit approval
3. preserve lineage metadata everywhere
4. write tests before or alongside repository and service logic
5. keep provider integrations behind interfaces
6. do not stuff large tool outputs directly into prompts
7. prefer exact state retrieval over semantic retrieval where possible
8. use background workers for consolidation and promotion
9. never hard delete important memories in v1
10. emit debug logs for every memory mutation

# Definition of Done

- all migrations pass
- all tests pass
- retrieval contract is implemented
- compaction preserves lineage
- outdated memories can be superseded safely
- end-to-end demo shows:
  - session continuity
  - user preference recall
  - project task and open-loop continuity
  - knowledge retrieval
  - compaction without loss of critical context

## First Codex Prompt

Use this when opening the first implementation wave.

```text
Implement W01-W04 for the monday memory-aware agent harness inside the existing monday repo/runtime. Do not introduce a new service language or framework unless explicitly required by the current repo.

Scope:
- W01 Repo Bootstrap
- W02 Schema Design
- W03 Domain Models
- W04 Repository Layer

Required memory types in this wave:
- SessionMemory
- UserProfileStable
- UserProfileVolatile
- ProjectState
- Task
- OpenLoop
- Decision
- KnowledgeChunk
- SummaryMemory
- ToolLog
- ArtifactRef
- WorkflowExample

Hard constraints:
- preserve lineage metadata on all mutable memory types
- use exact store + semantic store abstractions
- keep embeddings/vector search behind interfaces
- write tests before or alongside implementation
- leave retrieval engine, compaction worker, and background consolidation as stubs if needed, but define their interfaces now

Deliverables:
- repo bootstrap and config wiring
- schema/migration set
- domain models and validation schemas
- repository interfaces and first concrete implementations
- integration tests for CRUD, scoped reads, and version/supersede behavior
- README section documenting storage contract decisions

Do not implement W05+ in this wave.
```

## Source Basis

Primary source basis for this packet:

- [LangGraph memory overview](https://docs.langchain.com/oss/python/langgraph/memory)
- [LangGraph add-memory guide](https://docs.langchain.com/oss/python/langgraph/add-memory)
- [LangMem conceptual guide](https://langchain-ai.github.io/langmem/concepts/conceptual_guide/)
- [Mem0 ingestion control guide](https://docs.mem0.ai/cookbooks/essentials/controlling-memory-ingestion)
- [OpenAI Agents Python sessions](https://openai.github.io/openai-agents-python/sessions/)
- [OpenAI Agents JS sessions](https://openai.github.io/openai-agents-js/guides/sessions/)

Research signals carried into prioritization:

- [OpenReview retrieval-versus-write signal](https://openreview.net/forum?id=cxYbqAtBIz)
- [OpenReview StreamMemBench](https://openreview.net/forum?id=i1gkKNMX0K)
- [MemGPT](https://arxiv.org/abs/2310.08560)
