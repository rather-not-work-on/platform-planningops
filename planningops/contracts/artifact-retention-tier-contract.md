# Artifact Retention Tier Contract

## Purpose
Reduce Git noise while preserving deterministic evidence and rehydrate paths.

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Applies to files under `planningops/artifacts/**` produced by runtime scripts.

## Tier Definitions
1. `git-canonical`
   - Commit to Git as source-of-truth evidence.
   - Examples: `validation/`, `program/`, `meta-plan/`, `verification/latest-*`, `ci/federated-ci-summary.json`.
2. `git-optional`
   - Commit only for selected milestones/audits; default is no commit.
   - Examples: `conformance/`, `pilot/`, `refactor-hygiene/latest.json`.
3. `external-only`
   - Do not commit to Git; store in external backend and keep pointer manifest in Git.
   - Examples: `loops/`, `sync-summary/`, `transition-log/`, `adapter-hooks/`, `supervisor/`, `experiments/`.

## Storage Backends
- `local`: local filesystem sink (default)
- `s3`: S3-compatible object sink (mockable)
- `oci`: OCI Object Storage sink (mockable)

Backend selection is controlled by:
- config: `planningops/config/artifact-storage-policy.json`
- runtime override: `PLANNINGOPS_ARTIFACT_SINK_BACKEND`

## Pointer Manifest Contract
- Pointer root: `planningops/artifacts/pointers/`
- Each externalized artifact must emit a pointer JSON with:
  - `logical_path`
  - `backend`
  - `uri`
  - `sha256`
  - `bytes`
  - `written_at_utc`

## Retention Contract
- `external-only` artifacts follow backend retention windows and compaction rules.
- Pointer manifests remain in Git until corresponding runbook retention expiry.
- Rehydrate must resolve pointer -> backend object deterministically.

## Verification
- Policy config: `planningops/config/artifact-storage-policy.json`
- Validator: `planningops/scripts/validate_artifact_storage_policy.py`
- Test: `bash planningops/scripts/test_validate_artifact_storage_policy_contract.sh`
