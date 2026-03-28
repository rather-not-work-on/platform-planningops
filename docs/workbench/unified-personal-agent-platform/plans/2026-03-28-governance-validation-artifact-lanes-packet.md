---
title: plan: Governance Validation Artifact Lanes Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills deterministic governance validator report artifacts and locks them with a comparison regression.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
  - ./2026-03-28-contract-helper-surface-sync-packet.md
---

# plan: Governance Validation Artifact Lanes Packet

## Summary
- Promote deterministic `repo-boundary`, `script-role`, and `artifact-storage-policy` validator reports into tracked `.test.json` artifacts.
- Keep those artifacts distinct from mutable live validation outputs.
- Add one regression that regenerates the three reports and compares them to the committed artifacts.

## Scope
- `planningops/artifacts/validation/repo-boundary-report.test.json`
- `planningops/artifacts/validation/script-role-report.test.json`
- `planningops/artifacts/validation/artifact-storage-policy-valid.test.json`
- `planningops/scripts/test_governance_validation_artifact_lanes.sh`
- `planningops/artifacts/README.md`

## Acceptance
- `test_governance_validation_artifact_lanes.sh` passes
- `test_validate_repo_boundaries_contract.sh` passes
- `test_validate_script_roles_contract.sh` passes
- `test_validate_artifact_storage_policy_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
