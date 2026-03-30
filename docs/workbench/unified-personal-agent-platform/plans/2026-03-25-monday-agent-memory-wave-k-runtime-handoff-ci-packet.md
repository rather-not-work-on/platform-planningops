---
title: plan: MONDAY Agent Memory Wave K Runtime-Handoff CI Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the monday memory scheduler reflection chain into the canonical runtime-handoff federated CI helper so the control-plane path is exercised in the same lane as the existing supervisor-to-monday bridges.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-j-scheduled-control-plane-automation-packet.md
  - ./2026-03-25-monday-agent-memory-wave-i-goal-completion-handoff-packet.md
---

# plan: MONDAY Agent Memory Wave K Runtime-Handoff CI Packet

## Purpose

Seal the new monday memory control-plane path inside the canonical federated runtime lane. After Wave J, the scheduled reflection runner can already branch terminal memory completions into the supervisor goal-completion handoff path, but that chain still lives as standalone regressions. Wave K promotes those regressions into `run_runtime_handoff_ci_check.sh`.

## Scope

Wave K should add:

- the monday memory scheduler reflection regressions to `run_runtime_handoff_ci_check.sh`
- contract coverage proving the helper step inventory now includes the memory reflection chain
- wiring coverage proving local/workflow runtime-handoff entrypoints still call only the helper while the helper itself now owns the memory reflection steps
- README/workbench updates freezing that helper-owned surface as canonical

Wave K should not yet add:

- a new federated job just for memory reflection
- automatic batching across multiple monday memory scheduler reports
- any new reflection vocabulary or delivery semantics

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes:
  - `test_worker_outcome_reflection_cycle_scheduler_report.sh`
  - `test_reflection_goal_completion_handoff_cycle.sh`
  - `test_scheduled_reflection_delivery_cycle.sh`
- local/workflow runtime-handoff surfaces still invoke only the helper
- the full runtime-handoff helper passes with the new memory reflection chain included
- docs describe runtime-handoff as the canonical CI home for the memory scheduler reflection path

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- monday memory scheduler evidence already flows through planningops reflection
- terminal memory completions already branch into the goal-completion handoff bridge
- those regressions still run outside the canonical federated runtime-handoff helper

Implement Wave K only:
1. add the memory reflection regressions to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to pin the new step inventory
3. keep local/workflow runtime-handoff entrypoints helper-only
4. update README/workbench docs so runtime-handoff is the canonical CI home for this path
```
