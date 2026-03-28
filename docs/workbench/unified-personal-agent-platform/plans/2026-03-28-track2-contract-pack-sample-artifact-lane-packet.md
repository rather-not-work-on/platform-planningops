---
title: plan: Track2 Contract Pack Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` lane for `run_track2_contract_pack_validation.py` by mocking command checks while preserving real artifact and reference validation.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
  - ./track2-implementation-readiness-packet.md
---

# plan: Track2 Contract Pack Sample Artifact Lane Packet

## Summary
- Replay the Track2 contract-pack validator with mocked command checks so the report no longer depends on live GitHub-side validators.
- Preserve real artifact/frontmatter and reference-rule checks against the checked-in workbench docs.
- Publish the resulting report as a committed `.sample.json` artifact and lock it with one replay regression.

## Scope
- `planningops/artifacts/validation/track2-contract-pack-report.sample.json`
- `planningops/scripts/test_run_track2_contract_pack_validation_artifact_lane.sh`
- `planningops/artifacts/README.md`
- `planningops/scripts/README.md`

## Acceptance
- `test_run_track2_contract_pack_validation_artifact_lane.sh` passes
- `test_module_readme_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
