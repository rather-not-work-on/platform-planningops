# Goal Brief Contract

## Purpose
Define the canonical problem statement that turns a user-level objective into a control-plane managed active goal.

## Required Fields
- `goal_key`
- `title`
- `objective`
- `success_outcomes`
- `non_goals`
- `operator_channels`
- `completion_contract_refs`
- `execution_contract_file`

## Rules
- A goal brief must describe the desired outcome, not an implementation checklist.
- A goal brief must identify the primary operator channel and terminal notification channel.
- A goal brief must point to one execution contract file that the control plane can materialize.
- A goal brief must list machine-checkable completion references instead of relying on free-form prose.

## Ownership
- `planningops` owns goal definition and resolution.
- `monday` owns operator interaction and channel delivery.
- Channel integrations must be referenced through contracts and repo-owned adapters, not embedded directly in planningops automation prompts.

## Validation
- `planningops/scripts/validate_active_goal_registry.py`
