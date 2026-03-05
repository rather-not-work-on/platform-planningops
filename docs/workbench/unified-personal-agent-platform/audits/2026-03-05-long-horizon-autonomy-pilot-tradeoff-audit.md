---
title: Long-Horizon Autonomy Pilot Trade-Off Audit
type: audit
date: 2026-03-05
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Reports pilot evidence for the autonomous supervisor loop, compares policy alternatives, and records next backlog items.
---

# Long-Horizon Autonomy Pilot Trade-Off Audit

## Scope
Validate post-`029` supervisor loop behavior and capture decision-quality trade-offs before expanding autonomy scope.

## Pilot Run
### Command
`python3 planningops/scripts/autonomous_supervisor_loop.py --mode dry-run --max-cycles 3 --convergence-pass-streak 2 --continue-on-experiment --loop-result-sequence-file planningops/fixtures/supervisor-loop-sequence-sample.json --items-file planningops/fixtures/backlog-stock-items-sample.json --offline --run-id pilot-20260305-supervisor-sequence --artifacts-root planningops/artifacts/pilot --output planningops/artifacts/pilot/pilot-20260305-supervisor-sequence-summary.json`

### Result
- `supervisor_verdict=pass`
- `stop_reason=converged`
- executed cycles: `2`

### Multi-Step Resolution Evidence
1. Cycle 1
- high-uncertainty + simulation-required path detected
- experiment trigger artifact emitted
- replenishment candidate pack validated
2. Cycle 2
- implementation-profile pass path (`L3`)
- replenishment candidate count dropped to `0`
- convergence condition satisfied

Evidence:
- `planningops/artifacts/pilot/pilot-20260305-supervisor-sequence-summary.json`
- `planningops/artifacts/pilot/pilot-20260305-supervisor-sequence/summary.json`
- `planningops/artifacts/pilot/pilot-20260305-supervisor-sequence/cycle-01/cycle-report.json`
- `planningops/artifacts/pilot/pilot-20260305-supervisor-sequence/cycle-02/cycle-report.json`

## Comparative Experiment Evidence
Experiment protocol evidence reused from completed `027`:
- `planningops/artifacts/experiments/2026-03-05-lock-drift-classification/manifest.json`
- `planningops/artifacts/experiments/2026-03-05-lock-drift-classification/decision-record.md`

This satisfies the pilot requirement that at least one branch/worktree comparison case is present in the autonomy decision chain.

## Trade-Off Analysis
### Option A: Stop on Experiment Trigger (Default)
Pros
- strongest safety posture
- deterministic operator checkpoint

Cons
- lower unattended throughput
- more manual restarts

### Option B: Continue with Strict Gates (`--continue-on-experiment`)
Pros
- better uninterrupted progress
- useful for controlled pilot convergence testing

Cons
- higher policy complexity
- requires strict backlog/quality gates to avoid silent drift

### Decision
- Keep Option A as production default.
- Use Option B only for explicit pilot/rehearsal runs with strict gate evidence.

Rejected alternatives:
- Throughput-first continuous run without experiment stop: rejected due quality/risk exposure.

## Backlog Generated from Pilot
- `todos/031-ready-p1-supervisor-live-runner-dryrun-pilot.md` (dependency: `030,029,028`)
- `todos/032-ready-p2-supervisor-experiment-auto-executor.md` (dependency: `030,027,029`)
