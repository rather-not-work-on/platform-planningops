---
title: plan: Backlog Materialize Sample Report Snapshot Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Locks the full offline `core/backlog/materialize.py` dry-run lane with normalized report and projected-issue snapshots.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-report-smoke-packet.md
  - ./2026-03-28-backlog-materialize-snapshot-regression-packet.md
---

# plan: Backlog Materialize Sample Report Snapshot Packet

## Summary
- Capture normalized expected outputs for the offline backlog materialize dry-run lane.
- Snapshot the top-level materialize report, compile report, issue-quality report, and projected issues.
- Keep the report lane deterministic without reusing live supervisor artifacts.

## Scope
- `planningops/fixtures/backlog-materialize-*.expected.json`
- `planningops/scripts/test_backlog_materialize_sample_report_snapshot_contract.sh`
- `planningops/scripts/README.md`

## Acceptance
- `test_backlog_materialize_sample_report_snapshot_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
