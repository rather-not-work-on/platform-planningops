---
title: plan: External Only Artifact Migration Lanes Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes deterministic tracked migration dry-run and apply outputs into committed artifact lanes.
related_docs:
  - ./2026-03-28-external-only-commit-guard-artifact-lanes-packet.md
  - ./2026-03-28-artifact-storage-policy-validation-artifact-lanes-packet.md
---

# plan: External Only Artifact Migration Lanes Packet

## Summary
- Reuse the tracked-mode external-only policy fixture for artifact migration coverage.
- Promote deterministic tracked dry-run and apply migration outputs into committed `.test.json` lanes.
- Add a comparison regression that regenerates both lanes and compares them to the committed snapshots.

## Scope
- `planningops/artifacts/validation/artifact-migration-tracked-dry-run.test.json`
- `planningops/artifacts/validation/artifact-migration-tracked-apply.test.json`
- `planningops/scripts/test_migrate_external_only_artifact_lanes.sh`

## Acceptance
- `test_migrate_external_only_artifacts_contract.sh` passes
- `test_migrate_external_only_artifact_lanes.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
