---
title: plan: Backlog Materialize Snapshot Regression Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds canonical expected-output fixtures and a regression that compares offline backlog materialization CLI outputs to normalized sample snapshots.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-fixture-smoke-packet.md
---

# plan: Backlog Materialize Snapshot Regression Packet

## Summary
- Store canonical expected outputs for the sample program manifest and label backfill flows.
- Normalize timestamp and temp-path noise before comparison.
- Lock the offline materialization path to exact sample snapshots.

## Scope
- `planningops/fixtures/program-manifest-sample.expected.json`
- `planningops/fixtures/program-manifest-report-sample.expected.json`
- `planningops/fixtures/issue-label-backfill-sample-updated-issues.expected.json`
- `planningops/fixtures/issue-label-backfill-report-sample.expected.json`
- `planningops/scripts/test_backlog_materialize_sample_snapshot_contract.sh`

## Acceptance
- `test_backlog_materialize_sample_snapshot_contract.sh` passes
- `test_module_readme_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
