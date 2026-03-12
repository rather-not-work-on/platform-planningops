# Autonomous Supervisor Loop Contract

## Goal
Encode `plan -> work -> review -> replan` as a deterministic multi-cycle supervisor loop so long-horizon autonomy is quality-first and self-correcting.

## Cycle Structure
Each cycle must run in this order:
1. Work execution (`issue_loop_runner`)
2. Review gate (verdict/reason extraction)
3. Experiment trigger evaluation
4. Backlog stock + replenishment gate validation
5. Stop/continue decision

Cycle report artifact:
- `planningops/artifacts/supervisor/<run-id>/cycle-<nn>/cycle-report.json`
Operator report artifact:
- `planningops/artifacts/supervisor/<run-id>/operator-report.json`
Operator summary artifact:
- `planningops/artifacts/supervisor/<run-id>/operator-summary.md`
Inbox payload artifact:
- `planningops/artifacts/supervisor/<run-id>/inbox-payload.json`

## Required Decisions Per Cycle
1. `last_verdict` and `reason_code`
2. `replan_required` and optional `replan_decision_path`
3. `experiment_trigger` (`triggered`, `reasons`)
4. `backlog_gate` result (stock breach + candidate violation)
5. `continue_or_stop` decision derived from contract rules

## Experiment Trigger Integration
Supervisor must trigger comparative experiment path when any is true:
1. `uncertainty_level in {high, critical}`
2. `simulation_required=true`
3. loop profile indicates simulation-first (`L2 Simulation`)

When triggered, supervisor must emit:
- `experiment-trigger.json`
- protocol reference to `planningops/contracts/worktree-comparative-experiment-protocol.md`
- optional auto-executor report link when `--experiment-auto-execute` is enabled

## Auto Executor Linkage
- Supervisor can invoke `planningops/scripts/supervisor_experiment_auto_executor.py` on experiment trigger.
- Auto executor output fields must be attached to cycle report:
  - `experiment_auto_executor.enabled`
  - `experiment_auto_executor.rc`
  - `experiment_auto_executor.output_path`
  - `experiment_auto_executor.verdict`
  - `experiment_auto_executor.selected_option`
- Auto executor failure is terminal with stop reason `experiment_auto_executor_failed`.

## Stop Rules
Stop immediately when:
1. quality gate fails (`last_verdict=fail`)
2. escalation auto-pause is active
3. strict backlog gate fails
4. experiment trigger is active and `continue_on_experiment=false`

Convergence stop allowed when:
- pass streak reaches threshold and replenishment candidate count is zero.

## Replan and Replenishment Outputs
Replan and replenishment are first-class outputs:
- `replan_required`
- `replan_decision_path` (if present)
- `replenishment_candidates_path`
- `replenishment_candidates_count`
- optional `backlog_materialization` result when `--auto-materialize-backlog` is enabled

When auto materialization is enabled:
1. `dry-run` may invoke `planningops/scripts/core/backlog/materialize.py` and attach its report as review evidence.
2. `apply` may invoke backlog materialization and continue into the next cycle if materialization succeeds.
3. materialization failure is terminal with stop reason `replan_materialization_failed`.

## Summary Artifact
Run summary must include:
1. `supervisor_verdict` (`pass|fail|inconclusive`)
2. `stop_reason` + `stop_details`
3. full `cycles[]` records
4. referenced contracts
5. operator report sidecar paths when generated

Output:
- `planningops/artifacts/supervisor/last-run.json`
- `planningops/artifacts/supervisor/last-run-operator-report.json`
- `planningops/artifacts/supervisor/last-run-operator-summary.md`
- `planningops/artifacts/supervisor/last-run-inbox-payload.json`

## Testability Mapping
- implementation:
  - `planningops/scripts/autonomous_supervisor_loop.py`
- deterministic simulation test:
  - `planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
