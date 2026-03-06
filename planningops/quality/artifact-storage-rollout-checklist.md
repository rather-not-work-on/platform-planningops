# Artifact Storage Rollout Checklist

## Goal
Roll out tiered artifact storage with safe fallback and deterministic rehydrate behavior.

## Pre-Flight
- [ ] `planningops/config/artifact-storage-policy.json` passes validator.
- [ ] `planningops/contracts/artifact-retention-tier-contract.md` is approved.
- [ ] External backend credentials (if non-local) are configured in runtime environment.
- [ ] Pointer manifest path (`planningops/artifacts/pointers/`) is writable.

## Rollout Steps
1. Set backend selector (`PLANNINGOPS_ARTIFACT_SINK_BACKEND`) to target backend.
2. Run sink dry-run/migration command on sample artifacts.
3. Validate pointer manifests are generated and resolvable.
4. Run loop/supervisor/review flows and verify no regressions.
5. Enable commit guard for `external_only` paths in CI.

## Verification
- [ ] External-only writes produce pointer manifests in Git path.
- [ ] Canonical outputs remain under `planningops/artifacts/validation/**` (or other canonical roots).
- [ ] Rehydrate can restore at least one external object using pointer metadata.

## Rollback Plan
1. Set `PLANNINGOPS_ARTIFACT_SINK_BACKEND=local`.
2. Disable external-only commit guard temporarily if emergency hotfix requires it.
3. Re-run validation suite and confirm loop runtime output stability.
4. Keep pointer manifests; do not delete existing external payloads until post-incident review.

## Post-Rollout
- [ ] Record backend and retention settings in runbook/issue closure.
- [ ] Attach dry-run report and at least one rehydrate evidence log.
