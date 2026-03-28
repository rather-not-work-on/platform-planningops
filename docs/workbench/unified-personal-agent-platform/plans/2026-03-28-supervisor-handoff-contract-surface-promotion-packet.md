---
title: plan: Supervisor Handoff Contract Surface Promotion Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the canonical supervisor handoff contract and contract regression to reflect the newly tracked validation, bundle, readiness, and doctor/gate surfaces.
related_docs:
  - ./2026-03-28-supervisor-handoff-bundle-doctor-gate-family-backfill-packet.md
  - ./2026-03-28-supervisor-handoff-bundle-readiness-assessor-family-backfill-packet.md
---

# plan: Supervisor Handoff Contract Surface Promotion Packet

## Summary
- Promote the canonical `supervisor operator handoff` contract so it matches the now-tracked validation, bundle, readiness, preview/display, and doctor/gate surfaces.
- Lock the contract regression to real emitted supervisor artifacts, including degraded federated-ci blocked handoffs, bundle sidecar attachment propagation, and first-action/CTA carry-through.
- Keep this unit limited to the contract doc and its regression; no new implementation surfaces are introduced here.

## Scope
- `planningops/contracts/supervisor-operator-handoff-contract.md`
- `planningops/scripts/test_supervisor_operator_handoff_contract.sh`
- workbench hub link for this contract-surface promotion

## Acceptance
- `test_supervisor_operator_handoff_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
