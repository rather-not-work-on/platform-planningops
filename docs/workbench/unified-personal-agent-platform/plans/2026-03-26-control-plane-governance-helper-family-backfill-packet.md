---
title: plan: Control-Plane Governance Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the control-plane-governance helper entrypoint and its contract and wiring regressions so the GitHub loop-guardrails lane no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-federated-conformance-helper-family-backfill-packet.md
  - ./2026-03-26-platform-contracts-helper-family-backfill-packet.md
---

# plan: Control-Plane Governance Helper Family Backfill Packet

## Summary
- Backfill the tracked `control-plane-governance` helper family that the GitHub `loop-guardrails` lane and helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so control-plane artifact-policy, ontology, memory, inventory, and scheduler-queue governance checks are reproducible from remote `main`.
- Verify the helper owns the control-plane validator and audit step inventory instead of leaving those commands inlined in workflow YAML.

## Scope
- `planningops/scripts/run_control_plane_governance_ci_check.sh`
- `planningops/scripts/test_run_control_plane_governance_ci_check_contract.sh`
- `planningops/scripts/test_control_plane_governance_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_control_plane_governance_ci_check_contract.sh` passes
- `test_control_plane_governance_helper_wiring.sh` proves the workflow `loop-guardrails` subsection calls only the canonical helper
- `test_run_control_plane_governance_ci_check_smoke.sh` passes with deterministic fixture inputs
