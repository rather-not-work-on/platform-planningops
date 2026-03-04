---
status: done
priority: p2
issue_id: "019"
tags: [code-review, planningops, drift, automation]
dependencies: []
---

# Compile Existing Issue Metadata Not Resynced

## Problem Statement

When compile finds an existing issue, it reuses the issue as-is and does not update title/body metadata. Plan revisions can therefore drift from issue metadata, breaking deterministic plan-to-issue projection.

## Findings

- Existing issue branch skips metadata update path entirely.
  - `planningops/scripts/compile_plan_to_backlog.py:403`
- Body/title construction exists only for create path.
  - `planningops/scripts/compile_plan_to_backlog.py:407`
  - `planningops/scripts/compile_plan_to_backlog.py:408`

## Proposed Solutions

### Option 1: Add Issue Edit Sync On Reuse (Recommended)

**Approach:** On matched issue, compare desired title/body and call `gh issue edit` when changed.

**Pros:**
- Restores idempotent sync semantics
- Keeps current architecture

**Cons:**
- Additional API calls during compile

**Effort:** 2-3 hours

**Risk:** Low

---

### Option 2: Strict Drift Fail Instead of Auto-Edit

**Approach:** Detect mismatch and fail compile, requiring explicit operator reconciliation.

**Pros:**
- Strong governance and audit trail

**Cons:**
- Higher operational friction

**Effort:** 2-4 hours

**Risk:** Medium

## Recommended Action

## Technical Details

**Affected files:**
- `planningops/scripts/compile_plan_to_backlog.py`

## Acceptance Criteria

- [x] Existing issue metadata is reconciled or deterministic fail is emitted
- [x] Regression test covers plan revision metadata update path
- [x] Compile report explicitly records metadata update action

## Work Log

### 2026-03-04 - Resolution

**By:** Codex

**Actions:**
- Added issue metadata reconciliation path on reuse (title/body compare + `gh issue edit` in apply mode).
- Added report fields `metadata_sync_required` and `metadata_sync_action` for explicit traceability.
- Added dry-run/apply regression tests for stale-metadata reuse path.

**Validation:**
- `bash planningops/scripts/test_compile_plan_to_backlog_contract.sh`

### 2026-03-04 - Code Review Finding

**By:** Codex

**Actions:**
- Traced create/reuse branches in compiler implementation.
- Verified no update path for reused issues.

**Learnings:**
- Current behavior can silently carry stale plan context.
