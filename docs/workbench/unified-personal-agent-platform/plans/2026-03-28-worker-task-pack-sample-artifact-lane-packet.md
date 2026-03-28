---
title: plan: Worker Task Pack Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` artifact lane for `validate_worker_task_pack.py`, separate from mutable live task-pack reports.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
  - ./2026-03-26-runtime-profiles-validator-family-backfill-packet.md
---

# plan: Worker Task Pack Sample Artifact Lane Packet

## Summary
- Publish a committed sample worker-task-pack report generated from the current runtime profile catalog and a fixed `reflection_action` replay input.
- Add one regression that replays `validate_worker_task_pack.py` and compares the normalized output to the committed `.sample.json` artifact.
- Keep the sample lane separate from mutable live `worker-task-pack-report.json` outputs.

## Scope
- `planningops/artifacts/validation/worker-task-pack-report.sample.json`
- `planningops/scripts/test_validate_worker_task_pack_artifact_lane.sh`
- `planningops/artifacts/README.md`
- `planningops/scripts/README.md`

## Acceptance
- `test_validate_worker_task_pack_contract.sh` passes
- `test_validate_worker_task_pack_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
