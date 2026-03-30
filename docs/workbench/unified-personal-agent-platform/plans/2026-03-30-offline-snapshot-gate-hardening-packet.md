---
title: plan: Offline Snapshot Gate Hardening Packet
type: plan
date: 2026-03-30
updated: 2026-03-30
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens offline supervisor and loop-runner snapshot fallback behavior so missing live project items degrade with explicit fallback causes, seeded snapshot input, and backlog-stock normalization.
related_docs:
  - ./2026-03-28-loop-runner-snapshot-intake-normalization-packet.md
  - ./2026-03-28-backlog-stock-snapshot-normalization-packet.md
---

# plan: Offline Snapshot Gate Hardening Packet

## Summary
- Classify project-item fallback causes as `rate_limit`, `network`, `auth`, `owner_resolution`, or `other` so loop-runner and supervisor guidance stop flattening every snapshot fallback into one ambiguous message.
- Seed the offline issue-runner project-items snapshot from `--items-file` or the canonical `program-manifest.json` surface before the supervisor forces snapshot-backed dry-runs.
- Normalize backlog stock intake for offline snapshots that carry `U<n>` issue refs or omit explicit project status while still reporting `issue_state`.

## Scope
- `planningops/scripts/core/loop/runner.py`
- `planningops/scripts/autonomous_supervisor_loop.py`
- `planningops/scripts/backlog_stock_replenishment_guard.py`
- `planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
- contract/readme/workbench traceability for the offline snapshot gate surface

## Acceptance
- `test_issue_loop_runner_multi_repo_intake.sh` passes
- `test_backlog_stock_replenishment_contract.sh` passes
- `test_autonomous_supervisor_loop_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
