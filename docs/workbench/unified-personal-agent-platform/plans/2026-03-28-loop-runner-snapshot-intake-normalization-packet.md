---
title: plan: Loop Runner Snapshot Intake Normalization Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens loop-runner intake so workflow-state variants, issue snapshots, and manifest fallback snapshots normalize into one deterministic selector surface.
related_docs:
  - ./2026-03-28-planning-context-dependency-key-pattern-packet.md
---

# plan: Loop Runner Snapshot Intake Normalization Packet

## Summary
- Normalize workflow-state tokens before candidate selection.
- Synthesize selector-ready project items from issue snapshots and manifest-style snapshots.
- Keep the unit limited to loop-runner intake normalization, regression coverage, and workbench traceability.

## Scope
- `planningops/scripts/core/loop/runner.py`
- `planningops/scripts/core/loop/selection.py`
- `planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
- workbench hub link for this loop-intake packet

## Acceptance
- `test_issue_loop_runner_multi_repo_intake.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
