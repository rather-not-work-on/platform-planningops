---
status: complete
priority: p2
issue_id: "025"
tags: [planningops, ci, regression, reliability, contracts]
dependencies: ["023", "024"]
---

# Reliability CI Regression Pack

## Problem Statement
Without a dedicated reliability CI pack, regressions in retry/timeout/budget/heartbeat behavior can re-enter after local fixes.

## Findings
- Existing tests cover several contracts but do not yet guarantee full reliability envelope introduced by Phase 1-3.
- Reliability hardening plan requires explicit regression matrix and CI guard.
  - `docs/workbench/unified-personal-agent-platform/plans/2026-03-05-refactor-worker-reliability-hardening-plan.md`
- Prior reviews found guardrail regressions when checks were not wired to CI.

## Proposed Solutions

### Option 1: Add focused reliability contract test pack and CI trigger (Recommended)

**Approach:** Add dedicated test script(s) for retry/timeout/budget/heartbeat scenarios and wire workflow trigger for loop-runtime file changes.

**Pros:**
- Prevents silent regression of reliability contracts
- Fast feedback at PR stage

**Cons:**
- Additional CI runtime cost

**Effort:** 2-4 hours

**Risk:** Low

---

### Option 2: Rely on manual smoke tests only

**Approach:** Keep local script validation without CI enforcement.

**Pros:**
- No CI overhead

**Cons:**
- High regression risk
- Non-deterministic quality gate behavior

**Effort:** <1 hour

**Risk:** High

## Recommended Action
Implement Option 1 after completion of issues `023` and `024`.

## Technical Details
**Affected files:**
- `planningops/scripts/test_worker_executor_contract.sh` (new)
- existing test scripts for lock/watchdog and verification
- `.github/workflows/*` reliability check workflow

## Acceptance Criteria
- [x] CI runs reliability pack on changes to loop runtime scripts/contracts/schemas.
- [x] Test matrix includes timeout, retry convergence, budget exhausted, and heartbeat lock safety.
- [x] Failing reliability checks block merge.
- [x] CI output links to deterministic artifact/report paths.

## Work Log

### 2026-03-05 - Backlog Split

**By:** Codex

**Actions:**
- Derived this backlog issue from reliability hardening plan Phase 4.
- Set dependencies on issues `023` and `024` because CI pack must reflect finalized verifier and lock runtime behavior.

**Learnings:**
- Reliability guarantees decay quickly without permanent CI enforcement.

### 2026-03-05 - Implementation Complete

**By:** Codex

**Actions:**
- Upgraded `.github/workflows/planningops-contracts-dryrun.yml` with a dedicated reliability regression pack step.
- Wired the following regression set into CI:
  - `planningops/scripts/test_worker_executor_contract.sh`
  - `planningops/scripts/test_verify_loop_run_hard_gate_contract.sh`
  - `planningops/scripts/test_lease_lock_watchdog.sh`
  - `planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
  - `planningops/scripts/test_loop_checkpoint_resume.sh`
- Added deterministic CI report generation:
  - `planningops/artifacts/validation/worker-task-pack-ci-report.json`
  - `planningops/artifacts/ci/reliability-regression-summary.json`
- Kept execution inside existing required workflow/job (`PlanningOps Contracts Dry-Run` / `validate-and-dry-run`) so reliability failures block merge.

**Learnings:**
- Reusing an already-required gate is the lowest-risk way to enforce new reliability invariants without branch-protection drift.
