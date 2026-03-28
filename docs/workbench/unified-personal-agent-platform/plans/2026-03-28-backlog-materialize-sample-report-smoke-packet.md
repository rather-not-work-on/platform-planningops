---
title: plan: Backlog Materialize Sample Report Smoke Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds a real `core/backlog/materialize.py` dry-run smoke that drives the offline sample execution contract through compile, label, manifest, and issue-quality outputs.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-fixture-packet.md
  - ./2026-03-28-backlog-materialize-sample-fixture-smoke-packet.md
  - ./2026-03-28-backlog-materialize-snapshot-regression-packet.md
---

# plan: Backlog Materialize Sample Report Smoke Packet

## Summary
- Extract the sample execution contract into a reusable fixture.
- Run `core/backlog/materialize.py` in dry-run mode against that fixture.
- Assert the combined compile, label, manifest, and issue-quality reports stay deterministic.

## Scope
- `planningops/fixtures/backlog-materialization-sample-contract.json`
- `planningops/scripts/test_backlog_materialization_contract.sh`
- `planningops/scripts/test_backlog_materialize_sample_report_smoke.sh`
- `planningops/scripts/README.md`

## Acceptance
- `test_backlog_materialization_contract.sh` passes
- `test_backlog_materialize_sample_report_smoke.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
