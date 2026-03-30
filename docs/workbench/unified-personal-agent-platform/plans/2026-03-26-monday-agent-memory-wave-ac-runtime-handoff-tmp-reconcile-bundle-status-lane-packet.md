---
title: plan: MONDAY Agent Memory Wave AC Runtime-Handoff Tmp-Reconcile Bundle-Status Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the first tmp-summary reconcile bundle-status resolved bundle layer into the runtime-handoff helper so the monday memory reflection lane owns the root status sidecar validator plus the first resolved bundle validator, doctor, and gate surfaces.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-ab-runtime-handoff-tmp-reconcile-root-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-aa-runtime-handoff-federated-summary-contract-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-z-runtime-handoff-federated-summary-readiness-lane-packet.md
---

# plan: MONDAY Agent Memory Wave AC Runtime-Handoff Tmp-Reconcile Bundle-Status Lane Packet

## Purpose

Close the first tmp-summary reconcile bundle-status gap under the monday memory reflection path. The canonical helper already owns the root tmp-summary reconcile repair, validator, and resolver, but the first status sidecar validator and the first resolved status-bundle validator/doctor/gate layer still sit outside the helper inventory.

## Scope

Wave AC should add:

- `test_validate_federated_ci_summary_tmp_reconcile_bundle.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- `test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh` to the canonical `run_runtime_handoff_ci_check.sh` inventory
- helper contract, wiring, README, and workbench updates freezing that first bundle-status layer

Wave AC should not add:

- `status-bundle-status` outer bundle layers
- outer doctor-owned sidecar ladders
- new monday runtime behavior
- a separate tmp-reconcile bundle-status helper lane

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the first tmp-summary reconcile bundle-status layer
- local/workflow runtime-handoff entrypoints still call only the canonical helper surface
- runtime-handoff helper, docs, and federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already owns the root tmp-summary reconcile repair, validator, and resolver
- the next coherent dependency ring is the first bundle-status layer: bundle validation, status validation, status-bundle resolution, status-bundle validation, doctor, and gate

Implement Wave AC only:
1. add test_validate_federated_ci_summary_tmp_reconcile_bundle.sh, test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh, test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh, test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh, test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh, and test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh to run_runtime_handoff_ci_check.sh
2. update helper contract and wiring regressions to require that first bundle-status layer
3. update README/workbench docs so runtime-handoff explicitly owns that first resolved bundle-status surface
4. verify the helper lane and the full federated matrix remain green
```
