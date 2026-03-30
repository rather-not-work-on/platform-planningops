---
title: plan: MONDAY Agent Memory Wave Z Runtime-Handoff Federated Summary Readiness Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the canonical federated-summary readiness assessor, validator, doctor, and gate regressions into the runtime-handoff helper so the monday memory reflection lane owns the same federated-CI readiness surface already referenced by the operator automation summary.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-y-runtime-handoff-ops-summary-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-x-runtime-handoff-bundle-readiness-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-w-runtime-handoff-supervisor-handoff-contract-lane-packet.md
---

# plan: MONDAY Agent Memory Wave Z Runtime-Handoff Federated Summary Readiness Lane Packet

## Purpose

Close the remaining federated-summary readiness gap under the monday memory reflection path. The canonical helper already owns the supervisor handoff path, bundle readiness, memory reflection bridges, goal policy, and the operator-facing automation summary contract, but the federated-summary readiness assessor, validator, doctor, and gate still sit outside the same helper-owned lane even though that summary contract depends on them directly.

## Scope

Wave Z should add:

- `test_assess_federated_ci_summary_readiness.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_validate_federated_ci_summary_readiness_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_doctor_federated_ci_summary.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_gate_federated_ci_summary.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- helper contract, wiring, README, and workbench updates freezing that expanded federated-summary readiness inventory

Wave Z should not add:

- new federated summary artifact fields
- new monday runtime behavior
- a separate readiness-only helper lane
- changes to the local/workflow runtime-handoff invocation shape

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the federated-summary readiness assessor, validator, doctor, and gate regressions
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already replays the supervisor handoff, bundle-readiness, reflection, delivery, goal-policy, supervisor-handoff contract, and ops-summary checks
- the automation operations summary contract already depends on the canonical federated-summary readiness assessor, validator, doctor, and gate
- those federated-summary readiness regressions still sit outside the canonical helper inventory

Implement Wave Z only:
1. add test_assess_federated_ci_summary_readiness.sh, test_validate_federated_ci_summary_readiness_contract.sh, test_doctor_federated_ci_summary.sh, and test_gate_federated_ci_summary.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require those readiness steps
3. update README/workbench docs so runtime-handoff explicitly owns the federated-summary readiness surface that the ops summary already references
4. verify the helper lane and the full federated matrix remain green
```
