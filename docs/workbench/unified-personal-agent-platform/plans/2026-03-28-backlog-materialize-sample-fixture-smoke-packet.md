---
title: plan: Backlog Materialize Sample Fixture Smoke Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds a smoke regression that drives the new offline manifest and label fixtures through the real backlog materialization CLIs.
related_docs:
  - ./2026-03-28-backlog-materialize-sample-fixture-packet.md
---

# plan: Backlog Materialize Sample Fixture Smoke Packet

## Summary
- Run the sample manifest fixture through `build_program_manifest.py`.
- Run the sample label fixture through `backfill_issue_labels.py`.
- Assert the combined offline materialization flow stays deterministic.

## Scope
- `planningops/scripts/test_backlog_materialize_sample_fixture_smoke.sh`
- `planningops/scripts/README.md`

## Acceptance
- `test_backlog_materialize_sample_fixture_smoke.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
