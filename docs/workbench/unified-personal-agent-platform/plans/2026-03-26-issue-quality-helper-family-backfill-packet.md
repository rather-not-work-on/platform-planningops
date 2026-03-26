---
title: plan: Issue-Quality Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the issue-quality helper entrypoint and its contract and wiring regressions so the loop-guardrails workflow no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-runtime-operations-ready-helper-family-backfill-packet.md
  - ./2026-03-26-provider-profile-helper-family-backfill-packet.md
---

# plan: Issue-Quality Helper Family Backfill Packet

## Summary
- Backfill the tracked `issue-quality` helper family that the loop-guardrails workflow and helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so issue-quality validation is reproducible from remote `main`.
- Verify the helper owns the contract regressions plus live issue-quality validator instead of leaving those steps inlined in the workflow job.

## Scope
- `planningops/scripts/run_issue_quality_ci_check.sh`
- `planningops/scripts/test_run_issue_quality_ci_check_contract.sh`
- `planningops/scripts/test_issue_quality_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_issue_quality_ci_check_contract.sh` passes
- `test_issue_quality_helper_wiring.sh` proves the workflow block calls only the canonical helper
- `run_issue_quality_ci_check.sh --python-bin python3` succeeds from the repo root
