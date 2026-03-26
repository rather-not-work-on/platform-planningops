---
title: plan: MONDAY Agent Memory Wave AM Runtime-Handoff Tmp-Reconcile Resolved-Bundle Completion Lane Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Finishes runtime-handoff ownership of the newly promoted tmp-summary reconcile outer ring by adding the matching resolver and resolved-bundle validation contract to the helper inventory.
related_docs:
  - ./2026-03-26-monday-agent-memory-wave-al-runtime-handoff-tmp-reconcile-next-status-promotion-lane-packet.md
  - ./2026-03-26-monday-agent-memory-wave-ak-runtime-handoff-tmp-reconcile-next-status-prerequisite-packet.md
---

# plan: MONDAY Agent Memory Wave AM Runtime-Handoff Tmp-Reconcile Resolved-Bundle Completion Lane Packet

## Purpose

Complete runtime-handoff ownership of the outer tmp-summary reconcile ring that AL promoted. AL sealed the doctor/gate and next-status contracts; AM adds the matching resolver and resolved bundle-validation contract so the full ring is owned inside one helper lane.

## Scope

Wave AM should add:

- the outer-ring resolver regression to `run_runtime_handoff_ci_check.sh`
- the outer-ring resolved bundle-validation regression to `run_runtime_handoff_ci_check.sh`
- matching helper contract and wiring updates
- README and workbench updates describing that the full resolved-bundle surface is now owned

Wave AM should not add:

- a deeper next-status prerequisite ring
- new monday runtime behavior
- a separate helper lane

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_runtime_handoff_ci_check.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/federation/README.md`

## Acceptance Gates

- `run_runtime_handoff_ci_check.sh --print-steps` includes the outer-ring resolver plus resolved bundle-validation contract
- helper contract and wiring regressions pin the same added steps
- helper lane and local federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday memory-aware agent harness and planningops control-plane rollout.

Current state:
- runtime-handoff already owns the outer tmp-summary reconcile doctor/gate plus next-status contract ring
- the same ring's resolver and resolved bundle-validation contract still sit outside the canonical helper inventory

Implement Wave AM only:
1. add the matching outer-ring resolver and resolved bundle-validation contract regressions to run_runtime_handoff_ci_check.sh
2. update test_run_runtime_handoff_ci_check_contract.sh and test_supervisor_handoff_bridge_wiring.sh to require those same helper steps
3. update README/workbench docs so runtime-handoff explicitly owns the full resolved-bundle surface for that ring
4. verify the helper lane and local federated matrix remain green
```
