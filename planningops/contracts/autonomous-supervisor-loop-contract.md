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
Operator handoff validation artifact:
- `planningops/artifacts/supervisor/<run-id>/operator-handoff-validation.json`
Optional goal-completion delivery artifact:
- `monday/runtime-artifacts/messaging/delivery-cycles/supervisor-goal-completion-<run-id>.json`

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

Offline snapshot fallback semantics:
- when `--offline` is enabled, supervisor must require project-item snapshot fallback and seed the snapshot from `--items-file` or canonical `planningops/artifacts/program/program-manifest.json` when no explicit snapshot file exists yet
- snapshot-backed rate-limit guidance emitted through cycle or summary artifacts must include `fallback_cause` with one of `rate_limit`, `network`, `auth`, `owner_resolution`, `other`, or `none`

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
6. operator handoff validation sidecar paths when generated

Supervisor/operator CTA sidecars must also obey these rules:
- `operator-report.json` and `inbox-payload.json` should treat `priority_headline`, `priority_cta_command`, and `priority_summary_markdown` as the planningops source of truth for downstream CTA rendering
- `operator-summary.md` and `inbox-payload.json` should expose the canonical `operator-handoff-validation.json` path so downstream operator surfaces can inspect emitted handoff validation evidence without reopening the run directory manually
- each run should also emit `operator-handoff-bundle.json`, `operator-handoff-bundle-validation.json`, `operator-handoff-bundle-readiness.json`, and `operator-handoff-bundle-readiness-validation.json` plus `last-run` copies so bundle consumers can resolve, validate, diagnose, and gate the same canonical CTA surface
- when monday translates those artifacts into wrappers, dispatch artifacts, delivery-cycle reports, or scheduler evidence, that downstream path should preserve one canonical `operator_handoff_validation_path` / `priority_preview_ref` / `priority_display_packet_ref` trio plus the planningops-owned `operator_handoff_bundle_path` / `operator_handoff_bundle_validation_path` / `operator_handoff_bundle_readiness_path` / `operator_handoff_bundle_readiness_validation_path` sidecar set derived from the same planningops CTA surface
- CTA consumers should use monday's canonical resolver entrypoints:
  - `scripts/resolve_operator_priority_preview.py`
  - `scripts/resolve_operator_priority_display_packet.py`
- planningops bundle consumers should use:
  - `planningops/scripts/resolve_supervisor_operator_handoff_bundle.py`
  - `planningops/scripts/validate_supervisor_operator_handoff_bundle.py`
  - `planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py`
  - `planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py`
  - `planningops/scripts/doctor_supervisor_operator_handoff_bundle.py`
  - `planningops/scripts/gate_supervisor_operator_handoff_bundle.sh`
- if multiple monday artifacts from one supervisor delivery path dereference different preview/display packet JSON, that is a contract regression and must fail closed
- machine validation should use:
  - `planningops/schemas/supervisor-operator-report.schema.json`
  - `planningops/schemas/supervisor-inbox-payload.schema.json`
  - `planningops/scripts/validate_supervisor_operator_handoff.py`
  - `planningops/schemas/supervisor-operator-handoff-bundle.schema.json`
  - `planningops/schemas/supervisor-operator-handoff-bundle-validation.schema.json`
  - `planningops/schemas/supervisor-operator-handoff-bundle-readiness.schema.json`
  - `planningops/schemas/supervisor-operator-handoff-bundle-readiness-validation.schema.json`
  - `planningops/scripts/validate_supervisor_operator_handoff_bundle.py`
  - `planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py`
  - `planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py`
  - `planningops/scripts/doctor_supervisor_operator_handoff_bundle.py`
  - `planningops/scripts/gate_supervisor_operator_handoff_bundle.sh`

Output:
- `planningops/artifacts/supervisor/last-run.json`
- `planningops/artifacts/supervisor/last-run-operator-report.json`
- `planningops/artifacts/supervisor/last-run-operator-summary.md`
- `planningops/artifacts/supervisor/last-run-inbox-payload.json`
- `planningops/artifacts/supervisor/last-run-operator-handoff-validation.json`
- when `stop_reason=goal_completed` and monday delivery is available:
  - planningops may cache a copy of the monday delivery-cycle report as local evidence

## Testability Mapping
- implementation:
  - `planningops/scripts/autonomous_supervisor_loop.py`
  - `planningops/scripts/supervisor_handoff_common.py`
- machine validation:
  - `planningops/scripts/validate_supervisor_operator_handoff.py`
- deterministic simulation test:
  - `planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
