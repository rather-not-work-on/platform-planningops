---
title: plan: Contract Helper Surface Sync Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Syncs small contract/readme surfaces so helper entrypoints and the active-goal terminal-state rule are explicitly documented.
related_docs:
  - ./2026-03-28-active-goal-registry-empty-state-packet.md
---

# plan: Contract Helper Surface Sync Packet

## Summary
- Add helper-lane references to artifact-retention and memory-tier contracts.
- Document the no-active-goal terminal state in the goals README.
- Keep the unit documentation-only with no runtime behavior changes.

## Scope
- `planningops/contracts/artifact-retention-tier-contract.md`
- `planningops/contracts/memory-tier-contract.md`
- `planningops/scripts/core/goals/README.md`
- workbench hub link for this helper-surface packet

## Acceptance
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
