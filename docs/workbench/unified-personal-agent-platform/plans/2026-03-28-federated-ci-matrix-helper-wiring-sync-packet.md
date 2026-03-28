---
title: plan: Federated CI Matrix Helper Wiring Sync Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the GitHub and local federated CI matrix surfaces onto the helper entrypoints that were already backfilled, so workflow and local execution share the same canonical lanes and summary sidecars.
related_docs:
  - ./2026-03-26-federated-conformance-helper-family-backfill-packet.md
  - ./2026-03-26-federated-summary-helper-family-backfill-packet.md
  - ./2026-03-26-platform-contracts-helper-family-backfill-packet.md
---

# plan: Federated CI Matrix Helper Wiring Sync Packet

## Summary
- Rewire the GitHub federated CI workflow to call canonical helper entrypoints instead of inlining lane-specific command blocks.
- Align the local federated matrix runner with the same helper surfaces and expanded summary sidecar chain.
- Keep the unit focused on workflow and local-matrix wiring plus workbench traceability.

## Scope
- `.github/workflows/federated-ci-matrix.yml`
- `planningops/scripts/federation/federated_ci_matrix_local.sh`
- workbench hub link for this packet

## Acceptance
- `test_federated_ci_workflow_summary_contract.sh` passes
- `test_federated_ci_local_matrix_mode_contract.sh` passes
- helper wiring regressions for promoted lanes pass
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
