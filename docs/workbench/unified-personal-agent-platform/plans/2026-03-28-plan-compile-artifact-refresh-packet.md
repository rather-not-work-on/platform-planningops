---
title: plan: Plan Compile Artifact Refresh Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the committed plan-compile validation artifact so canonical sample backlog compilation evidence matches the current compiler output.
related_docs:
  - ./2026-03-28-plan-projection-artifact-refresh-packet.md
---

# plan: Plan Compile Artifact Refresh Packet

## Summary
- Re-run the sample backlog compiler against the committed sample execution contract.
- Refresh the committed compile validation report without changing compiler behavior.
- Keep the unit artifact-only: no helper, workflow, or contract logic changes.

## Scope
- `planningops/artifacts/validation/plan-compile-report.json`
- workbench hub link for this packet

## Acceptance
- `test_compile_plan_to_backlog_contract.sh` passes
- `python3 planningops/scripts/compile_plan_to_backlog.py --contract-file planningops/fixtures/plan-execution-contract-sample.json --output planningops/artifacts/validation/plan-compile-report.json` succeeds
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
