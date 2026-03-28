---
title: plan: Scheduled Reflection Goal Context Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens the scheduled reflection delivery cycle so goal context is resolved before queue admission and terminal goal-completed actions route through the dedicated handoff bridge.
related_docs:
  - ./2026-03-28-worker-outcome-reflection-goal-context-packet.md
---

# plan: Scheduled Reflection Goal Context Packet

## Summary
- Move the scheduled reflection delivery runner onto shared reflection plumbing.
- Resolve goal context before queue admission and enforce queue-seed/goal consistency.
- Route terminal `goal_completed` actions through the dedicated goal-completion handoff bridge.

## Scope
- `planningops/scripts/federation/run_scheduled_reflection_delivery_cycle.py`
- `planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`
- `planningops/scripts/test_scheduled_reflection_delivery_cycle_contract.sh`
- workbench hub link for this scheduled-cycle hardening packet

## Acceptance
- `test_scheduled_reflection_delivery_cycle.sh` passes
- `test_scheduled_reflection_delivery_cycle_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
