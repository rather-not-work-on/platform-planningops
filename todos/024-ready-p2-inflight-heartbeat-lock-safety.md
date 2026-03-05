---
status: ready
priority: p2
issue_id: "024"
tags: [planningops, lock, watchdog, reliability, concurrency]
dependencies: ["022"]
---

# In-Flight Heartbeat and Lock Safety

## Problem Statement
Lease lock heartbeat is refreshed at stage boundaries, but not continuously during long worker execution, leaving a stale-lock window.

## Findings
- Heartbeat refresh currently occurs on checkpoint events.
  - `planningops/scripts/issue_loop_runner.py:979`
  - `planningops/scripts/issue_loop_runner.py:1068`
  - `planningops/scripts/issue_loop_runner.py:1162`
  - `planningops/scripts/issue_loop_runner.py:1486`
- Contract expects lock lifecycle safety and stale/zombie mitigation.
  - `planningops/contracts/lease-lock-watchdog-contract.md`
- Long-running worker operations can exceed practical heartbeat intervals.

## Proposed Solutions

### Option 1: Add runtime heartbeat pump during worker execution (Recommended)

**Approach:** Start heartbeat refresh loop while worker is running and stop on completion/interruption.

**Pros:**
- Closes stale-lock gap during long runs
- Aligns with lock contract intent

**Cons:**
- Adds concurrency complexity

**Effort:** 3-4 hours

**Risk:** Medium

---

### Option 2: Increase lock TTL only

**Approach:** Extend TTL to reduce stale-lock collisions without active heartbeat loop.

**Pros:**
- Very small code change

**Cons:**
- Does not solve actual stale-lock lifecycle reliability
- Slower recovery from truly dead workers

**Effort:** 1-2 hours

**Risk:** High

## Recommended Action
Implement Option 1 and emit explicit watchdog events for runtime-window heartbeat behavior.

## Technical Details
**Affected files:**
- `planningops/scripts/issue_loop_runner.py`
- `planningops/contracts/lease-lock-watchdog-contract.md`
- `planningops/scripts/test_lease_lock_watchdog.sh` (or equivalent regression script)

## Acceptance Criteria
- [ ] Heartbeat refresh runs during worker execution window.
- [ ] Lock ownership drift during execution is detected and classified.
- [ ] Watchdog artifact includes runtime-window heartbeat events.
- [ ] Regression test covers long-running execution with lock safety assertions.

## Work Log

### 2026-03-05 - Backlog Split

**By:** Codex

**Actions:**
- Derived this backlog issue from reliability hardening plan Phase 3.
- Linked dependency to issue `022` because execution boundary refactor defines runtime window.

**Learnings:**
- Stage-only heartbeat is insufficient once worker runtime becomes policy-driven and potentially long-lived.

