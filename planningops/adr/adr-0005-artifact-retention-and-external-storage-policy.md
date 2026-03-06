# ADR-0005: Artifact Retention Tiers and External Storage Policy

## Status
Accepted

## Context
Planningops and execution repos accumulate high-frequency runtime artifacts. Committing all generated files to Git lowers review signal-to-noise and increases maintenance drag.

We need:
1. Deterministic evidence paths for governance.
2. Tiered retention policy for Git vs external storage.
3. Migration path that works local-first and can move to S3/OCI.

## Decision
1. Introduce three artifact tiers:
   - `git-canonical`
   - `git-optional`
   - `external-only`
2. External-only artifacts are stored by sink backend (`local|s3|oci`) and represented in Git by pointer manifests.
3. Policy source is fixed at `planningops/config/artifact-storage-policy.json`.
4. Contract and validation are enforced by:
   - `planningops/contracts/artifact-retention-tier-contract.md`
   - `planningops/scripts/validate_artifact_storage_policy.py`
5. Rollout follows checklist and rollback steps in:
   - `planningops/quality/artifact-storage-rollout-checklist.md`

## Consequences
### Positive
- Less Git noise for high-frequency execution logs.
- Clear SoT boundary: policy/summary in Git, bulk runtime logs in external sink.
- Backend migration path local -> S3/OCI without changing logical artifact contract.

### Negative
- Additional operational complexity (sink config, pointer lifecycle, rehydrate tooling).
- Need CI guardrails to prevent accidental commit of external-only paths.

## Alternatives Considered
1. Keep all artifacts in Git.
   - Rejected: long-term review/merge overhead too high.
2. Move all artifacts external-only.
   - Rejected: loses canonical governance evidence in Git.
3. Manual per-run decision.
   - Rejected: non-deterministic and hard to automate.
