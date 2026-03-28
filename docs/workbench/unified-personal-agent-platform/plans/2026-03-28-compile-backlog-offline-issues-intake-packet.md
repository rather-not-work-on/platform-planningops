---
title: plan: Compile Backlog Offline Issues Intake Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens compile/materialize and manifest generation so offline issues snapshots and richer plan metadata propagate through the backlog pipeline deterministically.
related_docs:
  - ./2026-03-28-loop-runner-snapshot-intake-normalization-packet.md
---

# plan: Compile Backlog Offline Issues Intake Packet

## Summary
- Allow `compile_plan_to_backlog.py` to consume offline issues JSON payloads.
- Pass projected issues through backlog materialization and preserve richer contract/topology metadata in the program manifest.
- Keep the unit limited to compile/materialize/manifest pipeline hardening plus regression coverage.

## Scope
- `planningops/scripts/build_program_manifest.py`
- `planningops/scripts/compile_plan_to_backlog.py`
- `planningops/scripts/core/backlog/materialize.py`
- `planningops/scripts/test_compile_plan_to_backlog_contract.sh`
- workbench hub link for this offline-intake packet

## Acceptance
- `test_compile_plan_to_backlog_contract.sh` passes
- `test_build_program_manifest_contract.sh` passes
- `test_backlog_materialization_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
