---
title: plan: Backlog Stock Snapshot Normalization Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens backlog stock replenishment guard intake so projected issue snapshots and workflow-state variants normalize into the same replenishment policy surface.
related_docs:
  - ./2026-03-28-loop-runner-snapshot-intake-normalization-packet.md
---

# plan: Backlog Stock Snapshot Normalization Packet

## Summary
- Allow backlog stock replenishment to read list, `items`, `issues`, or `project_items` payloads.
- Normalize workflow-state variants and projected issue snapshot rows before policy matching.
- Expand the planningops backlog stock policy to count ready implementation and review-gate work.

## Scope
- `planningops/scripts/backlog_stock_replenishment_guard.py`
- `planningops/config/backlog-stock-policy.json`
- workbench hub link for this replenishment packet

## Acceptance
- `test_backlog_stock_replenishment_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
