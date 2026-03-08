# Control Plane Boundary Contract

## Purpose
Keep `platform-planningops` as a thin control plane with explicit repository boundaries.

## Repository Ownership
- `platform-planningops`: planning contracts, orchestration policy, cross-repo gate coordination.
- `platform-contracts`: shared interfaces/schema versions.
- `platform-provider-gateway`: provider runtime and failover behavior.
- `platform-observability-gateway`: observability runtime and replay/backfill operations.
- `monday`: execution runtime, scheduler, worker lifecycle.

## Boundary Rules
1. `platform-planningops` must not contain production runtime implementation for provider/o11y/scheduler domains.
2. Canonical control-plane loop logic must live under `planningops/scripts/core/`.
3. Cross-repo execution entrypoints and repo-to-adapter mappings in this repo must live under `planningops/scripts/federation/`.
4. Non-recurring bootstrap/migration scripts must live under `planningops/scripts/oneoff/`.
5. Root-level `planningops/scripts/*.py|*.sh` files for migrated federation/core/oneoff concerns must be wrapper-only dispatchers.
6. Any boundary change must update:
   - `planningops/config/repository-boundary-map.json`
   - `planningops/config/script-role-map.json`
   - `planningops/scripts/validate_repo_boundaries.py`
   - `planningops/scripts/validate_script_roles.py`
   - `planningops/scripts/test_validate_repo_boundaries_contract.sh`
   - `planningops/scripts/test_validate_script_roles_contract.sh`
7. Compatibility wrappers must be tracked by `planningops/config/wrapper-deprecation-map.json` until deprecation gates allow removal.
8. Boundary and role validators must ignore filesystem metadata files (for example `._*`, `.DS_Store`) to avoid false-positive drift in mixed storage environments.

## Verification
- Contract test: `bash planningops/scripts/test_validate_repo_boundaries_contract.sh`
- Deprecation lifecycle test: `bash planningops/scripts/test_validate_wrapper_deprecation_contract.sh`
- CI guardrail: `.github/workflows/federated-ci-matrix.yml` `loop-guardrails` job.

## Failure Handling
If boundary verification fails:
1. Move misplaced federation script to `planningops/scripts/federation/`.
2. Move misplaced recurring control-plane logic to `planningops/scripts/core/`.
3. Keep backward compatibility via thin wrapper at previous root path.
4. Re-run boundary contract test and full guardrail chain.
