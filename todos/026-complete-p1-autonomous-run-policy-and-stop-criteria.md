---
status: complete
priority: p1
issue_id: "026"
tags: [planningops, autonomy, governance, reliability]
dependencies: []
---

# Autonomous Run Policy and Stop Criteria Contract

## Problem Statement
Autonomous execution intent is clear, but run control is still interpreted as time-window oriented in some places. We need explicit policy that prioritizes convergence quality and risk gates over fixed runtime duration.

## Findings
- Long-horizon autonomy needs deterministic start/stop/replan criteria.
- Existing safety signals already exist (`same_reason_x3`, `inconclusive_x2`) and should remain primary brakes.
- Current wording can be interpreted as “run for N hours” instead of “run until quality/risk criteria are met.”

## Proposed Solutions

### Option 1: Convergence/Risk-Based Run Policy Contract (Recommended)

**Approach:** Define run continuation and stop conditions using convergence metrics, quality gates, and risk triggers. Runtime duration remains secondary metadata.

**Pros:**
- Matches user intent exactly
- Reduces blind long-running behavior
- Keeps Kanban pull discipline

**Cons:**
- Requires clear KPI and threshold definitions

**Effort:** 2-3 hours

**Risk:** Low

---

### Option 2: Keep Time-Window Policy + Add Caveats

**Approach:** Keep “3h+” style policy and add caveat text around quality.

**Pros:**
- Minimal change

**Cons:**
- Ambiguity remains
- Easy to drift into throughput-first operations

**Effort:** <1 hour

**Risk:** Medium

## Recommended Action
Implement Option 1 and make convergence/risk the only hard control axis for autonomous runs.

## Technical Details
**Affected files:**
- brainstorm/plan docs defining autonomous mode
- `planningops/contracts/requirements-contract.md` (if control semantics need explicit lock)

## Acceptance Criteria
- [x] Autonomous mode definition is explicitly difficulty/convergence bounded, not time bounded.
- [x] Stop conditions include quality gate fail + escalation triggers + safety conflicts.
- [x] Replan trigger linkage is explicit and testable.

## Work Log

### 2026-03-05 - Backlog Creation

**By:** Codex

**Actions:**
- Added policy-contract backlog item from Approach B refinement.

**Learnings:**
- Time budget is operational metadata, not primary control logic.

### 2026-03-05 - Implementation Complete

**By:** Codex

**Actions:**
- Added `planningops/contracts/autonomous-run-policy-contract.md` to formalize convergence/risk-based autonomous run control and deterministic stop criteria.
- Linked stop/replan logic to existing testable implementation anchors:
  - `planningops/scripts/issue_loop_runner.py` (`evaluate_escalation`, `run_with_runtime_heartbeat`)
  - `planningops/scripts/verify_loop_run.py`
  - tests: `test_escalation_gate.sh`, `test_lease_lock_watchdog.sh`, `test_verify_loop_run_hard_gate_contract.sh`
- Updated `planningops/contracts/requirements-contract.md` with explicit autonomous control/stop requirements and mapping reference.
- Updated `planningops/contracts/README.md` contract index.

**Learnings:**
- Making autonomy control explicit in contracts prevents drift back to time-window interpretations and keeps stop behavior reviewable.
