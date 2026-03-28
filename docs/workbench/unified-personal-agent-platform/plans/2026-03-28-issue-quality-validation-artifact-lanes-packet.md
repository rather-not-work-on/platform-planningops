---
title: plan: Issue Quality Validation Artifact Lanes Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes deterministic issue-quality valid and invalid validator reports into tracked test lanes.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
  - ./2026-03-28-governance-validation-artifact-lanes-packet.md
---

# plan: Issue Quality Validation Artifact Lanes Packet

## Summary
- Promote deterministic `issue-quality-valid.test.json` and `issue-quality-invalid.test.json` outputs into tracked validation artifacts.
- Keep the `.test.json` issue-quality lanes distinct from the fixture-backed `.sample.json` validation outputs.
- Add one regression that regenerates both lanes and compares them to the committed snapshots.

## Scope
- `planningops/artifacts/validation/issue-quality-valid.test.json`
- `planningops/artifacts/validation/issue-quality-invalid.test.json`
- `planningops/scripts/test_issue_quality_validation_artifact_lanes.sh`
- `planningops/artifacts/README.md`

## Acceptance
- `test_issue_quality_validation_artifact_lanes.sh` passes
- `test_validate_issue_quality_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
