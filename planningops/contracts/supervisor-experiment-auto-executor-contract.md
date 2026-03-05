# Supervisor Experiment Auto Executor Contract

## Goal
Convert supervisor experiment triggers into deterministic branch/worktree comparative execution without manual operator steps.

## Trigger Binding
- Input trigger source: `autonomous_supervisor_loop` cycle experiment trigger.
- Auto executor runs only when:
  - experiment trigger is active, and
  - `--experiment-auto-execute` is enabled.

## Required Behavior
1. Deterministic experiment id and branch/worktree naming.
2. At least two options must be supported (`option-a`, `option-b` by default).
3. Validation pack commands run in each isolated worktree.
4. Per-option report JSON is emitted.
5. Decision record is generated with weighted rubric.
6. Cleanup behavior must be explicit (`keep_worktrees` false by default).

## Artifacts
- `manifest.json`
- `option-<id>-report.json` (per option)
- `decision-record.md`
- `supervisor-auto-executor-report.json`

Default root:
- `planningops/artifacts/experiments/<experiment-id>/`

## Decision Rubric
Score each option:
1. correctness/safety (weight `0.40`)
2. implementation complexity (weight `0.20`)
3. maintainability/drift risk (weight `0.20`)
4. rollback cost (weight `0.20`)

Safety floor:
- `correctness/safety >= 3` required for eligibility.

## Failure Mode
Auto executor returns fail when:
- worktree creation fails for all options, or
- all options fail safety floor / validation pack.

Supervisor mapping:
- stop reason: `experiment_auto_executor_failed`
- verdict: `fail`

## Testability Mapping
- implementation:
  - `planningops/scripts/supervisor_experiment_auto_executor.py`
  - `planningops/scripts/autonomous_supervisor_loop.py`
- regression:
  - `planningops/scripts/test_supervisor_experiment_auto_executor_contract.sh`
