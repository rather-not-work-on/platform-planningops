---
title: Supervisor Experiment Auto Executor Audit
type: audit
date: 2026-03-05
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Validates automatic trigger-to-worktree comparative execution path and records selected option evidence.
---

# Supervisor Experiment Auto Executor Audit

## Scope
Validate `032` implementation where supervisor trigger directly invokes comparative worktree execution.

## Command
`python3 planningops/scripts/autonomous_supervisor_loop.py --mode dry-run --max-cycles 1 --continue-on-experiment --report-only-gates --items-file planningops/fixtures/backlog-stock-items-sample.json --offline --loop-result-sequence-file planningops/fixtures/supervisor-loop-sequence-sample.json --run-id pilot-20260305-experiment-autoexec --artifacts-root planningops/artifacts/pilot --output planningops/artifacts/pilot/pilot-20260305-experiment-autoexec-summary.json --experiment-auto-execute --experiment-validation-pack-file planningops/config/supervisor-experiment-validation-pack.json --experiment-artifacts-root planningops/artifacts/experiments --experiment-worktree-root /tmp/planningops-supervisor-experiments`

## Result
- supervisor verdict: `pass`
- cycle count: `1`
- experiment trigger: `true`
- auto executor verdict: `pass`
- selected option: `option-a`

## Auto Executor Evidence
- `planningops/artifacts/experiments/pilot-20260305-experiment-autoexec-cycle-01-issue-201/manifest.json`
- `planningops/artifacts/experiments/pilot-20260305-experiment-autoexec-cycle-01-issue-201/option-option-a-report.json`
- `planningops/artifacts/experiments/pilot-20260305-experiment-autoexec-cycle-01-issue-201/option-option-b-report.json`
- `planningops/artifacts/experiments/pilot-20260305-experiment-autoexec-cycle-01-issue-201/decision-record.md`
- `planningops/artifacts/experiments/pilot-20260305-experiment-autoexec-cycle-01-issue-201/supervisor-auto-executor-report.json`

## Contract Coverage
- `planningops/contracts/worktree-comparative-experiment-protocol.md`
- `planningops/contracts/autonomous-supervisor-loop-contract.md`
- `planningops/contracts/supervisor-experiment-auto-executor-contract.md`
