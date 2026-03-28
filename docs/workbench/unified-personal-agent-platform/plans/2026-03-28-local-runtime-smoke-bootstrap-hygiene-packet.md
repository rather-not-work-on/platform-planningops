---
title: plan: Local Runtime Smoke Bootstrap Hygiene Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens federated Python bootstrap and local runtime smoke orchestration so launcher startup, retry evidence, and stale run-root cleanup stay deterministic.
related_docs:
  - ./2026-03-28-wave14-rehearsal-default-task-packet.md
---

# plan: Local Runtime Smoke Bootstrap Hygiene Packet

## Summary
- Prune AppleDouble files and reject unhealthy managed Python interpreters in federated bootstrap.
- Rebuild conformance run roots before reuse and add launcher/retry evidence to local runtime smoke reports.
- Keep the unit limited to bootstrap/conformance/smoke plumbing plus their regressions.

## Scope
- `planningops/scripts/federation/federated_python_env.py`
- `planningops/scripts/federation/cross_repo_conformance_check.py`
- `planningops/scripts/federation/run_local_runtime_stack_smoke.py`
- `planningops/scripts/test_local_runtime_stack_smoke_contract.sh`
- workbench hub link for this bootstrap-hygiene packet

## Acceptance
- `test_federated_python_env_contract.sh` passes
- `test_cross_repo_conformance_run_root_reuse_contract.sh` passes
- `test_local_runtime_stack_smoke_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
