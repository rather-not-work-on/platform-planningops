---
title: plan: Federated-Summary Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the federated-summary helper entrypoint and its contract, wiring, and smoke regressions so the workflow summary lane no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-runtime-handoff-federated-ci-summary-family-backfill-packet.md
  - ./2026-03-26-issue-quality-helper-family-backfill-packet.md
---

# plan: Federated-Summary Helper Family Backfill Packet

## Summary
- Backfill the tracked `federated-summary` helper family that the federated matrix workflow already invokes directly.
- Promote the missing helper entrypoint plus contract, wiring, and smoke regressions into git-tracked reality so summary synthesis and readiness sidecars are reproducible from remote `main`.
- Verify the helper owns summary init/append/finalize and readiness generation instead of leaving those steps inlined in workflow YAML.

## Scope
- `planningops/scripts/run_federated_summary_ci_check.sh`
- `planningops/scripts/test_run_federated_summary_ci_check_contract.sh`
- `planningops/scripts/test_federated_summary_helper_wiring.sh`
- `planningops/scripts/test_run_federated_summary_ci_check_smoke.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_federated_summary_ci_check_contract.sh` passes
- `test_federated_summary_helper_wiring.sh` proves the workflow job calls only the canonical helper
- `test_run_federated_summary_ci_check_smoke.sh` passes for both pass and fail summary cases
