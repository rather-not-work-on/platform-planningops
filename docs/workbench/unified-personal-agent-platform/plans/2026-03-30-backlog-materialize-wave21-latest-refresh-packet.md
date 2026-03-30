---
title: plan: Backlog Materialize Wave21 Latest Refresh Packet
type: plan
date: 2026-03-30
updated: 2026-03-30
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the canonical backlog materialization latest lane from the wave21 execution contract so projected issues, compile evidence, label evidence, issue-quality evidence, and program-manifest evidence share one canonical projected-issues surface.
related_docs:
  - ./2026-03-15-goal-driven-autonomy-wave21-issue-pack.md
  - ./2026-03-28-backlog-materialize-wave22-latest-refresh-packet.md
---

# plan: Backlog Materialize Wave21 Latest Refresh Packet

## Summary
- Replay `planningops/scripts/core/backlog/materialize.py` against the checked-in wave21 execution contract.
- Refresh canonical `projected-issues.json` first, then derive compile, label, issue-quality, and program-manifest outputs from that same canonical projected-issues lane.
- Keep the materialize summary output ephemeral so the committed unit remains limited to canonical latest artifacts plus workbench traceability.

## Scope
- `planningops/artifacts/backlog/projected-issues.json`
- `planningops/artifacts/validation/plan-compile-report.json`
- `planningops/artifacts/validation/issue-label-backfill-report.json`
- `planningops/artifacts/validation/issue-quality-report.json`
- `planningops/artifacts/program/program-manifest.json`
- `planningops/artifacts/validation/program-manifest-report.json`

## Acceptance
- `test_backlog_materialization_contract.sh` passes
- `python3 planningops/scripts/core/backlog/materialize.py --contract-file docs/workbench/unified-personal-agent-platform/plans/2026-03-15-goal-driven-autonomy-wave21.execution-contract.json ...` succeeds with canonical projected-issues, compile, label, quality, and manifest outputs
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
