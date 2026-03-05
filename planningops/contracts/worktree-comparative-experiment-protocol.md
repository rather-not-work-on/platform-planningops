# Worktree Comparative Experiment Protocol

## Goal
Standardize A/B (or A/B/C) branch/worktree experiments so architecture decisions are evidence-driven, reproducible, and auditable.

## Trigger Conditions
Comparative experiment mode is required when any is true:
1. `uncertainty_level` is `high|critical`,
2. proposed change alters reliability semantics, contracts, or safety gates,
3. two or more approaches have materially different rollback/complexity trade-offs.

## Execution Rules
1. Create at least two isolated branches/worktrees (`option-a`, `option-b`).
2. Implement the smallest meaningful slice needed to compare behavior.
3. Run the same validation command pack for each option.
4. Capture artifacts under a single experiment root:
   - `planningops/artifacts/experiments/<date>-<topic>/`
5. Record deterministic rubric scores and selection decision.

## Required Artifacts
- `manifest.json`
  - `experiment_id`, `topic`, `trigger`, `options`, `validation_pack`
- `option-<id>-report.json` (for each option)
  - `branch`, `worktree`, `commands`, `rc`, `summary`, `artifacts`
- `decision-record.md`
  - selected option, score breakdown, trade-offs, rollback notes

## Decision Rubric (Deterministic)
Each option is scored 1-5 on:
1. correctness/safety (weight 0.40)
2. implementation complexity (weight 0.20)
3. maintainability/drift risk (weight 0.20)
4. rollback cost (weight 0.20)

Total score:
- `total = sum(score_i * weight_i)`
- highest total wins unless a safety criterion fails (`correctness/safety < 3`)

## Selection Record Format
`decision-record.md` must include:
1. `selected_option`
2. `rejected_options`
3. `score_table`
4. `safety_gate_notes`
5. `rollback_plan`
6. `follow_up_tasks`

## Notes
- This protocol complements, not replaces, the regular plan-work-review loop.
- Time spent in experiments is justified only when it reduces downstream rework/risk.
