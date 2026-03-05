---
status: complete
priority: p1
issue_id: "028"
tags: [planningops, backlog, kanban, queue, autonomy]
dependencies: ["026"]
---

# Backlog Stock and Replenishment Loop

## Problem Statement
Autonomous execution quality degrades when backlog stock becomes shallow or noisy. We need a contract for backlog stock levels, replenishment cadence, and quality filters.

## Findings
- User intent requires both “do useful work now” and “continuously add quality next issues.”
- Existing backlog items are good but no explicit stock floor/replenishment policy is fixed.
- Without filters, low-quality follow-up issues can flood queue and reduce signal.

## Proposed Solutions

### Option 1: Stock-Level Contract + Replenishment Gate (Recommended)

**Approach:** Define minimum stock per queue class and a replenishment gate that accepts only dependency-scoped, evidence-backed follow-ups.

**Pros:**
- Preserves execution continuity
- Prevents vague issue accumulation
- Improves prioritization signal

**Cons:**
- Requires queue classification and validation rules

**Effort:** 2-4 hours

**Risk:** Medium

---

### Option 2: Ad-hoc Backlog Growth

**Approach:** Add issues as discovered without stock targets or filters.

**Pros:**
- Low process overhead

**Cons:**
- Queue noise growth
- Unstable prioritization

**Effort:** <1 hour

**Risk:** High

## Recommended Action
Implement Option 1 and make backlog quality filters part of the autonomous gate.

## Technical Details
**Affected files:**
- workbench plan/brainstorm docs for queue policy
- optional queue validation/report script
- `todos/` governance notes if needed

## Acceptance Criteria
- [x] Queue classes and minimum stock targets are defined.
- [x] Replenishment requires evidence-backed candidate generation.
- [x] New backlog entries include dependency and acceptance criteria baseline.
- [x] “Immediate high-value ready item first” rule is explicitly enforced.

## Work Log

### 2026-03-05 - Backlog Creation

**By:** Codex

**Actions:**
- Added backlog stock/replenishment control issue from Approach B refinement.

**Learnings:**
- Sustainable autonomy requires queue health controls, not only runner controls.

### 2026-03-05 - Implementation Complete

**By:** Codex

**Actions:**
- Added backlog stock/replenishment contract and policy (`planningops/contracts/backlog-stock-replenishment-contract.md`, `planningops/config/backlog-stock-policy.json`).
- Added stock/replenishment guard script and regression test (`planningops/scripts/backlog_stock_replenishment_guard.py`, `planningops/scripts/test_backlog_stock_replenishment_contract.sh`).
- Enforced explicit `high_value_ready_first` ordering in intake selection (`planningops/scripts/issue_loop_runner.py`).
- Added evidence-backed replenishment candidate artifact generation in runner output (`planningops/artifacts/backlog/issue-<n>-replenishment-candidates.json`).
- Wired new contract test into CI guardrails.

**Validation:**
- `python3 -m py_compile planningops/scripts/issue_loop_runner.py planningops/scripts/backlog_stock_replenishment_guard.py`
- `bash planningops/scripts/test_worker_executor_contract.sh`
- `bash planningops/scripts/test_verify_loop_run_hard_gate_contract.sh`
- `bash planningops/scripts/test_lease_lock_watchdog.sh`
- `bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
- `bash planningops/scripts/test_loop_checkpoint_resume.sh`
- `bash planningops/scripts/test_validate_worker_task_pack_contract.sh`
- `bash planningops/scripts/test_backlog_stock_replenishment_contract.sh`
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
