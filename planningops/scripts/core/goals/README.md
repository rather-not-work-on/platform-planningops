# planningops/scripts/core/goals

## Purpose
Hold recurring goal-resolution logic for the control plane.

## Contents
- `resolve_active_goal.py`
  - Canonical entrypoint for resolving the active goal registry into a concrete execution contract and channel policy payload.

## Rules
- Goal resolution must be deterministic and file-backed.
- The active goal registry is the first source of truth for autonomous execution when no explicit contract path is supplied.
