---
title: plan: MONDAY Agent Memory Wave W Runtime-Handoff Supervisor Handoff Contract Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the supervisor operator handoff contract regressions into the canonical runtime-handoff helper so the federated runtime lane owns the core handoff artifact and validation boundary used by the monday memory reflection bridges.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-v-runtime-handoff-goal-policy-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-m-runtime-handoff-supervisor-contract-packet.md
  - ./2026-03-26-monday-agent-memory-wave-u-runtime-handoff-local-delivery-contract-lane-packet.md
---

# plan: MONDAY Agent Memory Wave W Runtime-Handoff Supervisor Handoff Contract Lane Packet

## Purpose

Close the remaining core supervisor-handoff gap under the monday memory reflection path. The canonical helper already owns reflection execution, delivery contracts, and goal policy, but the direct supervisor handoff artifact and validator regressions still sit outside that same lane. Wave W promotes those handoff-policy checks into `runtime-handoff`.

## Scope

Wave W should add:

- `test_supervisor_operator_handoff_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_validate_supervisor_operator_handoff_contract.sh` to the same helper-owned runtime lane
- helper contract, wiring, README, and workbench updates freezing that expanded supervisor-handoff inventory

Wave W should not add:

- new supervisor artifact fields
- new monday delivery behavior
- new bridge semantics
- another top-level CI helper

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes `test_supervisor_operator_handoff_contract.sh` and `test_validate_supervisor_operator_handoff_contract.sh`
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays reflection execution, delivery contracts, goal policy, and downstream local delivery contracts
- the direct supervisor operator handoff contract tests still sit outside the canonical helper inventory

Implement Wave W only:
1. add test_supervisor_operator_handoff_contract.sh and test_validate_supervisor_operator_handoff_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require the supervisor handoff steps
3. update README/workbench docs so runtime-handoff explicitly owns the supervisor handoff artifact and validation boundary
4. verify the helper lane and the full federated matrix remain green
```
