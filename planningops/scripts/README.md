# planningops/scripts

## Purpose
Host executable runners, validators, and contract tests for planningops loops.

## Contents
- Runtime runners:
  - `issue_loop_runner.py` (`--pec-preflight-mode legacy|hybrid|strict-pec`)
  - `ralph_loop_local.py`
  - `meta_plan_orchestrator.py`
  - `github_sync_adapter.py`
  - `repo_execution_adapters.py`
- Validation and reporting:
  - `validate_contracts.py`
  - `validate_worker_task_pack.py`
  - `validate_project_field_schema.py`
  - `verify_loop_run.py`
  - `verify_plan_projection.py`
  - `cross_repo_conformance_check.py`
  - `multi_repo_projection_report.py`
- Backlog/bootstrap helpers:
  - `bootstrap_two_track_backlog.py`
  - `compile_plan_to_backlog.py`
  - `build_meta_plan_graph.py`
  - `test_compile_plan_to_backlog_contract.sh`
  - `test_build_meta_plan_graph_contract.sh`
  - `run_track1_gate_dryrun.py`
  - `run_track2_contract_pack_validation.py`
  - `normalize_ready_implementation_blueprint_refs.py`
- Refactor hygiene:
  - `refactor_hygiene_loop.py`
  - `refactor_hygiene_multi_repo.py`
- Local CI and contract tests:
  - `federated_ci_matrix_local.sh`
  - `test_meta_plan_orchestrator_contract.sh`
  - `test_meta_plan_graph_schema_contract.sh`
  - `test_verify_plan_projection_contract.sh`
  - `test_ralph_loop_local_worker_policy.sh`
  - `test_*.sh`

## Change Rules
- Each new runner must produce deterministic artifacts under `planningops/artifacts`.
- Contract-impacting behavior changes must include/adjust a `test_*.sh` regression test.
- Commands must run from repo root with repo-relative paths.
