---
title: plan: Backlog Materialize Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes fixture-backed `program-manifest` and `issue-label-backfill` sample artifacts into canonical `.sample.json` artifact lanes separate from live latest outputs.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-fixture-packet.md
  - ./2026-03-28-backlog-materialize-sample-report-smoke-packet.md
  - ./2026-03-28-backlog-materialize-sample-report-snapshot-packet.md
---

# plan: Backlog Materialize Sample Artifact Lane Packet

## Summary
- Publish committed `.sample.json` artifacts for the fixture-backed manifest and label lanes.
- Keep those artifacts separate from mutable live latest outputs under `planningops/artifacts/`.
- Add one regression that re-materializes the fixture outputs and compares them to the committed sample artifacts.

## Scope
- `planningops/artifacts/program/program-manifest.sample.json`
- `planningops/artifacts/validation/program-manifest-report.sample.json`
- `planningops/artifacts/backlog/issue-label-updated-issues.sample.json`
- `planningops/artifacts/validation/issue-label-backfill-report.sample.json`
- `planningops/scripts/test_backlog_materialize_sample_artifact_lane.sh`
- `planningops/artifacts/README.md`

## Acceptance
- `test_backlog_materialize_sample_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
