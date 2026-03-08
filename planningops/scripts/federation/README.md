# planningops/scripts/federation

## Purpose
Keep cross-repository execution entrypoints isolated from the planningops core loop.

## Contents
- `adapter_registry.py`: repo-to-adapter mapping registry for execution hooks
- `cross_repo_conformance_check.py`: federated contract/provider/o11y/runtime conformance matrix
- `github_sync_adapter.py`: GitHub sync smoke/idempotency/drift helper
- `multi_repo_projection_report.py`: repo-level projection drift aggregation
- `run_local_oracle_rehearsal.py`: local-first vs oracle_cloud rehearsal harness
- `federated_ci_matrix_local.sh`: local federated CI matrix runner

Compatibility wrappers are kept at `planningops/scripts/*.py|*.sh`; `repo_execution_adapters.py` remains the legacy root name for `adapter_registry.py`.

## Change Rules
- New multi-repo execution entrypoints must be added here, not at `planningops/scripts/` root.
- Repo-specific execution mapping must stay here; core loop modules must consume this directory through thin interfaces only.
- Root wrappers must remain thin dispatch-only files.
- Any federation entrypoint addition must update `planningops/config/repository-boundary-map.json` and pass `test_validate_repo_boundaries_contract.sh`.
