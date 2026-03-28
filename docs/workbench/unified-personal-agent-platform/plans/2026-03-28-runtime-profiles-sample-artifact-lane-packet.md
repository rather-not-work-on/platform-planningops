---
title: plan: Runtime Profiles Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` lane for `validate_runtime_profiles.py`, separate from mutable live runtime profile reports.
related_docs:
  - ./2026-03-26-runtime-profiles-validator-family-backfill-packet.md
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
---

# plan: Runtime Profiles Sample Artifact Lane Packet

## Summary
- Publish a committed sample runtime-profiles validation report generated from the checked-in runtime profile catalog.
- Add one regression that replays `validate_runtime_profiles.py` and compares the normalized output to the committed `.sample.json` artifact.
- Keep the sample lane separate from mutable live `runtime-profiles-report.json` outputs.

## Scope
- `planningops/artifacts/validation/runtime-profiles-report.sample.json`
- `planningops/scripts/test_validate_runtime_profiles_artifact_lane.sh`
- `planningops/artifacts/README.md`
- `planningops/scripts/README.md`

## Acceptance
- `test_validate_runtime_profiles_contract.sh` passes
- `test_validate_runtime_profiles_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
