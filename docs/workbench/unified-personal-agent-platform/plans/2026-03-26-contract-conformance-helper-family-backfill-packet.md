---
title: plan: Contract-Conformance Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the contract-conformance helper entrypoint and its contract and wiring regressions so the local federated matrix no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-federated-summary-helper-family-backfill-packet.md
  - ./2026-03-26-runtime-operations-ready-helper-family-backfill-packet.md
---

# plan: Contract-Conformance Helper Family Backfill Packet

## Summary
- Backfill the tracked `contract-conformance` helper family that the local federated matrix and CI helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so cross-repo conformance checking is reproducible from remote `main`.
- Verify the helper owns the cross-repo checker invocation instead of leaving the raw checker command inlined in the matrix lane.

## Scope
- `planningops/scripts/run_contract_conformance_ci_check.sh`
- `planningops/scripts/test_run_contract_conformance_ci_check_contract.sh`
- `planningops/scripts/test_contract_conformance_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_contract_conformance_ci_check_contract.sh` passes
- `test_contract_conformance_helper_wiring.sh` proves the local matrix block calls only the canonical helper
- `run_contract_conformance_ci_check.sh --run-id <id> --workspace-root .. --bootstrap-mode auto --python-bin python3` succeeds from the repo root
