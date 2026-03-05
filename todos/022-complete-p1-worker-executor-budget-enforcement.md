---
status: complete
priority: p1
issue_id: "022"
tags: [planningops, worker, reliability, runtime]
dependencies: []
---

# Worker Executor and Attempt Budget Enforcement

## Problem Statement
Worker execution is currently single-shot and does not enforce attempt-budget limits at runtime, which weakens convergence guarantees.

## Findings
- `ralph_loop_local.py` executes worker command once via `run_cmd(...)` without retry/timeout control.
  - `planningops/scripts/ralph_loop_local.py:299`
- `issue_loop_runner.py` parses attempt budget but does not enforce it during run lifecycle.
  - `planningops/scripts/issue_loop_runner.py:401`
  - `planningops/scripts/issue_loop_runner.py:804`
- Contracts already require bounded retries and budget semantics.
  - `planningops/contracts/attempt-budget-contract.md`
  - `planningops/contracts/failure-taxonomy-and-retry-policy.md`

## Proposed Solutions

### Option 1: Add dedicated executor module (Recommended)

**Approach:** Introduce `worker_executor.py` that enforces timeout/retry policy and integrate it into `ralph_loop_local.py`, then apply budget guard in `issue_loop_runner.py`.

**Pros:**
- Clear runtime boundary
- Reusable in future multi-repo execution path
- Improves deterministic classification of runtime failures

**Cons:**
- Requires interface and test updates

**Effort:** 4-6 hours

**Risk:** Medium

---

### Option 2: Inline retry/timeout logic into existing scripts

**Approach:** Add loops directly in `ralph_loop_local.py` and budget checks in `issue_loop_runner.py` without new module.

**Pros:**
- Fewer files changed

**Cons:**
- Harder to test and reuse
- Higher chance of logic drift

**Effort:** 3-5 hours

**Risk:** Medium

## Recommended Action
Implement Option 1. Keep policy resolution unchanged, but move execution controls into a dedicated executor and enforce `max_attempts` before/through execution.

## Technical Details
**Affected files:**
- `planningops/scripts/worker_executor.py` (new)
- `planningops/scripts/ralph_loop_local.py`
- `planningops/scripts/issue_loop_runner.py`
- `planningops/contracts/attempt-budget-contract.md` (if wording update needed)

## Acceptance Criteria
- [x] Worker command execution enforces timeout/retry bounds from validated runtime/task-pack policy.
- [x] Attempt budget (`max_attempts`) is enforced and violation path is explicit.
- [x] Exhausted retries emit deterministic reason classification.
- [x] Contract tests cover success/retry/timeout/budget-exhausted paths.

## Work Log

### 2026-03-05 - Backlog Split

**By:** Codex

**Actions:**
- Derived this backlog issue from reliability hardening plan Phase 1.
- Linked problem and contract anchors for immediate implementation start.

**Learnings:**
- Runtime reliability gaps are mostly enforcement gaps, not schema-definition gaps.

### 2026-03-05 - Implementation Complete

**By:** Codex

**Actions:**
- Added `planningops/scripts/worker_executor.py` and enforced retry/timeout/budget policy execution.
- Wired `planningops/scripts/ralph_loop_local.py` to load validated worker task-pack policy, apply `max_attempts`, and emit deterministic execution reason codes.
- Updated `planningops/scripts/issue_loop_runner.py` to pass budget/task-pack enforcement context into loop execution and expose attempt-budget guard evidence in selection/output payloads.
- Expanded regression coverage:
  - `planningops/scripts/test_worker_executor_contract.sh` (new)
  - `planningops/scripts/test_ralph_loop_local_worker_policy.sh`
  - `planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`

**Learnings:**
- Splitting worker execution into a dedicated module keeps policy semantics stable and testable while minimizing drift in loop orchestration code.
