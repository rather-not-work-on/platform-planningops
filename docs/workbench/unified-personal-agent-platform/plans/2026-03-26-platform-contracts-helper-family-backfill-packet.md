---
title: plan: Platform-Contracts Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the platform-contracts helper entrypoint and its contract and wiring regressions so the GitHub contract-conformance lane no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-contract-conformance-helper-family-backfill-packet.md
  - ./2026-03-26-federated-summary-helper-family-backfill-packet.md
---

# plan: Platform-Contracts Helper Family Backfill Packet

## Summary
- Backfill the tracked `platform-contracts` helper family that the GitHub `contract-conformance` lane and helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so platform-contract validation is reproducible from remote `main`.
- Verify the helper owns the managed-venv bootstrap, contract validation, and schema-change classification instead of leaving those commands inlined in workflow YAML.

## Scope
- `planningops/scripts/run_platform_contracts_ci_check.sh`
- `planningops/scripts/test_run_platform_contracts_ci_check_contract.sh`
- `planningops/scripts/test_platform_contracts_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_platform_contracts_ci_check_contract.sh` passes
- `test_platform_contracts_helper_wiring.sh` proves the workflow `contract-conformance` job calls only the canonical helper
- `run_platform_contracts_ci_check.sh --contracts-root ../platform-contracts --python-bin python3` succeeds from the repo root
