---
title: plan: Reflection Action No Active Goal Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens reflection action handoff so action application fails closed when no active goal context is available, matching the evaluator's behavior.
related_docs:
  - ./2026-03-28-worker-outcome-reflection-goal-context-packet.md
---

# plan: Reflection Action No Active Goal Packet

## Summary
- Align reflection action application with evaluator-side no-active-goal failure behavior.
- Simplify the applier's post-processing error handling so existing validation errors stay authoritative.
- Update the handoff contract and regression coverage for missing active-goal context.

## Scope
- `planningops/scripts/core/goals/apply_worker_outcome_reflection.py`
- `planningops/scripts/test_apply_worker_outcome_reflection.sh`
- `planningops/contracts/reflection-action-handoff-contract.md`
- workbench hub link for this no-active-goal hardening packet

## Acceptance
- `test_apply_worker_outcome_reflection.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
