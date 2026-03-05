---
status: done
priority: p1
issue_id: "018"
tags: [code-review, planningops, contracts, reliability]
dependencies: []
---

# Compile Dedup Key Collision Across Plans

## Problem Statement

`compile_plan_to_backlog.py` deduplicates existing issues using only `plan_item_id`. This can incorrectly match an issue from a different plan/revision, causing updates/reopen actions to target the wrong card.

## Findings

- `find_issue_for_item()` matches by marker `plan_item_id` only, without `plan_id` or `target_repo` scope.
  - `planningops/scripts/compile_plan_to_backlog.py:207`
- `compile_item()` relies on this lookup for open and closed issue reuse.
  - `planningops/scripts/compile_plan_to_backlog.py:385`
  - `planningops/scripts/compile_plan_to_backlog.py:391`
- Contract text states deterministic identity is `plan_item_id + target_repo`, but implementation does not enforce that identity key.

## Proposed Solutions

### Option 1: Match By Composite Marker (Recommended)

**Approach:** Parse and match `plan_id`, `plan_item_id`, and `target_repo` from issue body metadata.

**Pros:**
- Aligns with contract-level determinism
- Low invasive change to existing flow

**Cons:**
- Requires robust issue-body metadata parser

**Effort:** 2-4 hours

**Risk:** Medium

---

### Option 2: Add Stable Hash Key Field

**Approach:** Write `compile_identity_key` into issue body and match only by this key.

**Pros:**
- Single-key deterministic matching
- Less parsing logic

**Cons:**
- Requires migration for existing issues

**Effort:** 4-6 hours

**Risk:** Medium

## Recommended Action

## Technical Details

**Affected files:**
- `planningops/scripts/compile_plan_to_backlog.py`

## Resources

- `planningops/contracts/plan-execution-contract-v1.md`

## Acceptance Criteria

- [x] Dedup uses deterministic composite identity, not raw `plan_item_id` alone
- [x] Cross-plan collision regression test added
- [x] Existing tests continue to pass

## Work Log

### 2026-03-04 - Resolution

**By:** Codex

**Actions:**
- Updated compiler dedup matching to use composite identity (`plan_id + plan_item_id + target_repo`).
- Added deterministic ambiguity fail-fast when multiple issues share same identity.
- Added regression tests for cross-plan collision and duplicate identity rows.

**Validation:**
- `bash planningops/scripts/test_compile_plan_to_backlog_contract.sh`

### 2026-03-04 - Code Review Finding

**By:** Codex

**Actions:**
- Reviewed compile dedup path and issue reuse flow.
- Confirmed identity mismatch between contract and implementation.

**Learnings:**
- Wrong-card reuse risk exists when different plans share same `plan_item_id` pattern.

## Notes

- Blocks safe autonomous backlog sync at scale.
