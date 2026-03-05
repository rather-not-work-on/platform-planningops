---
status: ready
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
- [ ] Supervisor loop can run multiple cycles autonomously with quality gates.
- [ ] Comparative experiment trigger path is integrated.
- [ ] Replan and backlog replenishment are first-class outputs, not side notes.
- [ ] Pilot run demonstrates convergence on at least one difficult multi-step task.

## Work Log

### 2026-03-05 - Backlog Creation

**By:** Codex

**Actions:**
- Added supervisor-loop backlog item that depends on reliability and process-control prerequisites.

**Learnings:**
- True long-horizon autonomy is orchestration quality, not just command execution.

