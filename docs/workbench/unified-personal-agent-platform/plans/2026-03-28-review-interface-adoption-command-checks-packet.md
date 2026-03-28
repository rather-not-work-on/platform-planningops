---
title: plan: Review Interface Adoption Command Checks Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills command-check coverage for review interface adoption so cross-repo interface validation can assert executable checks as well as issue, gap, and file markers.
related_docs:
  - ./2026-03-28-federated-tooling-contract-test-family-backfill-packet.md
---

# plan: Review Interface Adoption Command Checks Packet

## Summary
- Extend `review_interface_adoption.py` with explicit `command_checks`.
- Backfill a deterministic regression proving pass/fail command exit codes are captured in the report.
- Keep the unit limited to the runner change, regression, and workbench references.

## Scope
- `planningops/scripts/federation/review_interface_adoption.py`
- `planningops/scripts/test_review_interface_adoption.sh`
- workbench hub link for this command-check backfill

## Acceptance
- `test_review_interface_adoption.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
