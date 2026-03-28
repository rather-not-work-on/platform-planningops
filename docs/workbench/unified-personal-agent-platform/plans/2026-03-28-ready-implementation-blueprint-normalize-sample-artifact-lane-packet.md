---
title: plan: Ready-Implementation Blueprint Normalize Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` lane for `normalize_ready_implementation_blueprint_refs.py` using fixture-backed `gh` responses.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
---

# plan: Ready-Implementation Blueprint Normalize Sample Artifact Lane Packet

## Summary
- Add fixture-backed project item-list and issue-view payloads for the ready-implementation blueprint normalizer.
- Publish a committed dry-run normalization report generated from those fixtures.
- Add one regression that replays the normalizer through a mocked `gh` binary and compares the normalized output to the committed `.sample.json` artifact.

## Scope
- `planningops/fixtures/ready-implementation-blueprint-project-items.sample.json`
- `planningops/fixtures/ready-implementation-blueprint-issue-view.sample.json`
- `planningops/artifacts/validation/ready-implementation-blueprint-normalize-report.sample.json`
- `planningops/scripts/test_normalize_ready_implementation_blueprint_refs_artifact_lane.sh`

## Acceptance
- `test_normalize_ready_implementation_blueprint_refs.sh` passes
- `test_normalize_ready_implementation_blueprint_refs_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
