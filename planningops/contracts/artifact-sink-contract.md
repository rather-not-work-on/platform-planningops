# Artifact Sink Contract

## Purpose
Provide a deterministic write/read/rehydrate abstraction for artifact storage backends.

## Scope
- `planningops/scripts/artifact_sink.py`
- Consumer scripts:
  - `issue_loop_runner.py`
  - `autonomous_supervisor_loop.py`
  - `supervisor_experiment_auto_executor.py`
  - `verify_loop_run.py`

## Interface
- `ArtifactSink.write_json(logical_path, data)`
- `ArtifactSink.write_text(logical_path, text, append=False)`
- `ArtifactSink.append_ndjson_row(logical_path, row)`
- `ArtifactSink.externalize_existing_file(logical_path, delete_local=True)`
- `ArtifactSink.rehydrate_from_pointer(pointer_path, output_path)`
- `ArtifactSink.runtime_path(logical_path)` / `resolve_read_path(logical_path)`

## Behavioral Rules
1. Tier resolution uses `planningops/config/artifact-storage-policy.json`.
2. For `external_only` tier:
   - write payload to selected backend (`local|s3|oci`)
   - write pointer manifest under `planningops/artifacts/pointers/**`
3. Rehydrate restores payload bytes from pointer source deterministically.
4. Commit guard fails when PR diff includes `external_only` paths.

## Verification
- E2E sink test: `bash planningops/scripts/test_artifact_sink_e2e.sh`
- Commit guard test: `bash planningops/scripts/test_validate_external_only_commit_guard.sh`
- Migration test: `bash planningops/scripts/test_migrate_external_only_artifacts_contract.sh`
- Policy validation: `python3 planningops/scripts/validate_artifact_storage_policy.py --strict`

## Related Contracts
- `planningops/contracts/execution-event-storage-residency-contract.md`
