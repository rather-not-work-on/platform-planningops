---
status: complete
priority: p2
issue_id: "029"
tags: [planningops, autonomy, supervisor, workflow, quality]
dependencies: ["022", "023", "024", "025", "027", "028"]
---

# Autonomous Plan-Work-Review-Replan Supervisor

## Problem Statement
We need a single supervisory loop that can continuously execute difficult tasks with quality gates, run experiments when needed, and replan/replenish backlog without manual micromanagement.

## Findings
- Runtime reliability backlog (022-025) establishes technical safety base.
- New process backlog (027-028) establishes comparison/replenishment discipline.
- Missing piece is a supervisor policy that orchestrates:
  - work selection
  - execution depth
  - experiment branching
  - review/replan transitions
  - backlog replenishment

## Proposed Solutions

### Option 1: Gate-Driven Supervisor Policy (Recommended)

**Approach:** Build a policy layer that repeatedly executes `plan -> work -> review -> replan`, with explicit branch/worktree experiment triggers and backlog replenishment outputs.

**Pros:**
- Aligns directly with desired UX
- Encodes quality-first autonomy behavior
- Enables longer unattended operation with controlled risk

**Cons:**
- Requires careful state and trigger design

**Effort:** 4-6 hours

**Risk:** Medium

---

### Option 2: Continue with manual operator steering

**Approach:** Keep existing scripts and rely on manual transitions between planning/work/review cycles.

**Pros:**
- No new orchestration logic

**Cons:**
- Limited unattended autonomy
- Inconsistent loop depth and backlog replenishment

**Effort:** 0 hours now

**Risk:** High

## Recommended Action
Implement Option 1 as policy-first orchestration, then validate with pilot scenarios before broad apply-mode use.

## Technical Details
**Affected files:**
- planning/workbench operating policy docs
- potentially `issue_loop_runner.py` wrapper/supervisor entrypoint
- validation/report artifacts for supervisor decisions

## Acceptance Criteria
- [x] Supervisor loop can run multiple cycles autonomously with quality gates.
- [x] Comparative experiment trigger path is integrated.
- [x] Replan and backlog replenishment are first-class outputs, not side notes.
- [x] Pilot run demonstrates convergence on at least one difficult multi-step task.

## Work Log

### 2026-03-05 - Backlog Creation

**By:** Codex

**Actions:**
- Added supervisor-loop backlog item that depends on reliability and process-control prerequisites.

**Learnings:**
- True long-horizon autonomy is orchestration quality, not just command execution.

### 2026-03-05 - Implementation Complete

**By:** Codex

**Actions:**
- Added supervisor loop runner (`planningops/scripts/autonomous_supervisor_loop.py`) implementing multi-cycle `plan -> work -> review -> replan`.
- Added supervisor contract (`planningops/contracts/autonomous-supervisor-loop-contract.md`) and requirements mapping updates.
- Integrated experiment trigger artifacts (`experiment-trigger.json`) and stop policy (`continue-on-experiment` toggle).
- Wired backlog stock/replenishment gate into each supervisor cycle via `backlog_stock_replenishment_guard.py`.
- Promoted replan/replenishment fields to first-class cycle outputs in supervisor reports.
- Added deterministic simulation fixture and contract test (`planningops/fixtures/supervisor-loop-sequence-sample.json`, `planningops/scripts/test_autonomous_supervisor_loop_contract.sh`).
- Added CI guardrail coverage for supervisor contract test.

**Validation:**
- `python3 -m py_compile planningops/scripts/autonomous_supervisor_loop.py planningops/scripts/issue_loop_runner.py`
- `bash planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
- `bash planningops/scripts/test_backlog_stock_replenishment_contract.sh`
- `bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
- `bash planningops/scripts/test_worker_executor_contract.sh`
- `bash planningops/scripts/test_verify_loop_run_hard_gate_contract.sh`
- `bash planningops/scripts/test_lease_lock_watchdog.sh`
- `bash planningops/scripts/test_loop_checkpoint_resume.sh`
- `bash planningops/scripts/test_validate_worker_task_pack_contract.sh`
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
