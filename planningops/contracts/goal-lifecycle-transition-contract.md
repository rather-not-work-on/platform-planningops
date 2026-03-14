# Goal Lifecycle Transition Contract

## Purpose
Define the only allowed state transitions for the active goal registry so automation can promote the next goal without reusing stale backlog or inventing ad hoc goal state.

## Canonical Boundary
- registry file: `planningops/config/active-goal-registry.json`
- resolver: `planningops/scripts/core/goals/resolve_active_goal.py`
- follow-up mutator: `planningops/scripts/core/goals/transition_goal_state.py`

## Allowed Goal States
- `draft`
- `active`
- `blocked`
- `achieved`
- `archived`

## Allowed Transitions
- `draft -> active`
- `draft -> archived`
- `active -> blocked`
- `active -> achieved`
- `blocked -> active`
- `blocked -> archived`
- `achieved -> archived`

Transitions outside this list are invalid and must fail closed.

## Transition Preconditions
- At most one goal may be `active` after the transition completes.
- `active_goal_key` must match the unique active goal when one exists.
- `active_goal_key` must be empty when a transition intentionally leaves the registry without an active goal.
- `active -> achieved` requires completion evidence that satisfies `planningops/contracts/goal-completion-contract.md`.
- `active -> blocked` requires a concrete blocker reason and evidence reference.
- `achieved -> archived` requires the goal to keep its completion references and execution contract path for audit lookup.
- `draft -> active` or `blocked -> active` requires every referenced file in the goal entry to exist.

## Promotion Rules
- When an `active` goal transitions to `achieved`, automation may promote the next goal only if a single candidate is explicitly selected.
- Promotion must never reopen or reuse issues belonging to an `achieved` goal.
- If no next goal is available, automation must stop with a compact completion summary instead of falling back to stale contract materialization.
- `active -> achieved` without a successor is allowed only when automation intentionally hands control back to operator channels for the next goal brief.

## Evidence Rules
- Every transition attempt must emit:
  - `goal_key`
  - `from_status`
  - `to_status`
  - `transition_reason`
  - `transition_timestamp_utc`
  - `evidence_refs`
  - `verdict`
- Transition evidence must be deterministic for the same input registry and requested transition.

## Ownership Boundary
- PlanningOps owns:
  - lifecycle policy
  - state transition validation
  - registry mutation evidence
- Monday owns:
  - operator-facing notifications that may result from an `achieved` transition

## Failure Rules
- Invalid transitions must not mutate the registry.
- Transition validation failure must return a blocked review outcome, not silent fallback.
- Supervisor logic must attempt goal transition before closed-issue replanning when the active goal is exhausted.
- Supervisor logic must treat an exhausted active goal without a promoted successor as goal completion or `replan_required`, never `quality_gate_fail`.

## Validation Targets
- `planningops/scripts/validate_active_goal_registry.py`
- `planningops/scripts/core/goals/resolve_active_goal.py`
- `planningops/scripts/core/goals/transition_goal_state.py`
