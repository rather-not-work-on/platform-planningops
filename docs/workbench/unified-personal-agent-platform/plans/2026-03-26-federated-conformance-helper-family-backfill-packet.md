---
title: plan: Federated-Conformance Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the federated-conformance helper entrypoint and its contract and wiring regressions so the GitHub federated-conformance lane no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-platform-contracts-helper-family-backfill-packet.md
  - ./2026-03-26-contract-conformance-helper-family-backfill-packet.md
---

# plan: Federated-Conformance Helper Family Backfill Packet

## Summary
- Backfill the tracked `federated-conformance` helper family that the GitHub workflow lane and helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so artifact-policy rollout and cross-repo conformance checks are reproducible from remote `main`.
- Verify the helper owns the artifact-policy rollout and managed bootstrap/conformance checker invocation instead of leaving those commands inlined in workflow YAML.

## Scope
- `planningops/scripts/run_federated_conformance_ci_check.sh`
- `planningops/scripts/test_run_federated_conformance_ci_check_contract.sh`
- `planningops/scripts/test_federated_conformance_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_federated_conformance_ci_check_contract.sh` passes
- `test_federated_conformance_helper_wiring.sh` proves the workflow `federated-conformance` job calls only the canonical helper
- `run_federated_conformance_ci_check.sh --run-id <id> --workspace-root .. --python-bin python3 --policy-output planningops/artifacts/validation/federated-artifact-policy-rollout-report.json --bootstrap-mode auto --output planningops/artifacts/conformance/<id>.json` succeeds from the repo root
