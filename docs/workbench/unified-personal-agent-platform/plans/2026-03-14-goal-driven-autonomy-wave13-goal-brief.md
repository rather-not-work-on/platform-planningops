---
title: plan: Goal-Driven Autonomy Wave 13 Goal Brief
type: plan
date: 2026-03-14
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the thirteenth goal-driven autonomy wave so monday can select the current scheduled worker outcome from runtime-owned state and emit the handoff without a planningops bridge input.
tags:
  - uap
  - goal
  - autonomy
  - planningops
  - monday
  - scheduler
  - queue
  - worker-outcome
  - handoff
---

# Goal-Driven Autonomy Wave 13 Goal Brief

## Objective

Remove the remaining bridge input from wave12 by making monday resolve the current scheduled worker outcome on its own:
- `monday scheduled queue cycle -> monday worker-outcome selector -> worker-outcome handoff artifact -> planningops reflection cycle -> delivery cycle`
- planningops no longer forwards an explicit `--worker-outcome-json` bridge input for the primary scheduled loop
- monday remains the owner of queue state, worker-outcome persistence, and worker-outcome selection

## Success Outcomes

- planningops has a repo-owned contract for scheduler-native worker-outcome selection
- monday can resolve one deterministic worker outcome for the active scheduled run from runtime-owned evidence or store state
- planningops scheduled reflection-delivery orchestration can execute the primary path without an operator-supplied worker-outcome bridge input
- review evidence proves the queue/runtime selection logic remains monday-owned and the control-plane remains thin

## Non-Goals

- no daemonized scheduler service
- no distributed queue backend
- no planningops-owned queue mutation or worker-outcome storage
- no new provider or observability transport work

## Completion References

- `planningops/contracts/autonomous-scheduler-queue-control-plane-contract.md`
- `planningops/contracts/scheduled-worker-outcome-handoff-contract.md`
- `planningops/contracts/scheduled-reflection-delivery-cycle-contract.md`
- `planningops/contracts/goal-completion-contract.md`

## Roadmap Reference

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-autonomous-scheduler-queue-control-plane-plan.md`

## Execution Contract

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-14-goal-driven-autonomy-wave13.execution-contract.json`
