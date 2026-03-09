# planningops/scripts/federation

## Purpose
Keep cross-repository execution entrypoints isolated from the planningops core loop.

## Contents
- `federated_python_env.py`: deterministic local Python bootstrap helper for sibling-repo federated checks
- `adapter_registry.py`: repo-to-adapter mapping registry for execution hooks
- `cross_repo_conformance_check.py`: federated contract/provider/o11y/runtime conformance matrix
- `github_sync_adapter.py`: GitHub sync smoke/idempotency/drift helper
- `multi_repo_projection_report.py`: repo-level projection drift aggregation
- `run_local_oracle_rehearsal.py`: local-first vs oracle_cloud rehearsal harness
- `validate_execution_wave_readiness.py`: readiness validator for plan waves that must verify prerequisite outputs and closed issues before projecting the next issue pack
- `review_interface_adoption.py`: spec-driven cross-repo review generator for completed interface waves
- `federated_ci_matrix_local.sh`: local federated CI matrix runner

Compatibility wrappers are kept at `planningops/scripts/*.py|*.sh`; `repo_execution_adapters.py` remains the legacy root name for `adapter_registry.py`.

## Change Rules
- New multi-repo execution entrypoints must be added here, not at `planningops/scripts/` root.
- Repo-specific execution mapping must stay here; core loop modules must consume this directory through thin interfaces only.
- Shared local bootstrap logic for federated checks should live here so shell runners and Python entrypoints reuse the same managed environment policy.
- Root wrappers must remain thin dispatch-only files.
- Any federation entrypoint addition must update `planningops/config/repository-boundary-map.json` and pass `test_validate_repo_boundaries_contract.sh`.
