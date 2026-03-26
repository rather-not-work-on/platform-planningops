---
title: plan: MONDAY Harness Projection Wave AP Suite Root-Surface Promotion Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes the remaining root monday harness projection regressions into the suite helper so the suite owns the full projection validation and contract surface before sync.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-k-runtime-handoff-ci-packet.md
  - ./2026-03-26-monday-agent-memory-wave-ao-runtime-handoff-tmp-reconcile-root-ladder-completion-lane-packet.md
---

# plan: MONDAY Harness Projection Wave AP Suite Root-Surface Promotion Packet

## Purpose

Close the remaining gap in `run_monday_agent_harness_projection_ci_suite.sh`. Before Wave AP, the suite already owned almost the entire monday harness projection ladder, but the root validate/doctor/gate regressions and the contract-doc regression still sat outside the canonical suite inventory.

## Scope

Wave AP should add:

- `test_validate_monday_agent_harness_projection.sh`
- `test_doctor_monday_agent_harness_projection.sh`
- `test_gate_monday_agent_harness_projection.sh`
- `test_monday_agent_harness_projection_contract_doc.sh`
- matching suite-contract updates
- README/workbench updates describing the suite as the canonical owner of the full projection surface before sync

Wave AP should not add:

- new projection schemas or validators
- wrapper-level direct regressions in `run_monday_agent_harness_projection_ci_check.sh`
- monday runtime changes

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/test_run_monday_agent_harness_projection_ci_suite_contract.sh`
- `/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/scripts/README.md`

## Acceptance Gates

- `run_monday_agent_harness_projection_ci_suite.sh --print-tests` includes the four root-surface regressions
- suite contract pins the same ordered inventory
- helper lane and full local federated matrix remain green after the promotion

## Codex Prompt

```text
Continue the monday harness projection control-plane rollout.

Current state:
- run_monday_agent_harness_projection_ci_suite.sh already owns the projection status/bundle ladder and final latest sync
- four root-surface regressions still sit outside the suite helper: validate root projection, doctor root projection, gate root projection, and projection contract doc

Implement Wave AP only:
1. add those four regressions to run_monday_agent_harness_projection_ci_suite.sh in canonical order before the final sync
2. update test_run_monday_agent_harness_projection_ci_suite_contract.sh to require the same suite inventory
3. update README/workbench docs so the suite is described as owning the full projection surface before sync
4. verify the suite helper, wrapper helper, and full local federated matrix remain green
```
