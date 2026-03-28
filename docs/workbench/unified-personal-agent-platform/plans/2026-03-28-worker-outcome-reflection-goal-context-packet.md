---
title: plan: Worker Outcome Reflection Goal Context Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens worker outcome reflection orchestration so goal context is resolved up front and reflected consistently across direct outcome and scheduler-report entry paths.
related_docs:
  - ./2026-03-28-review-interface-adoption-command-checks-packet.md
---

# plan: Worker Outcome Reflection Goal Context Packet

## Summary
- Move worker outcome reflection orchestration onto shared reflection plumbing.
- Resolve goal context before export/evaluation so inferred-goal and no-active-goal cases are deterministic.
- Extend the cycle contract and regression coverage for scheduler-report and goal-completion bridge aware flow.

## Scope
- `planningops/scripts/federation/run_worker_outcome_reflection_cycle.py`
- `planningops/scripts/test_worker_outcome_reflection_cycle.sh`
- `planningops/contracts/reflection-cycle-orchestration-contract.md`
- `planningops/contracts/worker-outcome-reflection-contract.md`
- workbench hub link for this orchestration hardening packet

## Acceptance
- `test_worker_outcome_reflection_cycle.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
