---
status: complete
priority: p2
issue_id: "032"
tags: [planningops, supervisor, experiment, worktree]
dependencies: ["030", "027", "029"]
---

# Supervisor Experiment Auto Executor

## Problem Statement
Supervisor currently emits experiment trigger artifacts, but does not yet execute comparative worktree branches automatically from that trigger.

## Findings
- Trigger detection is integrated, yet follow-through still depends on manual operator action.
- Converting trigger -> controlled experiment execution would reduce orchestration gaps.

## Proposed Solution
Implement an experiment auto-executor path that creates option worktrees, runs a fixed validation pack, and writes rubric-based decision artifacts.

## Acceptance Criteria
- [x] Supervisor trigger can invoke worktree option scaffolding with deterministic naming.
- [x] Validation pack runs for each option and captures per-option report JSON.
- [x] Decision record includes selected/rejected options with weighted rubric scores.
- [x] Failure mode and cleanup behavior are documented and contract-tested.

## Work Log

### 2026-03-05 - Auto Executor Complete

**By:** Codex

**Actions:**
- Added automatic comparative executor:
  - `planningops/scripts/supervisor_experiment_auto_executor.py`
- Integrated supervisor trigger -> executor wiring:
  - `planningops/scripts/autonomous_supervisor_loop.py` (`--experiment-auto-execute`)
- Added validation pack config:
  - `planningops/config/supervisor-experiment-validation-pack.json`
- Added dedicated contract and regression test:
  - `planningops/contracts/supervisor-experiment-auto-executor-contract.md`
  - `planningops/scripts/test_supervisor_experiment_auto_executor_contract.sh`
- Ran deterministic pilot execution with auto executor enabled:
  - run id: `pilot-20260305-experiment-autoexec`
  - selected option: `option-a`

**Validation:**
- `python3 -m py_compile planningops/scripts/autonomous_supervisor_loop.py planningops/scripts/supervisor_experiment_auto_executor.py`
- `bash planningops/scripts/test_supervisor_experiment_auto_executor_contract.sh`
- `python3 planningops/scripts/autonomous_supervisor_loop.py --mode dry-run --max-cycles 1 --continue-on-experiment --report-only-gates --items-file planningops/fixtures/backlog-stock-items-sample.json --offline --loop-result-sequence-file planningops/fixtures/supervisor-loop-sequence-sample.json --run-id pilot-20260305-experiment-autoexec --artifacts-root planningops/artifacts/pilot --output planningops/artifacts/pilot/pilot-20260305-experiment-autoexec-summary.json --experiment-auto-execute --experiment-validation-pack-file planningops/config/supervisor-experiment-validation-pack.json --experiment-artifacts-root planningops/artifacts/experiments --experiment-worktree-root /tmp/planningops-supervisor-experiments`
