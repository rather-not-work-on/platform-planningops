---
title: refactor: Worker Reliability Hardening and Convergence Control
type: plan
date: 2026-03-05
updated: 2026-03-05
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens worker execution reliability by enforcing attempt budgets, runtime retry/timeout policy, heartbeat safety, and stronger verification evidence gates.
source_brainstorm: docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-02-uap-post-waveb-next-phase-brainstorm.md
---

# refactor: Worker Reliability Hardening and Convergence Control

## Overview
Improve worker reliability so the loop converges predictably instead of depending on best-effort single-shot execution.

This plan focuses on deterministic failure handling and bounded retries for `issue_loop_runner -> ralph_loop_local -> worker command`.

Found brainstorm from `2026-03-02`: `uap-post-waveb-next-phase`. Using as context for planning.

Supporting brainstorm (same topic family): `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-01-uap-loop-selection-policy-brainstorm.md`.

## Research Consolidation
### Repository Research Summary
- Current runtime stack already has:
  - deterministic intake/selection
  - loop profile selection (`L1~L5`)
  - checkpoint/resume
  - lease lock + watchdog
  - escalation auto-pause
- Relevant code/contract anchors:
  - `planningops/scripts/issue_loop_runner.py`
  - `planningops/scripts/ralph_loop_local.py`
  - `planningops/scripts/validate_worker_task_pack.py`
  - `planningops/contracts/requirements-contract.md`
  - `planningops/contracts/worker-task-pack-contract.md`
  - `planningops/contracts/failure-taxonomy-and-retry-policy.md`

### Institutional Learnings Search
- `docs/solutions/` is not present in this repository.
- This plan uses workbench brainstorm/plan/audit artifacts and contracts as institutional context.

### External Research Decision
- Skip external research for this plan.
- Reason: this is internal contract-to-runtime consistency hardening, not adoption of a new external framework/API.

## Problem Statement
The worker path is deterministic at selection/preflight level, but runtime reliability controls are incomplete.

### Evidence-backed Gaps
1. Attempt budget is parsed but not enforced during execution.
- parsing: `planningops/scripts/issue_loop_runner.py:401`
- selected payload recording only: `planningops/scripts/issue_loop_runner.py:804`, `planningops/scripts/issue_loop_runner.py:1533`
- contract expectation: `planningops/contracts/attempt-budget-contract.md:4`

2. Worker command execution is single-shot without timeout/retry loop.
- command run helper has no timeout argument: `planningops/scripts/ralph_loop_local.py:26`
- execution is one `run_cmd(...)` call: `planningops/scripts/ralph_loop_local.py:299`
- retry policy exists in contract but not enforced by executor loop: `planningops/contracts/failure-taxonomy-and-retry-policy.md:30`

3. Provider timeout/retry values are carried in runtime/task-pack but not used to control actual subprocess execution.
- provider policy source: `planningops/config/runtime-profiles.json:22`
- task-pack contains `retry_policy` and `timeout_ms`: `planningops/scripts/validate_worker_task_pack.py:143`

4. Verification gate for worker execution is too weak.
- verdict currently depends on sync-summary file existence only: `planningops/scripts/ralph_loop_local.py:356`

5. Lock heartbeat updates only at stage checkpoints, not during long worker command runtime.
- heartbeat at stage saves: `planningops/scripts/issue_loop_runner.py:979`, `planningops/scripts/issue_loop_runner.py:1068`, `planningops/scripts/issue_loop_runner.py:1162`, `planningops/scripts/issue_loop_runner.py:1486`
- contract requires heartbeat lifecycle safety: `planningops/contracts/lease-lock-watchdog-contract.md:20`

## Goals
1. Enforce bounded execution (`attempt_budget`, `max_retries`, `timeout_ms`) in runtime.
2. Guarantee failure classification consistency (`reason_code`) between executor, verifier, and feedback.
3. Reduce false positives (`pass`/`done`) by strengthening verification evidence.
4. Keep Kanban pull model and existing loop-profile policy unchanged.

## Non-Goals
- Introduce a new loop profile (`L6+`).
- Redesign project field schema.
- Build remote orchestration platform in this phase.

## SpecFlow Analysis
### User Flow Overview
1. Runner selects an eligible issue card.
2. Preflight validates PEC + worker task pack.
3. Worker executor runs command with bounded retries/timeouts.
4. Verifier checks artifact completeness and semantic consistency.
5. Feedback updates issue/project fields idempotently.
6. Escalation gate pauses on repeated non-convergence.

### Flow Permutations Matrix
| Case | Trigger | Expected behavior | Required evidence |
|---|---|---|---|
| A. Happy path | command success within first attempt | `pass`, `done` | execution-attempt log + verification report |
| B. Transient runtime error | first attempt fails, second succeeds | `pass` with retry trace | retry timeline + normalized reason transitions |
| C. Timeout | command exceeds `timeout_ms` | fail/inconclusive based on retry policy | timeout reason + backoff history |
| D. Budget exhausted | retry/attempt budget consumed | `blocked` + replan signal | budget ledger + escalation fields |
| E. Long-running command | execution longer than lock TTL window | no duplicate runner acquisition | heartbeat trace during execution |

### Missing Elements and Gap Closures
- **Retry control gap**
  - Missing: real executor-level retry loop bound by contract fields.
  - Closure: implement `worker_executor.py` with deterministic retry/backoff policy adapter.
- **Budget control gap**
  - Missing: `attempt_budget` not applied in runner lifecycle.
  - Closure: add attempt-budget ledger + pre-run budget check + fail-fast classification.
- **Verification quality gap**
  - Missing: summary-file existence is enough for pass path.
  - Closure: enforce required artifact schema and loop-profile-specific checks.
- **Heartbeat gap**
  - Missing: no in-flight heartbeat while worker command is running.
  - Closure: add heartbeat pump thread/process with bounded interval and stop-on-exit.

### Critical Questions and Defaults
1. Critical: What is default worker timeout when task-pack omits/invalid?
- Default: both `dry-run` and `apply` fail preflight and do not start execution.
2. Important: Should runtime_error after all retries be `fail` or `inconclusive`?
- Default: align to current taxonomy (`runtime_error` retries exhausted -> `inconclusive`).
3. Important: Should budget enforcement include wall-clock duration in this phase?
- Default: enforce `max_attempts` first, then duration/token budgets in next increment.

## Proposed Solution
Implement a reliability envelope around worker execution with six enforceable contracts.

### Contract C1: Execution Attempt Ledger
- New artifact:
  - `planningops/artifacts/loops/<date>/<loop_id>/execution-attempts.json`
- Required fields:
  - `attempt_no`, `started_at_utc`, `ended_at_utc`, `exit_code`, `reason_code`, `duration_ms`

### Contract C2: Runtime Retry/Timeout Enforcement
- New script:
  - `planningops/scripts/worker_executor.py`
- Responsibilities:
  - execute rendered command with `timeout_ms`
  - retry using `retry_policy.max_retries`
  - classify errors into taxonomy-aligned reason codes

### Contract C3: Attempt Budget Guard
- Extend runner:
  - enforce `max_attempts` from issue metadata before execution
  - persist budget consumption to watchdog/checkpoint payload

### Contract C4: In-flight Heartbeat Safety
- Heartbeat pump during worker execution window:
  - refresh lock while command is running
  - fail safe if lock ownership changes unexpectedly

### Contract C5: Verification Hard Gate Upgrade
- Extend verifier checks beyond file presence:
  - `execution-attempts.json` schema pass
  - worker output artifacts match selected loop profile
  - final verdict consistency across loop report/project payload

### Contract C6: Reliability CI Pack
- Add regression tests for:
  - timeout path
  - retry convergence path
  - budget exhausted path
  - heartbeat stale-lock race path

## Implementation Phases
### Phase 1: Budget and Executor Boundary (P1)
1. Add `worker_executor.py` with timeout and retry loop.
2. Wire `ralph_loop_local.py` to call executor instead of raw `run_cmd`.
3. Enforce `max_attempts` in `issue_loop_runner.py`.

Deliverables:
- `planningops/scripts/worker_executor.py`
- updated `planningops/scripts/ralph_loop_local.py`
- updated `planningops/scripts/issue_loop_runner.py`

### Phase 2: Verification and Evidence Hardening (P1)
1. Add attempt-ledger artifact schema.
2. Extend `verify_loop_run.py` to validate execution-attempt evidence.
3. Align verdict mapping rules across runner/verify/feedback.

Deliverables:
- `planningops/schemas/execution-attempts.schema.json`
- updated `planningops/scripts/verify_loop_run.py`
- updated `planningops/contracts/requirements-contract.md`

### Phase 3: Heartbeat and Concurrency Safety (P2)
1. Add in-flight heartbeat refresh loop.
2. Add lock-ownership drift detection while worker executes.
3. Emit explicit watchdog event taxonomy for runtime window.

Deliverables:
- updated `planningops/scripts/issue_loop_runner.py`
- updated `planningops/contracts/lease-lock-watchdog-contract.md`

### Phase 4: Regression and CI Reliability Gate (P2)
1. Add contract tests for retry/timeout/budget/heartbeat paths.
2. Add CI job that runs reliability pack on PRs touching loop scripts.

Deliverables:
- `planningops/scripts/test_worker_executor_contract.sh`
- updates to existing loop test scripts
- `.github/workflows` reliability job update

## Backlog Split (Issue Units + Dependencies)
This plan is split into four execution issues. Dependency is strict: no downstream start before blockers are complete.

1. **Issue 022 (P1): Worker executor + attempt budget enforcement**
- scope: Phase 1
- outputs: `worker_executor.py`, `ralph_loop_local.py` integration, `issue_loop_runner.py` budget enforcement
- dependencies: none
- backlog file: `todos/022-ready-p1-worker-executor-budget-enforcement.md`

2. **Issue 023 (P1): Verification hard gate upgrade**
- scope: Phase 2
- outputs: `execution-attempts.schema.json`, verifier checks, requirements contract sync
- dependencies: `022`
- backlog file: `todos/023-ready-p1-verification-hard-gate-upgrade.md`

3. **Issue 024 (P2): In-flight heartbeat and lock safety**
- scope: Phase 3
- outputs: runtime heartbeat pump, lock drift detection, watchdog taxonomy update
- dependencies: `022`
- backlog file: `todos/024-ready-p2-inflight-heartbeat-lock-safety.md`

4. **Issue 025 (P2): Reliability CI pack and regression matrix**
- scope: Phase 4
- outputs: retry/timeout/budget/heartbeat contract tests + CI workflow guard
- dependencies: `023`, `024`
- backlog file: `todos/025-ready-p2-reliability-ci-regression-pack.md`

## Acceptance Criteria
### Functional
- [ ] Worker execution uses enforced timeout and retry policy from validated task pack.
- [ ] Attempt budget is enforced before and during execution lifecycle.
- [ ] Exhausted retry/budget paths emit deterministic `reason_code` and evidence.
- [ ] Verification cannot report `pass` without execution-attempt evidence.

### Reliability
- [ ] No unbounded worker subprocess execution in apply mode.
- [ ] Duplicate run due to stale lock during long execution is prevented in tests.
- [ ] Re-running the same input does not produce divergent feedback state.

### Observability
- [ ] Attempt-level telemetry is present in artifacts and referenced in issue feedback.
- [ ] Watchdog report includes runtime-window heartbeat events.

## Success Metrics
- `worker_runtime_timeout_escaped_count = 0`
- `retry_converged_without_replan_rate >= 0.60` (pilot target)
- `false_pass_verdict_count = 0`
- `duplicate_execution_conflict_count = 0`
- `budget_violation_without_block_count = 0`

## Risks and Mitigations
### Risks
- Over-tight timeout defaults can increase false failures.
- Retry policy mismatch with taxonomy can create noisy escalation.
- Additional reliability checks can increase run latency.

### Mitigations
- Start with dry-run replay across existing artifacts.
- Roll out in `report-only` mode for one cycle, then enforce in apply mode.
- Track latency delta and cap retry count per loop profile.

## References
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-02-uap-post-waveb-next-phase-brainstorm.md`
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-01-uap-loop-selection-policy-brainstorm.md`
- `planningops/scripts/issue_loop_runner.py`
- `planningops/scripts/ralph_loop_local.py`
- `planningops/scripts/verify_loop_run.py`
- `planningops/scripts/validate_worker_task_pack.py`
- `planningops/contracts/requirements-contract.md`
- `planningops/contracts/attempt-budget-contract.md`
- `planningops/contracts/failure-taxonomy-and-retry-policy.md`
- `planningops/contracts/worker-task-pack-contract.md`
- `planningops/contracts/lease-lock-watchdog-contract.md`

## Next Actions
1. Review and refine this plan document.
2. Split Phase 1~4 into backlog issues with `plan_item_id` and dependencies.
3. Execute Phase 1 first (`worker_executor + attempt budget enforcement`) before wider refactors.
