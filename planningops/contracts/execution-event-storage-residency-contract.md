# Execution Event Storage Residency Contract

## Purpose
Define which runtime/event artifact families must remain external-only, which backend is used by default, and how local-first operation may migrate to S3/OCI without changing canonical evidence semantics.

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Governs execution/event families emitted by:
  - `planningops/scripts/core/loop/runner.py`
  - `planningops/scripts/ralph_loop_local.py`
  - `planningops/scripts/autonomous_supervisor_loop.py`
  - `planningops/scripts/supervisor_experiment_auto_executor.py`
  - `planningops/scripts/parser_diff_dry_run.py`

## Residency Rules
1. Event families under `planningops/artifacts/loops/**`, `transition-log/**`, `adapter-hooks/**`, `sync-summary/**`, `supervisor/**`, and `experiments/**` are `external_only`.
2. Canonical Git visibility for these families is pointer-only:
   - payload bytes live in the selected backend
   - Git retains pointer manifests and canonical validation evidence only
3. Default backend is `local`.
4. Approved migration backends are `s3` and `oci`.
5. Migration must preserve:
   - `logical_path`
   - `backend`
   - `uri`
   - `sha256`
   - `written_at_utc`

## Portability Profile
- Strategy: `local_first`
- Default target platform: local filesystem
- Migration targets: `s3`, `oci`
- Oracle Cloud portability is satisfied through `oci` backend compatibility; contract shape must remain unchanged when backend switches.

## Required Family Map
Configured in `planningops/config/artifact-storage-policy.json` under `execution_event_families`.

Minimum fields per family:
- `logical_root`
- `residency`
- `pointer_visibility`
- `default_backend`
- `migration_backends`
- `retention_days`
- `owner_scripts`

## Drift Guard
- Each `owner_scripts` entry must exist and reference its declared `logical_root`.
- Each `logical_root` must be covered by the `external_only` tier map.
- `retention_days` for event families must not exceed `retention.external_only_days`.

## Verification
- Policy validator: `python3 planningops/scripts/validate_artifact_storage_policy.py --strict`
- Contract test: `bash planningops/scripts/test_validate_artifact_storage_policy_contract.sh`
- Commit guard: `python3 planningops/scripts/validate_external_only_commit_guard.py --strict`

## Related Contracts
- `planningops/contracts/artifact-retention-tier-contract.md`
- `planningops/contracts/artifact-sink-contract.md`
- `planningops/contracts/requirements-contract.md`
