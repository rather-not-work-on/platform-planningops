# planningops runtime workspace

This directory contains Ralph Loop issue-resolution runtime artifacts.

## Layout
- `config/`: project metadata and field catalogs
- `contracts/`: problem/requirements/failure contracts
- `quality/`: verification checklist and verdict formats
- `adr/`: architecture decisions
- `scripts/`: local loop execution and validation scripts

Module-level navigation:
- `planningops/adr/README.md`
- `planningops/artifacts/README.md`
- `planningops/config/README.md`
- `planningops/contracts/README.md`
- `planningops/fixtures/README.md`
- `planningops/quality/README.md`
- `planningops/schemas/README.md`
- `planningops/scripts/README.md`
- `planningops/templates/README.md`

## Runtime Policy
- Local-first execution is the default baseline.
- Runtime naming is fixed:
  - External contract term: `Executor`
  - Internal implementation term: `Worker`
- Per-task runtime/provider policy is allowed and resolved by task key.

## Design-First Policy
- Implementation starts only after blueprint refs are defined:
  - `interface_contract_refs`
  - `package_topology_ref`
  - `dependency_manifest_ref`
  - `file_plan_ref`
- If implementation finds mismatch, return to redefine stage first, then resume.
- Every touched module must keep its own `README.md` updated.
- Contract reference: `planningops/contracts/implementation-readiness-gate-contract.md`

## Runtime Profiles
- Profile catalog: `planningops/config/runtime-profiles.json`
- Contract reference map: `planningops/config/contract-ref-map.json`
- `active_profile` defines the default runtime surface.
- `task_overrides.<task_key>` can override:
  - `runtime_profile`
  - provider policy (`model`, `fallback_models`, `max_retries`, `timeout_ms`)
  - worker policy:
    - `kind=parser_diff_dry_run` (baseline)
    - `kind=python_script` + `script` + `args[]` (`{loop_id}`, `{mode}`, `{issue_number}`, `{task_key}`, `{runtime_profile}` templating)
    - `kind=shell` + `command` template

Example task keys:
- `issue-18`
- `issue-19`
- `default`

## Local -> Oracle Cloud Migration
- Keep one contract, swap profile only.
- Migration pattern:
  1. Keep `task_overrides` unchanged.
  2. Add/validate `profiles.oracle_cloud` endpoints.
  3. Move selected tasks by changing `runtime_profile` (`local` -> `oracle_cloud`).
  4. Verify loop artifacts still satisfy the same gate evidence paths.

## Commands
```bash
python3 planningops/scripts/ralph_loop_local.py --issue-number 18 --mode dry-run
python3 planningops/scripts/issue_loop_runner.py --mode apply
python3 planningops/scripts/issue_loop_runner.py --mode dry-run --pec-preflight-mode strict-pec --pec-contract-file planningops/fixtures/plan-execution-contract-sample.json --no-feedback
python3 planningops/scripts/compile_plan_to_backlog.py --contract-file planningops/fixtures/plan-execution-contract-sample.json
python3 planningops/scripts/build_meta_plan_graph.py --contract-file planningops/fixtures/meta-plan-graph-sample.json --strict
python3 planningops/scripts/meta_plan_orchestrator.py --meta-graph-contract planningops/fixtures/meta-plan-graph-sample.json --mode dry-run --strict
python3 planningops/scripts/validate_worker_task_pack.py --task-key issue-18 --issue-number 18 --mode dry-run --loop-profile "L3 Implementation-TDD" --strict
python3 planningops/scripts/verify_plan_projection.py --contract-file planningops/fixtures/plan-execution-contract-sample.json --snapshot-file planningops/fixtures/plan-projection-snapshot-sample.json --strict
bash planningops/scripts/test_compile_plan_to_backlog_contract.sh
bash planningops/scripts/test_build_meta_plan_graph_contract.sh
bash planningops/scripts/test_verify_plan_projection_contract.sh
bash planningops/scripts/test_meta_plan_graph_schema_contract.sh
bash planningops/scripts/test_meta_plan_orchestrator_contract.sh
bash planningops/scripts/test_ralph_loop_local_worker_policy.sh
bash planningops/scripts/test_validate_worker_task_pack_contract.sh
python3 planningops/scripts/normalize_ready_implementation_blueprint_refs.py
python3 planningops/scripts/run_track2_contract_pack_validation.py --strict
python3 planningops/scripts/cross_repo_conformance_check.py
python3 planningops/scripts/run_local_oracle_rehearsal.py --days 7
bash planningops/scripts/test_module_readme_contract.sh
python3 planningops/scripts/refactor_hygiene_loop.py --policy-file planningops/config/refactor-hygiene-policy.json
python3 planningops/scripts/refactor_hygiene_multi_repo.py --config-file planningops/config/refactor-hygiene-multi-repo.json --workspace-root .
```

Optional profile override:
```bash
python3 planningops/scripts/ralph_loop_local.py \
  --issue-number 18 \
  --mode dry-run \
  --runtime-profile-file planningops/config/runtime-profiles.json \
  --task-key issue-18
```

Optional worker-policy override example:
```json
{
  "task_overrides": {
    "issue-42": {
      "runtime_profile": "local",
      "worker_policy": {
        "kind": "python_script",
        "script": "planningops/scripts/parser_diff_dry_run.py",
        "args": ["--run-id", "{loop_id}", "--mode", "{mode}"]
      }
    }
  }
}
```

## Periodic Refactor Hygiene Loop
- Contract: `planningops/contracts/module-refactor-hygiene-loop-contract.md`
- Policy file: `planningops/config/refactor-hygiene-policy.json`
- Output root: `planningops/artifacts/refactor-hygiene/<run-id>/`
- Queue contract: always `external_first` -> `internal_next`
- Checkpoints: generated by `checkpoint_every_tasks` to force context cleanup and scope pruning.

Scheduled execution:
- GitHub Actions workflow: `.github/workflows/refactor-hygiene.yml`
- cadence: every Monday 03:00 UTC

## Multi-Repo Consistency Mode
- Matrix config: `planningops/config/refactor-hygiene-multi-repo.json`
- Runner: `planningops/scripts/refactor_hygiene_multi_repo.py`
- Aggregate output: `planningops/artifacts/refactor-hygiene/multi-repo/<run-id>/aggregate.json`
- Scheduled workflow: `.github/workflows/refactor-hygiene-multi-repo.yml` (weekly)
