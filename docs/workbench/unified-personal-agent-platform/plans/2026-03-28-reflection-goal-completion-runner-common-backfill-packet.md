---
title: plan: Reflection Goal-Completion Runner Common Backfill Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the shared reflection-cycle plumbing and goal-completion handoff runner surfaces so planningops can emit canonical reflection-driven supervisor handoffs from direct actions or monday scheduler reports.
related_docs:
  - ./2026-03-28-supervisor-handoff-common-backfill-packet.md
  - ./2026-03-28-supervisor-handoff-goal-completion-bridge-test-family-backfill-packet.md
---

# plan: Reflection Goal-Completion Runner Common Backfill Packet

## Summary
- Backfill the tracked `reflection goal-completion handoff` runner family that sits between worker-outcome reflection and monday goal-completion delivery admission.
- Promote the missing shared reflection-cycle common module, federation runner, thin wrapper, and scheduler-report regression into git-tracked reality so fresh clones preserve canonical reflection-driven handoff behavior.
- Keep this unit limited to the runner/common family; scheduled reflection delivery regression expansion remains a separate follow-up wave.

## Scope
- `planningops/scripts/federation/reflection_cycle_common.py`
- `planningops/scripts/federation/run_reflection_goal_completion_handoff_cycle.py`
- `planningops/scripts/run_reflection_goal_completion_handoff_cycle.py`
- `planningops/scripts/test_worker_outcome_reflection_cycle_scheduler_report.sh`
- workbench hub link for this runner/common backfill

## Acceptance
- `test_reflection_goal_completion_handoff_cycle.sh` passes
- `test_worker_outcome_reflection_cycle_scheduler_report.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
