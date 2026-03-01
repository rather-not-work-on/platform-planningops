# planningops runtime workspace

This directory contains Ralph Loop issue-resolution runtime artifacts.

## Layout
- `config/`: project metadata and field catalogs
- `contracts/`: problem/requirements/failure contracts
- `quality/`: verification checklist and verdict formats
- `adr/`: architecture decisions
- `scripts/`: local loop execution and validation scripts

## Runtime Policy
- Local-first execution is the default baseline.
- Runtime naming is fixed:
  - External contract term: `Executor`
  - Internal implementation term: `Worker`
- Per-task runtime/provider policy is allowed and resolved by task key.

## Runtime Profiles
- Profile catalog: `planningops/config/runtime-profiles.json`
- Contract reference map: `planningops/config/contract-ref-map.json`
- `active_profile` defines the default runtime surface.
- `task_overrides.<task_key>` can override:
  - `runtime_profile`
  - provider policy (`model`, `fallback_models`, `max_retries`, `timeout_ms`)

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
python3 planningops/scripts/cross_repo_conformance_check.py
python3 planningops/scripts/run_local_oracle_rehearsal.py --days 7
```

Optional profile override:
```bash
python3 planningops/scripts/ralph_loop_local.py \
  --issue-number 18 \
  --mode dry-run \
  --runtime-profile-file planningops/config/runtime-profiles.json \
  --task-key issue-18
```
