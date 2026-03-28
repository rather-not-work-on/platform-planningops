---
title: plan: Issue Quality Artifact Refresh Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the committed issue-quality validation artifact so canonical evidence matches the current in-scope planning issue set.
related_docs:
  - ./2026-03-26-issue-quality-helper-family-backfill-packet.md
  - ./2026-03-28-federated-label-taxonomy-helper-sync-packet.md
---

# plan: Issue Quality Artifact Refresh Packet

## Summary
- Re-run the issue-quality validator against the current in-scope planning issues.
- Refresh the committed validation report without touching label backfill side effects.
- Keep the unit artifact-only: no helper, contract, or workflow logic changes.

## Scope
- `planningops/artifacts/validation/issue-quality-report.json`
- workbench hub link for this packet

## Acceptance
- `test_validate_issue_quality_contract.sh` passes
- `python3 planningops/scripts/validate_issue_quality.py --strict` succeeds
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
