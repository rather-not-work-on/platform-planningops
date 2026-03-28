---
title: plan: Plan Projection Artifact Refresh Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the committed plan-projection validation artifact so canonical sample projection evidence matches the current verifier output.
related_docs:
  - ./2026-03-28-project-field-schema-artifact-refresh-packet.md
---

# plan: Plan Projection Artifact Refresh Packet

## Summary
- Re-run the sample plan projection verifier against the committed sample contract and snapshot fixtures.
- Refresh the committed projection validation report without changing verifier behavior.
- Keep the unit artifact-only: no helper, workflow, or contract logic changes.

## Scope
- `planningops/artifacts/validation/plan-projection-report.json`
- workbench hub link for this packet

## Acceptance
- `test_verify_plan_projection_contract.sh` passes
- `python3 planningops/scripts/verify_plan_projection.py --contract-file planningops/fixtures/plan-execution-contract-sample.json --snapshot-file planningops/fixtures/plan-projection-snapshot-sample.json --strict --output planningops/artifacts/validation/plan-projection-report.json` succeeds
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
