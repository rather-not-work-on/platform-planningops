---
title: plan: Plan Projection Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` artifact lane for `verify_plan_projection.py`, separate from the mutable live latest projection report.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
  - ./2026-03-28-plan-projection-artifact-refresh-packet.md
---

# plan: Plan Projection Sample Artifact Lane Packet

## Summary
- Publish a committed sample projection report generated from the PEC sample contract and snapshot fixture.
- Add one regression that replays `verify_plan_projection.py` in snapshot mode and compares the normalized output to the committed `.sample.json` artifact.
- Keep the sample lane separate from the mutable `plan-projection-report.json` latest artifact.

## Scope
- `planningops/artifacts/validation/plan-projection-report.sample.json`
- `planningops/scripts/test_verify_plan_projection_artifact_lane.sh`
- `planningops/artifacts/README.md`
- `planningops/fixtures/README.md`
- `planningops/scripts/README.md`

## Acceptance
- `test_verify_plan_projection_contract.sh` passes
- `test_verify_plan_projection_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
