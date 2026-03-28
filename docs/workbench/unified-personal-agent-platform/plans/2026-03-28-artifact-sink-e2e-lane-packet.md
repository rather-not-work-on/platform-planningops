---
title: plan: Artifact Sink E2E Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a normalized artifact-sink end-to-end snapshot into a committed verification lane.
related_docs:
  - ./2026-03-28-external-only-commit-guard-artifact-lanes-packet.md
  - ./2026-03-28-external-only-artifact-migration-lanes-packet.md
---

# plan: Artifact Sink E2E Lane Packet

## Summary
- Regenerate a normalized artifact sink end-to-end summary from the local and s3 mock backends.
- Keep dynamic path and timestamp fields normalized inside the committed lane artifact.
- Add one regression that compares the normalized summary against the committed baseline.

## Scope
- `planningops/artifacts/validation/artifact-sink-e2e.test.json`
- `planningops/scripts/test_artifact_sink_e2e_artifact_lane.sh`
- `planningops/contracts/artifact-sink-contract.md`

## Acceptance
- `test_artifact_sink_e2e.sh` passes
- `test_artifact_sink_e2e_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
