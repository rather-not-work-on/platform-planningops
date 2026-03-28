---
title: plan: Blueprint Pack Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` lane for `validate_blueprint_pack.py`, backed by a committed markdown fixture.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
---

# plan: Blueprint Pack Sample Artifact Lane Packet

## Summary
- Add a committed valid blueprint-pack markdown fixture with all required sections.
- Publish a committed sample report generated from that fixture.
- Add one regression that replays `validate_blueprint_pack.py` and compares the output to the committed `.sample.json` artifact.

## Scope
- `planningops/fixtures/blueprint-pack-valid.sample.md`
- `planningops/artifacts/validation/blueprint-pack-report.sample.json`
- `planningops/scripts/test_validate_blueprint_pack_artifact_lane.sh`

## Acceptance
- `test_validate_blueprint_pack_contract.sh` passes
- `test_validate_blueprint_pack_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
