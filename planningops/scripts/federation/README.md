# planningops/scripts/federation

## Purpose
Keep cross-repository execution entrypoints isolated from the planningops core loop.

## Contents
- `federated_python_env.py`: deterministic local Python bootstrap helper for sibling-repo federated checks
- `adapter_registry.py`: repo-to-adapter mapping registry for execution hooks
- `cross_repo_conformance_check.py`: federated contract/provider/o11y/runtime conformance matrix
- `github_sync_adapter.py`: GitHub sync smoke/idempotency/drift helper
- `multi_repo_projection_report.py`: repo-level projection drift aggregation
- `run_issue_driven_mission_smoke.py`: planningops-owned bridge from GitHub issue context into monday local runtime smoke
- `run_issue_driven_runtime_stack_smoke.py`: planningops-owned aggregate runner that links an issue-driven monday mission smoke with provider and observability repo-owned smoke evidence
- `run_local_runtime_stack_smoke.py`: planningops-owned federated local smoke runner over repo-owned monday/provider/o11y entrypoints
- `run_local_oracle_rehearsal.py`: local-first vs oracle_cloud rehearsal harness
- `run_wave14_oracle_rehearsal.py`: wave-owned rehearsal runner that compares wave13 local vs oracle_cloud smoke outputs without changing the default local profile
- `validate_execution_wave_readiness.py`: readiness validator for plan waves that must verify prerequisite outputs and closed issues before projecting the next issue pack
- `review_interface_adoption.py`: spec-driven cross-repo review generator for completed interface waves
- `federated_ci_matrix_local.sh`: local federated CI matrix runner

Compatibility wrappers are kept at `planningops/scripts/*.py|*.sh`; `repo_execution_adapters.py` remains the legacy root name for `adapter_registry.py`.

## Change Rules
- New multi-repo execution entrypoints must be added here, not at `planningops/scripts/` root.
- Repo-specific execution mapping must stay here; core loop modules must consume this directory through thin interfaces only.
- Shared local bootstrap logic for federated checks should live here so shell runners and Python entrypoints reuse the same managed environment policy.
- Issue-to-mission normalization belongs here when planningops is orchestrating repo-owned runtime smoke.
- Root wrappers must remain thin dispatch-only files.
- Any federation entrypoint addition must update `planningops/config/repository-boundary-map.json` and pass `test_validate_repo_boundaries_contract.sh`.
