---
title: plan: Reflection Contract Guardrails Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills contract regressions so reflection evaluator and action handoff contracts assert the new goal-context failure rules and monday queue-admission boundary.
related_docs:
  - ./2026-03-28-reflection-action-no-active-goal-packet.md
---

# plan: Reflection Contract Guardrails Packet

## Summary
- Align reflection contract regressions with the already-promoted goal-context and queue-admission contract language.
- Keep this unit test-only: no runtime logic changes, only guardrails.
- Preserve workbench traceability for the contract test backfill.

## Scope
- `planningops/scripts/test_worker_outcome_reflection_contract.sh`
- `planningops/scripts/test_reflection_action_handoff_contract.sh`
- workbench hub link for this guardrail packet

## Acceptance
- `test_worker_outcome_reflection_contract.sh` passes
- `test_reflection_action_handoff_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
