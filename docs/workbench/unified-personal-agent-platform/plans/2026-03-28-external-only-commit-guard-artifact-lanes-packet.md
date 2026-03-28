---
title: plan: External Only Commit Guard Artifact Lanes Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes deterministic external-only commit guard outputs into tracked validator lanes.
related_docs:
  - ./2026-03-28-artifact-storage-policy-validation-artifact-lanes-packet.md
  - ./2026-03-28-governance-validation-artifact-lanes-packet.md
---

# plan: External Only Commit Guard Artifact Lanes Packet

## Summary
- Extract stable allowed, blocked, and tracked-mode fixtures for external-only commit guard coverage.
- Promote deterministic allowed, blocked, and tracked validator outputs into tracked `.test.json` lanes.
- Add a comparison regression that regenerates all three lanes and compares them to the committed snapshots.

## Scope
- `planningops/fixtures/external-only-commit-guard-allowed-files.sample.txt`
- `planningops/fixtures/external-only-commit-guard-blocked-files.sample.txt`
- `planningops/fixtures/external-only-commit-guard-policy.sample.json`
- `planningops/artifacts/validation/external-only-commit-guard-allowed.test.json`
- `planningops/artifacts/validation/external-only-commit-guard-blocked.test.json`
- `planningops/artifacts/validation/external-only-commit-guard-tracked.test.json`
- `planningops/scripts/test_external_only_commit_guard_artifact_lanes.sh`

## Acceptance
- `test_validate_external_only_commit_guard.sh` passes
- `test_external_only_commit_guard_artifact_lanes.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
