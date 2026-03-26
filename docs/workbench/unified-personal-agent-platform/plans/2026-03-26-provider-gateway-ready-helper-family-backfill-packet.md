---
title: plan: Provider-Gateway-Ready Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the provider-gateway-ready helper entrypoint and its contract and wiring regressions so the local federated matrix and CI guardrails no longer depend on local-only helper files.
related_docs:
  - ./2026-03-26-provider-profile-helper-family-backfill-packet.md
  - ./2026-03-26-runtime-handoff-federated-ci-summary-family-backfill-packet.md
---

# plan: Provider-Gateway-Ready Helper Family Backfill Packet

## Summary
- Backfill the tracked `provider-gateway-ready` helper family that the local federated matrix and CI helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so provider-gateway readiness checks are reproducible from remote `main`.
- Verify the helper owns stack bootstrap and cleanup instead of leaving launcher commands inlined in the matrix lane.

## Scope
- `planningops/scripts/run_provider_gateway_ready_ci_check.sh`
- `planningops/scripts/test_run_provider_gateway_ready_ci_check_contract.sh`
- `planningops/scripts/test_provider_gateway_ready_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_provider_gateway_ready_ci_check_contract.sh` passes
- `test_provider_gateway_ready_helper_wiring.sh` proves the local matrix block calls only the canonical helper
- `run_provider_gateway_ready_ci_check.sh --run-id <id>` succeeds against the sibling `platform-provider-gateway` repo and leaves no stale LiteLLM stack behind
