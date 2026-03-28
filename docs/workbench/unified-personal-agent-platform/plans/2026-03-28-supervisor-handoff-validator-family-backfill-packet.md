---
title: plan: Supervisor Handoff Validator Family Backfill Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the base supervisor handoff schemas, validator, and regression so planningops can validate operator-report and inbox-payload artifacts from remote main.
related_docs:
  - ./2026-03-26-runtime-profiles-validator-family-backfill-packet.md
  - ./2026-03-26-control-plane-governance-helper-smoke-packet.md
---

# plan: Supervisor Handoff Validator Family Backfill Packet

## Summary
- Backfill the tracked base `supervisor handoff` validator family that `planningops/scripts/README.md` already documents.
- Promote the missing operator report schema, inbox payload schema, handoff validation schema, machine validator, and regression into git-tracked reality so planningops can validate emitted operator handoff sidecars from remote `main`.
- Keep this unit limited to the base validator surface; bundle/readiness resolver families stay for follow-up units.

## Scope
- `planningops/schemas/supervisor-operator-report.schema.json`
- `planningops/schemas/supervisor-inbox-payload.schema.json`
- `planningops/schemas/supervisor-operator-handoff-validation.schema.json`
- `planningops/scripts/validate_supervisor_operator_handoff.py`
- `planningops/scripts/test_validate_supervisor_operator_handoff_contract.sh`
- workbench hub link for this validator-family backfill

## Acceptance
- `test_validate_supervisor_operator_handoff_contract.sh` passes
- `validate_supervisor_operator_handoff.py` emits a pass report for aligned handoff fixtures and fails closed for mismatched handoff fixtures
