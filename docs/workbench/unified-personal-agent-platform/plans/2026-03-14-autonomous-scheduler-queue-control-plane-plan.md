---
title: plan: Autonomous Scheduler and Queue Control Plane Roadmap
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines how UAP autonomy graduates from Codex-hosted recurring automation to a monday-owned scheduler and queue runtime with local-first durability, deterministic reflection, and operator-channel completion handling.
tags:
  - uap
  - autonomy
  - scheduler
  - queue
  - planningops
  - monday
  - slack
  - email
---

# Autonomous Scheduler and Queue Control Plane Roadmap

## Purpose

Move from "Codex automation triggers PlanningOps scripts" to a durable runtime where:
- `planningops` remains the control tower and single source of truth for goals, contracts, queue policy, and completion rules
- `monday` owns the actual scheduler, queue persistence, worker leasing, dispatch, retries, and operator-channel delivery
- Slack/email remain thin wrappers over monday-owned CLI or MCP surfaces

This roadmap is the migration plan for that change. It is not a permission to move scheduler runtime into `platform-planningops`.

## Current Baseline

Today the platform already has:
- an autonomous supervisor loop in `platform-planningops`
- active-goal registry and successor-goal promotion
- backlog materialization from execution contracts
- monday-owned operator-channel CLI baselines for status and completion delivery
- a historical scheduler queue baseline in `monday` proving dequeue, duplicate detection, and dependency blocking

What is still missing:
- a durable monday-owned schedule registry and execution queue
- lease, heartbeat, retry-budget, and dead-letter semantics
- a canonical policy boundary between "goal selection" and "queue dispatch"
- a path that no longer depends on Codex recurring automation as the long-term scheduler host

## Target End State

The desired steady state is:
1. operator or upstream trigger creates or updates an active goal
2. `planningops` compiles goal intent into executable policy and queue-ready work definitions
3. `monday` scheduler materializes, leases, runs, retries, and completes queued work
4. post-run reflection feeds back into `planningops` through deterministic evidence
5. monday sends operator status and terminal completion notifications through repo-owned channel adapters
6. when a goal is achieved, terminal email is sent once and the system waits for the next goal or schedule tick

## Ownership Boundary

### `platform-planningops`

Owns:
- goal briefs
- active-goal registry
- execution contracts
- queue admission rules
- scheduling policy and recurrence intent
- retry/escalation policy
- reflection and replan policy
- completion policy

Must not own:
- production scheduler daemon
- queue storage backend
- worker leasing implementation
- Slack or mail transport implementation

### `monday`

Owns:
- scheduler runtime
- queue persistence
- lease and heartbeat management
- worker dispatch
- retry and dead-letter execution
- operator-channel adapters
- terminal notification delivery

Must not own:
- global planning policy
- canonical backlog semantics
- control-plane truth for goal completion

### `platform-contracts`

Owns only shared schemas that genuinely cross repos:
- queue item schema
- scheduler event schema
- lease lifecycle schema
- dead-letter record schema
- run completion envelope schema when shared across planningops and monday

### `platform-provider-gateway` and `platform-observability-gateway`

Remain execution dependencies only:
- provider invocation and routing
- observability ingest, replay, and delivery

They should not become the queue orchestrator.

## Queue Model

The long-term queue model must support these states:
- `scheduled`
- `ready`
- `leased`
- `running`
- `blocked`
- `retry_wait`
- `dead_letter`
- `completed`

Each queue item must eventually carry:
- `queue_item_id`
- `goal_key`
- `schedule_key`
- `idempotency_key`
- `priority_class`
- `lease_owner`
- `lease_expires_at_utc`
- `retry_budget_remaining`
- `attempt_count`
- `dependency_keys`
- `blocked_reason`
- `dead_letter_reason`
- `completion_evidence_ref`

## Scheduling Model

The scheduler must support these trigger families:
- recurring schedule tick
- one-shot goal activation
- dependency-unblock wake
- retry-after wake
- reflection-triggered replan insertion
- manual operator injection

The first implementation should be local-first and durable:
- queue backend: SQLite inside `monday`
- scheduler loop: repo-owned CLI entrypoint first
- no distributed coordinator in the first phase

This is the right default because it maximizes debuggability, keeps state explicit, and avoids premature infra decisions.

## Reflection and Self-Supervision Loop

Reflection is not a side feature. It is part of the queue contract.

Every scheduler cycle must be able to answer:
1. did a leased item finish, block, retry, or dead-letter?
2. did verification pass?
3. does the result require replan or backlog replenishment?
4. should the active goal be promoted, paused, or escalated?
5. should monday notify Slack now, email once, or stay silent?

Reflection triggers must include at least:
- verification failure
- repeated retry exhaustion
- dead-letter transition
- unresolved dependency drift
- backlog exhaustion without eligible follow-up work
- achieved goal with no promoted successor

## Operator Interaction Model

Operator interaction should converge to:
- human <-> Slack
- Slack skill -> monday-owned CLI or MCP adapter
- monday -> planningops control-plane artifacts
- planningops never sends channel messages directly

Terminal completion policy remains:
- completion is decided by `planningops`
- delivery is performed by `monday`
- email is sent once when goal transitions to `achieved`

## Migration Phases

### Phase 0: Baseline Already Present

- Codex-hosted automation triggers the current supervisor loop
- active-goal promotion exists
- monday operator-channel CLI baselines exist
- historical monday scheduler queue smoke exists

### Phase 1: Contract Freeze

Freeze:
- scheduler and queue control-plane boundary
- shared queue schemas
- monday queue runtime topology
- retry, lease, heartbeat, dead-letter vocabulary

### Phase 2: Monday Local Queue Runtime

Implement in `monday`:
- local SQLite-backed queue store
- lease and heartbeat baseline
- scheduler cycle CLI
- worker dequeue and completion recording

### Phase 3: PlanningOps Policy Integration

Connect:
- goal registry
- execution contract compiler
- queue admission and recurrence policy
- materialized queue insertion

### Phase 4: Self-Supervised Reflection Integration

Add:
- retry-budget aware reflection
- dead-letter to replan mapping
- automatic backlog replenishment triggers
- successor-goal promotion from queue completion signals

### Phase 5: Operator Surface Integration

Upgrade monday so Slack and email are not just standalone CLIs but queue-aware delivery surfaces:
- status updates keyed by goal/run
- blocked reports keyed by queue item
- terminal completion idempotency by goal achievement

### Phase 6: Externalized Runtime Backends

Only after the local-first model is stable:
- move queue storage to Postgres or managed durable backend if needed
- add object storage or external event sink where it clearly reduces risk
- preserve the same contracts and state model

## Decisions Fixed Now

- `planningops` remains policy and memory, not scheduler runtime
- `monday` owns scheduler and queue execution
- local-first SQLite is the default first backend
- Slack and email remain thin wrappers over monday-owned CLI or MCP surfaces
- migration must preserve deterministic evidence and replayability

## Explicitly Deferred

- distributed queue infrastructure
- Redis-first or cloud-first scheduler design
- direct Slack intake changing active goals before queue/runtime semantics are stable
- replacing CLI boundaries with MCP before CLI proves insufficient

## Next Planning Step

The next successor goal after wave 3 should freeze the scheduler/queue foundation as wave 4:
- goal brief: `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave4-goal-brief.md`
- issue pack: `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave4-issue-pack.md`
- execution contract: `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave4.execution-contract.json`
