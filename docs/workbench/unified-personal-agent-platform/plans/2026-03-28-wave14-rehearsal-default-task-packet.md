---
title: plan: Wave14 Rehearsal Default Task Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens the Wave14 oracle rehearsal so deterministic deepagents-style tasks are always injected into local and oracle portability checks.
related_docs:
  - ./2026-03-28-loop-runner-snapshot-intake-normalization-packet.md
---

# plan: Wave14 Rehearsal Default Task Packet

## Summary
- Add a deterministic default simulated deepagents task for oracle rehearsal runs.
- Thread the task list through both local and oracle stack-smoke invocations.
- Lock the new default-task surface with the existing rehearsal contract regression.

## Scope
- `planningops/scripts/federation/run_wave14_oracle_rehearsal.py`
- `planningops/scripts/test_wave14_oracle_rehearsal_contract.sh`
- workbench hub link for this oracle rehearsal packet

## Acceptance
- `test_wave14_oracle_rehearsal_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
