---
title: plan: External-Artifact-Residency Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the external-artifact-residency helper entrypoint and its contract and wiring regressions so the GitHub loop-guardrails lane no longer depends on local-only helper files.
related_docs:
  - ./2026-03-26-control-plane-governance-helper-family-backfill-packet.md
  - ./2026-03-26-federated-conformance-helper-family-backfill-packet.md
---

# plan: External-Artifact-Residency Helper Family Backfill Packet

## Summary
- Backfill the tracked `external-artifact-residency` helper family that the GitHub `loop-guardrails` lane and helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so external-only commit/artifact residency checks are reproducible from remote `main`.
- Verify the helper owns the commit-guard diff and tracked audits instead of leaving those commands and base-ref fallback logic inlined in workflow YAML.

## Scope
- `planningops/scripts/run_external_artifact_residency_ci_check.sh`
- `planningops/scripts/test_run_external_artifact_residency_ci_check_contract.sh`
- `planningops/scripts/test_external_artifact_residency_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_external_artifact_residency_ci_check_contract.sh` passes
- `test_external_artifact_residency_helper_wiring.sh` proves the workflow `loop-guardrails` subsection calls only the canonical helper
- `run_external_artifact_residency_ci_check.sh --base-ref HEAD --head-ref HEAD --python-bin python3` succeeds from the repo root
