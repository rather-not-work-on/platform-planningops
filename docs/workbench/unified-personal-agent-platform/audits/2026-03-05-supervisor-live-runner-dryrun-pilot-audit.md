---
title: Supervisor Live Runner Dry-Run Pilot Audit
type: audit
date: 2026-03-05
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures live (non-sequence) supervisor pilot evidence and documents delta/recovery versus sequence-mode baseline.
---

# Supervisor Live Runner Dry-Run Pilot Audit

## Scope
Run `autonomous_supervisor_loop.py` without `--loop-result-sequence-file` to validate real `issue_loop_runner.py` selector/project interaction.

## Pilot Setup
- seed issue: `rather-not-work-on/platform-planningops#84` (temporary pilot issue)
- project item field setup:
  - `Status=Todo`
  - `initiative=unified-personal-agent-platform`
  - `workflow_state=ready-contract`
  - `component=planningops`
  - `target_repo=rather-not-work-on/platform-planningops`
- cleanup: issue closed and project item deleted after run

## Command
`python3 planningops/scripts/autonomous_supervisor_loop.py --mode dry-run --max-cycles 2 --continue-on-experiment --report-only-gates --owner rather-not-work-on --project-num 2 --initiative unified-personal-agent-platform --run-id pilot-20260305-live-runner --artifacts-root planningops/artifacts/pilot --output planningops/artifacts/pilot/pilot-20260305-live-runner-summary.json`

## Result
- `executed_cycles=2` (acceptance satisfied)
- `supervisor_verdict=fail`
- `stop_reason=escalation_auto_pause`

## Evidence
- `planningops/artifacts/pilot/pilot-20260305-live-runner-summary.json`
- `planningops/artifacts/pilot/pilot-20260305-live-runner/summary.json`
- `planningops/artifacts/pilot/pilot-20260305-live-runner/cycle-01/cycle-report.json`
- `planningops/artifacts/pilot/pilot-20260305-live-runner/cycle-02/cycle-report.json`
- `planningops/artifacts/pilot/pilot-20260305-live-runner/cycle-01/backlog-stock-report.json`
- `planningops/artifacts/pilot/pilot-20260305-live-runner/cycle-02/backlog-stock-report.json`

## Delta vs Sequence Pilot
Baseline reference:
- `planningops/artifacts/pilot/pilot-20260305-supervisor-sequence-summary.json`

Observed deltas:
1. Backlog gate
- sequence-mode: pass (`breach_count=0`)
- live-mode: fail (`breach_count=2`, both cycles)
- shortage classes:
  - `next_up`: `min_stock=2`, `actual_stock=0`
  - `quality_hardening`: `min_stock=2`, `actual_stock=1`

2. Escalation behavior
- live run stopped on cycle 2 with `escalation_auto_pause`, while `last_verdict=pass` and `reason_code=ok`
- this indicates current escalation counting may over-trigger on repeated `ok` reason code.

## Deterministic Recovery Plan
1. Queue stock recovery
- add dependency-linked `next_up` candidates to raise stock from `0` to `>=2`
- add quality hardening cards to raise stock from `1` to `>=2`

2. Escalation rule recovery
- constrain `same_reason_x3` auto-pause to non-pass path or non-`ok` reason taxonomy
- add regression coverage for repeated `pass/ok` cycles

## Follow-up Backlog
- `todos/033-ready-p1-escalation-ok-reason-false-positive-autopause.md`
- `todos/034-ready-p2-live-stock-shortage-replenishment-pack.md`
