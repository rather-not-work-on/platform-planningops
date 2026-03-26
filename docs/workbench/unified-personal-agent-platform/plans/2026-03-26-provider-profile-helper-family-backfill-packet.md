---
title: plan: Provider-Profile Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the provider-profile helper entrypoint and its contract and wiring regressions so the local federated matrix and GitHub workflow no longer depend on local-only helper files.
related_docs:
  - ./2026-03-26-runtime-handoff-federated-ci-summary-family-backfill-packet.md
  - ./2026-03-26-monday-agent-memory-wave-y-runtime-handoff-ops-summary-lane-packet.md
---

# plan: Provider-Profile Helper Family Backfill Packet

## Summary
- Backfill the tracked `provider-profile` helper family that both the local federated matrix and the GitHub workflow already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so provider-profile CI is reproducible from remote `main`.
- Verify the helper dry-run still delegates only to the sibling `platform-provider-gateway` LiteLLM launcher surface.

## Scope
- `planningops/scripts/run_provider_profile_ci_check.sh`
- `planningops/scripts/test_run_provider_profile_ci_check_contract.sh`
- `planningops/scripts/test_provider_profile_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_provider_profile_ci_check_contract.sh` passes
- `test_provider_profile_helper_wiring.sh` proves local matrix and workflow blocks call only the canonical helper
- `run_provider_profile_ci_check.sh --run-id <id>` succeeds against the sibling `platform-provider-gateway` repo
