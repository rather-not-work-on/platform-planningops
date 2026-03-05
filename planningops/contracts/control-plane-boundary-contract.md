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
2. Cross-repo execution entrypoints in this repo must live under `planningops/scripts/federation/`.
3. Root-level `planningops/scripts/*.py|*.sh` files for federation concerns must be wrapper-only dispatchers.
4. Any boundary change must update:
   - `planningops/config/repository-boundary-map.json`
   - `planningops/scripts/validate_repo_boundaries.py`
   - `planningops/scripts/test_validate_repo_boundaries_contract.sh`

## Verification
- Contract test: `bash planningops/scripts/test_validate_repo_boundaries_contract.sh`
- CI guardrail: `.github/workflows/federated-ci-matrix.yml` `loop-guardrails` job.

## Failure Handling
If boundary verification fails:
1. Move misplaced federation script to `planningops/scripts/federation/`.
2. Keep backward compatibility via thin wrapper at previous root path.
3. Re-run boundary contract test and full guardrail chain.
