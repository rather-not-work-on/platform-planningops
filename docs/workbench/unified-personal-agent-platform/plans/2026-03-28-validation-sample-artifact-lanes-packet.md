---
title: plan: Validation Sample Artifact Lanes Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes deterministic `.sample.json` validation artifacts for plan-compile and issue-quality outputs, separate from mutable live latest reports.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-artifact-lane-packet.md
  - ./2026-03-28-plan-compile-artifact-refresh-packet.md
  - ./2026-03-28-issue-quality-artifact-refresh-packet.md
---

# plan: Validation Sample Artifact Lanes Packet

## Summary
- Publish committed sample validation artifacts for `compile_plan_to_backlog.py`.
- Publish committed sample validation artifacts for valid and invalid `validate_issue_quality.py` fixture runs.
- Add one regression that replays those fixture lanes and compares them to the committed `.sample.json` artifacts.

## Scope
- `planningops/fixtures/plan-compile-sample-issues.json`
- `planningops/artifacts/validation/plan-compile-report.sample.json`
- `planningops/artifacts/validation/issue-quality-valid.sample.json`
- `planningops/artifacts/validation/issue-quality-invalid.sample.json`
- `planningops/scripts/test_validation_sample_artifact_lanes.sh`

## Acceptance
- `test_validation_sample_artifact_lanes.sh` passes
- `test_compile_plan_to_backlog_contract.sh` passes
- `test_validate_issue_quality_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
