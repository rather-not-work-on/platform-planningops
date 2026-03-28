---
title: plan: Backlog Materialize Sample Fixture Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Extracts deterministic sample issue fixtures for program-manifest and issue-label backfill contract coverage.
related_docs:
  - ./2026-03-28-meta-plan-execution-artifact-refresh-packet.md
---

# plan: Backlog Materialize Sample Fixture Packet

## Summary
- Add reusable sample issues fixtures for program manifest and label backfill contract tests.
- Remove large inline JSON payloads from the shell tests.
- Keep the unit test-only so later live artifact refreshes can target deterministic fixture-backed evidence.

## Scope
- `planningops/fixtures/program-manifest-sample-issues.json`
- `planningops/fixtures/issue-label-backfill-sample-issues.json`
- `planningops/scripts/test_build_program_manifest_contract.sh`
- `planningops/scripts/test_backfill_issue_labels_contract.sh`

## Acceptance
- `test_build_program_manifest_contract.sh` passes
- `test_backfill_issue_labels_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
