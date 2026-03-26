---
title: plan: Control-Plane Governance Helper Smoke Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds a deterministic smoke regression for the control-plane-governance helper so helper validation no longer depends on the live repo root state.
related_docs:
  - ./2026-03-26-control-plane-governance-helper-family-backfill-packet.md
  - ./2026-03-26-runtime-profiles-validator-family-backfill-packet.md
---

# plan: Control-Plane Governance Helper Smoke Packet

## Summary
- Add the tracked smoke regression that exercises `run_control_plane_governance_ci_check.sh` against deterministic fixture inputs.
- Seal the helper with a clean-root memory gate and inventory audit path so helper validation does not depend on the current repo root's compaction state.
- Publish the smoke hardening step in the workbench hub alongside the base helper-family packet.

## Scope
- `planningops/scripts/test_run_control_plane_governance_ci_check_smoke.sh`
- workbench hub link for this smoke packet

## Acceptance
- `test_run_control_plane_governance_ci_check_smoke.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
