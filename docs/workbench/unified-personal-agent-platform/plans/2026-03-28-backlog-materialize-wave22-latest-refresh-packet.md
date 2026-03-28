---
title: plan: Backlog Materialize Wave22 Latest Refresh Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the canonical backlog materialization outputs from the wave22 execution contract so projected issues, label backfill evidence, and program-manifest evidence share one deterministic source plan.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-artifact-lane-packet.md
  - ./2026-03-28-backlog-materialize-sample-report-snapshot-packet.md
---

# plan: Backlog Materialize Wave22 Latest Refresh Packet

## Summary
- Replay `planningops/scripts/core/backlog/materialize.py` against the checked-in wave22 execution contract.
- Refresh the canonical latest backlog-projected issues, issue-label backfill report, and program-manifest/report outputs from one consistent source plan.
- Keep auxiliary compile, quality, and materialization reports outside the committed unit by routing them to temporary outputs.

## Scope
- `planningops/artifacts/backlog/projected-issues.json`
- `planningops/artifacts/validation/issue-label-backfill-report.json`
- `planningops/artifacts/program/program-manifest.json`
- `planningops/artifacts/validation/program-manifest-report.json`

## Acceptance
- `test_backlog_materialization_contract.sh` passes
- `python3 planningops/scripts/core/backlog/materialize.py --contract-file docs/workbench/unified-personal-agent-platform/plans/2026-03-10-runtime-mission-wave22.execution-contract.json ...` succeeds with canonical projected-issues, label, and manifest outputs
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
