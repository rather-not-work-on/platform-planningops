---
status: pending
priority: p2
issue_id: "036"
tags: [code-review, reliability, planningops]
dependencies: []
---

# program manifest builder scans all issue states without dedup policy

## Problem Statement

`build_program_manifest.py` scans `state=all` issues across repos and directly materializes rows into manifest items. If historical closed issues with the same `plan_item_id` exist, manifest validation can fail due to duplicate keys, even when current active cards are valid.

## Findings

- Source fetch uses `state=all` for every repo.
- Build path appends all matching entries without deduping by `{plan_item_id,target_repo}` or open-state preference.
- Validation then fails on duplicate `plan_item_id`.

Evidence:
- `planningops/scripts/build_program_manifest.py:84`
- `planningops/scripts/build_program_manifest.py:135`
- `planningops/scripts/build_program_manifest.py:142`
- `planningops/scripts/build_program_manifest.py:185`

## Proposed Solutions

### Option 1: Use `state=open` by default

**Approach:** Restrict source listing to open issues for live program manifest.

**Pros:**
- Eliminates historical duplicates.
- Aligns with active Kanban execution set.

**Cons:**
- Closed-state observability requires separate historical report.

**Effort:** 1 hour

**Risk:** Low

---

### Option 2: Keep `state=all`, add deterministic dedup

**Approach:** Group by `{plan_item_id,target_repo}` and pick winner by state priority(open > closed) + latest update.

**Pros:**
- Supports historical visibility while keeping manifest stable.

**Cons:**
- More complex selection logic.

**Effort:** 2-4 hours

**Risk:** Medium

## Recommended Action


## Technical Details

**Affected files:**
- `planningops/scripts/build_program_manifest.py`
- `planningops/scripts/test_build_program_manifest_contract.sh`

## Resources

- A00 deliverable artifacts:
  - `planningops/artifacts/program/program-manifest.json`
  - `planningops/artifacts/validation/program-manifest-report.json`

## Acceptance Criteria

- [ ] Manifest generation is deterministic even with historical duplicate keys.
- [ ] Duplicate handling policy is explicit and covered by regression test.
- [ ] Report clearly indicates selected winner when duplicates exist.

## Work Log

### 2026-03-05 - Initial Discovery

**By:** Codex

**Actions:**
- Reviewed source fetch/build/validate flow.
- Identified duplicate-susceptible path from all-state listing.

**Learnings:**
- Current implementation works for now but can regress as issue history accumulates.

## Notes

- This is reliability debt likely to surface later, not immediate production failure.
