# Active Goal Registry Contract

## Purpose
Provide one canonical machine-readable pointer to the current active goal so automation does not infer the active execution contract from stale backlog or ad hoc prompts.

## Canonical File
- `planningops/config/active-goal-registry.json`

## Required Top-Level Fields
- `registry_version`
- `active_goal_key`
- `goals`

## Goal Entry Fields
- `goal_key`
- `title`
- `status`
- `owner_repo`
- `goal_brief_ref`
- `execution_contract_file`
- `completion_contract_refs`
- `operator_channels`

## Status Rules
- Allowed statuses: `draft`, `active`, `blocked`, `achieved`, `archived`
- Exactly one goal may be `active`
- `active_goal_key` must match the unique `active` goal

## Reference Rules
- `goal_brief_ref` must resolve to an existing repo-relative file
- `execution_contract_file` must resolve to an existing repo-relative file
- Every `completion_contract_refs` entry must resolve to an existing repo-relative file

## Channel Rules
- `primary_operator_channel` is required
- `terminal_notification_channel` is required
- PlanningOps may describe channel policy, but execution ownership remains in `rather-not-work-on/monday`

## Usage Rules
- Supervisor/materialization automation must prefer the active goal registry over hard-coded contract paths when both are available.
- If the registry has no active goal, automation must stop with a review-required outcome instead of inventing a goal.

## Validation
- `planningops/scripts/validate_active_goal_registry.py`
- `planningops/scripts/core/goals/resolve_active_goal.py`
