# Autonomous Scheduler Queue Control-Plane Contract

## Purpose
Freeze the canonical boundary between `platform-planningops` policy orchestration and the future `monday` scheduler/queue runtime.

This contract exists so:
- `planningops` remains the control tower and single source of truth
- `monday` becomes the long-term scheduler host instead of Codex recurring automation
- queue runtime growth does not pull daemon, lease, or transport behavior back into `planningops`

## Ownership Boundary

### PlanningOps owns
- goal briefs
- active-goal registry
- execution contracts
- schedule intent and recurrence policy
- queue admission policy
- retry and escalation policy
- reflection and replan policy
- completion policy

### PlanningOps must not own
- scheduler daemon host
- queue persistence backend
- lease or heartbeat implementation
- worker dispatch loop
- Slack or email transport implementation

### Monday owns
- scheduler runtime
- queue persistence
- lease and heartbeat management
- dequeue, dispatch, and completion recording
- retry wait and dead-letter execution
- operator-channel delivery adapters

### Platform-Contracts owns
Only shared schemas that genuinely cross repo boundaries:
- queue item schema
- scheduler event schema
- lease lifecycle schema
- dead-letter record schema

## Queue State Model
The canonical queue state vocabulary is:
- `scheduled`
- `ready`
- `leased`
- `running`
- `blocked`
- `retry_wait`
- `dead_letter`
- `completed`

PlanningOps may reference these states in policy, but monday owns the runtime transitions.

## Scheduling Trigger Model
The canonical trigger families are:
- recurring schedule tick
- one-shot goal activation
- dependency-unblock wake
- retry-after wake
- reflection-triggered replan insertion
- manual operator injection

PlanningOps defines which triggers are allowed and when they should enqueue work.
Monday decides how those triggers are materialized and executed at runtime.

## Required Queue Policy Fields
PlanningOps-generated queue-ready policy must eventually be able to describe:
- `goal_key`
- `schedule_key`
- `priority_class`
- `idempotency_key`
- `dependency_keys`
- `retry_budget`
- `escalation_policy_ref`
- `completion_policy_ref`

These fields are policy inputs.
Monday may extend repo-local runtime metadata, but must not redefine the meaning of the policy fields above.

## Reflection and Escalation Rules
Every monday-owned scheduler cycle must be able to feed deterministic evidence back into planningops for:
- verification failure
- retry exhaustion
- dead-letter transition
- unresolved dependency drift
- backlog exhaustion without eligible follow-up work
- achieved goal with no promoted successor

PlanningOps uses that evidence to:
- replenish backlog
- promote or pause goals
- escalate to the operator
- emit terminal completion policy

## Operator Channel Boundary
- planningops decides whether operator status or terminal completion should happen
- monday performs the actual operator delivery through repo-owned CLI or MCP adapters
- scheduler/queue work must remain compatible with:
  - `planningops/contracts/operator-channel-adapter-contract.md`
  - `planningops/contracts/goal-completion-contract.md`
  - `planningops/contracts/supervisor-operator-handoff-contract.md`

## Local-First Runtime Rule
The first durable scheduler/queue runtime must be local-first:
- default backend: SQLite in `monday`
- entrypoint shape: repo-owned CLI first
- no distributed coordinator requirement in this phase

PlanningOps must model policy so that migrating the backend later does not require redefining queue semantics.

## Migration Rule
Codex recurring automation is a temporary host only.

The intended migration path is:
1. planningops emits policy and active-goal truth
2. monday runs the durable scheduler and queue cycle
3. monday returns deterministic evidence to planningops
4. planningops decides promotion, replenishment, escalation, and completion

## Validation
- roadmap reference: `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-autonomous-scheduler-queue-control-plane-plan.md`
- wave goal brief: `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave4-goal-brief.md`
- contract regression: `planningops/scripts/test_autonomous_scheduler_queue_control_plane_contract.sh`
