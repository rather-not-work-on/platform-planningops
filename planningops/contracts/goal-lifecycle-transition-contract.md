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
- Exactly one goal may be `active` after the transition completes.
- `active_goal_key` must always match the unique active goal.
- `active -> achieved` requires completion evidence that satisfies `planningops/contracts/goal-completion-contract.md`.
- `active -> blocked` requires a concrete blocker reason and evidence reference.
- `achieved -> archived` requires the goal to keep its completion references and execution contract path for audit lookup.
- `draft -> active` or `blocked -> active` requires every referenced file in the goal entry to exist.

## Promotion Rules
- When an `active` goal transitions to `achieved`, automation may promote the next goal only if a single candidate is explicitly selected.
- Promotion must never reopen or reuse issues belonging to an `achieved` goal.
- If no next goal is available, automation must stop with a compact completion summary instead of falling back to stale contract materialization.

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
- Supervisor logic must treat an exhausted active goal without a promoted successor as `replan_required`, not `quality_gate_fail`.

## Validation Targets
- `planningops/scripts/validate_active_goal_registry.py`
- `planningops/scripts/core/goals/resolve_active_goal.py`
- `planningops/scripts/core/goals/transition_goal_state.py` (follow-up)
