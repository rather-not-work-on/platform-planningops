---
status: complete
priority: p1
issue_id: "027"
tags: [planningops, experimentation, worktree, architecture, tradeoff]
dependencies: ["026"]
---

# Worktree/Branch Comparative Experiment Protocol

## Problem Statement
When architecture trade-offs are unclear, decisions can be made from intuition only. We need a repeatable protocol to run A/B implementation experiments in separate worktrees and compare outcomes with evidence.

## Findings
- Current process has simulation and verification, but no formal “compare options by experiment artifact” loop.
- User intent explicitly requires direct experiments and trade-off sensing before committing to one direction.
- Git worktree is already an available mechanism and fits local-first workflow.

## Proposed Solutions

### Option 1: Standard A/B Worktree Experiment Protocol (Recommended)

**Approach:** For uncertain decisions, create at least two worktrees/branches, run minimal scoped implementations or simulations, and compare with fixed rubric.

**Pros:**
- Evidence-based decision making
- Better architecture quality under uncertainty
- Clear rollback path

**Cons:**
- Additional setup and review overhead

**Effort:** 3-4 hours

**Risk:** Medium

---

### Option 2: Single-branch Spike Notes

**Approach:** Keep one branch and compare alternatives by docs/notes only.

**Pros:**
- Faster setup

**Cons:**
- Weaker evidence
- Harder to detect hidden integration trade-offs

**Effort:** 1-2 hours

**Risk:** Medium

## Recommended Action
Implement Option 1 with a minimal experiment template and scoring rubric.

## Technical Details
**Affected files:**
- workbench audit/plan doc for experiment protocol
- optional script helper for experiment manifest generation

## Acceptance Criteria
- [x] Protocol defines when to trigger comparative experiment mode.
- [x] Protocol defines required artifacts per option (result, complexity notes, rollback cost).
- [x] Protocol defines deterministic decision rubric and selection record format.
- [x] At least one real pilot comparison run is captured.

## Work Log

### 2026-03-05 - Backlog Creation

**By:** Codex

**Actions:**
- Added protocol backlog item for branch/worktree comparative experiments.

**Learnings:**
- High-quality autonomy needs explicit experimentation discipline, not just execution loops.

### 2026-03-05 - Implementation Complete

**By:** Codex

**Actions:**
- Added `planningops/contracts/worktree-comparative-experiment-protocol.md` with:
  - trigger conditions,
  - execution rules,
  - required artifact contract,
  - deterministic weighted decision rubric,
  - selection record format.
- Synced contract index and requirements mapping:
  - `planningops/contracts/README.md`
  - `planningops/contracts/requirements-contract.md`
- Captured a real A/B pilot comparison run:
  - root: `planningops/artifacts/experiments/2026-03-05-lock-drift-classification/`
  - files:
    - `manifest.json`
    - `option-a-report.json`
    - `option-b-report.json`
    - `decision-record.md`
    - `option-a-test.log`
    - `option-b-test.log`
  - validation command: `bash planningops/scripts/test_lease_lock_watchdog.sh`

**Learnings:**
- Using real worktree mutations in pilot mode makes reliability trade-offs concrete and avoids intuition-only decisions.
