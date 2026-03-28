---
title: plan: Branch Protection Apply Artifact Lanes Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes deterministic branch protection apply outputs into tracked validator lanes backed by stable fixtures.
related_docs:
  - ./2026-03-28-branch-protection-audit-artifact-lanes-packet.md
  - ./2026-03-28-governance-validation-artifact-lanes-packet.md
---

# plan: Branch Protection Apply Artifact Lanes Packet

## Summary
- Extract stable repository-governance apply fixtures for branch protection dry-run coverage.
- Promote deterministic valid and invalid branch protection apply outputs into tracked `.test.json` artifact lanes.
- Add a comparison regression that regenerates both apply lanes from the fixtures and compares them to the committed snapshots.

## Scope
- `planningops/fixtures/repository-governance-apply-policy.sample.json`
- `planningops/fixtures/repository-governance-apply-policy-invalid.sample.json`
- `planningops/fixtures/branch-protection-apply-snapshot.sample.json`
- `planningops/artifacts/validation/branch-protection-apply-valid.test.json`
- `planningops/artifacts/validation/branch-protection-apply-invalid.test.json`
- `planningops/scripts/test_branch_protection_apply_artifact_lanes.sh`

## Acceptance
- `test_apply_branch_protection_contract.sh` passes
- `test_branch_protection_apply_artifact_lanes.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
