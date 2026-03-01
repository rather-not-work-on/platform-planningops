# Checkpoint Resume Contract

## Goal
Allow interrupted loop runs to resume from deterministic checkpoint stages.

## Checkpoint Location
- `planningops/artifacts/loop-runner/checkpoints/issue-<issue_number>.json`

## Checkpoint Stage Enum
- `pre_hook`
- `loop_executed`
- `verified`
- `feedback_applied`

## Required Fields
- `issue_number`
- `stage`
- `updated_at_utc`

## Optional Fields
- `loop_dir`
- `date_part`
- `loop_id`
- `verification_path`
- `payload_path`
- `adapter_pre_hook`
- `adapter_post_hook`
- `idempotency_key`

## Runner Controls
- `--resume-from-checkpoint`: reuse existing checkpoint artifacts when available
- `--simulate-interrupt-after <stage>`: test interruption at stage boundary

## Success Criteria
- resume run uses valid checkpoint artifacts
- checkpoint stage transitions are persisted
- checkpoint is cleared after successful `feedback_applied`
