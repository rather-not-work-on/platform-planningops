---
status: ready
priority: p2
issue_id: "030"
tags: [planningops, pilot, tradeoff, quality, autonomy]
dependencies: ["029"]
---

# Long-Horizon Autonomy Pilot and Trade-Off Report

## Problem Statement
After policy and supervisor setup, we need a pilot that proves autonomous difficult-task handling quality and captures real trade-offs for next design iteration.

## Findings
- Desired outcome is not raw ticket count; it is high-quality convergence with clear evidence.
- Pilot must include at least one comparative experiment branch/worktree case.
- Without measured pilot outcomes, autonomy policy tuning is guesswork.

## Proposed Solutions

### Option 1: Structured Pilot with KPI and Trade-Off Report (Recommended)

**Approach:** Run controlled autonomy pilot, collect evidence, and publish trade-off report covering correctness, complexity, maintainability, and rollback risk.

**Pros:**
- Converts assumptions into measured decisions
- Provides grounded input for next backlog wave

**Cons:**
- Requires disciplined evidence collection

**Effort:** 3-5 hours

**Risk:** Medium

---

### Option 2: Informal pilot notes

**Approach:** Run ad-hoc sessions and summarize outcomes loosely.

**Pros:**
- Faster

**Cons:**
- Weak comparability and poor decision quality

**Effort:** 1-2 hours

**Risk:** Medium

## Recommended Action
Implement Option 1 and require report publication as gate to the next autonomy expansion cycle.

## Technical Details
**Affected files:**
- pilot runbook doc
- pilot evidence artifacts
- trade-off report document in workbench audits/reviews

## Acceptance Criteria
- [ ] Pilot includes at least one difficult multi-step task solved autonomously.
- [ ] Pilot includes at least one branch/worktree comparison experiment.
- [ ] Trade-off report includes decision rationale and rejected alternatives.
- [ ] New backlog items are generated from pilot findings with dependencies.

## Work Log

### 2026-03-05 - Backlog Creation

**By:** Codex

**Actions:**
- Added pilot-validation backlog item as final validation stage for refined Approach B.

**Learnings:**
- Pilot and trade-off evidence are required to prevent policy overconfidence.

