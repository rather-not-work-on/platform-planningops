---
title: plan: Project Field Schema Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a fixture-backed `.sample.json` lane for `validate_project_field_schema.py` so project-schema validation can be replayed deterministically without live GitHub fetches.
related_docs:
  - ./2026-03-28-project-field-schema-artifact-refresh-packet.md
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
---

# plan: Project Field Schema Sample Artifact Lane Packet

## Summary
- Add fixture-backed `gh project field-list` and `gh project item-list` payloads for the project field schema validator.
- Publish a committed sample validation report generated from those fixtures.
- Add one regression that replays the validator through a mocked `gh` binary and compares the normalized output to the committed `.sample.json` lane.

## Scope
- `planningops/fixtures/project-field-schema-field-list.sample.json`
- `planningops/fixtures/project-field-schema-item-list.sample.json`
- `planningops/artifacts/validation/project-field-schema-report.sample.json`
- `planningops/scripts/test_validate_project_field_schema_artifact_lane.sh`

## Acceptance
- `test_validate_project_field_schema_matrix.sh` passes
- `test_validate_project_field_schema_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
