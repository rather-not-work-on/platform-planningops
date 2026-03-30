---
title: plan: MONDAY Agent Memory Wave AA Runtime-Handoff Federated Summary Contract Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the canonical federated-summary artifact builder and validator regressions into the runtime-handoff helper so the monday memory reflection lane owns the base summary contract underneath the already-promoted readiness, doctor, and gate surfaces.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-z-runtime-handoff-federated-summary-readiness-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-y-runtime-handoff-ops-summary-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-x-runtime-handoff-bundle-readiness-lane-packet.md
---

# plan: MONDAY Agent Memory Wave AA Runtime-Handoff Federated Summary Contract Lane Packet

## Purpose

Close the root federated-summary contract gap under the monday memory reflection path. The canonical helper already owns the federated-summary readiness assessor, validator, doctor, and gate, but those surfaces still sit on top of the base summary artifact builder and validator tests outside the same helper-owned lane.

## Scope

Wave AA should add:

- `test_federated_ci_summary_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_validate_federated_ci_summary_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- helper contract, wiring, README, and workbench updates freezing that expanded federated-summary contract inventory

Wave AA should not add:

- new federated summary schema fields
- tmp-reconcile bundle ladder regressions
- new monday runtime behavior
- a separate summary-only helper lane

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the federated-summary artifact contract and summary-validation contract regressions
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already owns the federated-summary readiness assessor, validator, doctor, and gate
- those surfaces still depend on the base federated-summary artifact builder and summary validator tests outside the helper inventory

Implement Wave AA only:
1. add test_federated_ci_summary_contract.sh and test_validate_federated_ci_summary_contract.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require those summary-contract steps
3. update README/workbench docs so runtime-handoff explicitly owns the base federated-summary contract under the already-promoted readiness ring
4. verify the helper lane and the full federated matrix remain green
```
