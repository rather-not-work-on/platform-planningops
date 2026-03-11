---
status: complete
priority: p2
issue_id: "035"
tags: [code-review, architecture, quality, planningops]
dependencies: []
---

# compile_plan_to_backlog plan_lane enforcement gap

## Problem Statement

`compile_plan_to_backlog.py` now supports syncing `plan_lane`, but the execution contract does not require `plan_lane`. This allows issue creation without lane metadata, which breaks the "create -> auto-set project fields" guarantee for `plan_lane`.

## Findings

- `REQUIRED_ITEM_KEYS` excludes `plan_lane`, so missing lane is accepted.
- Project update applies lane only when `item.get("plan_lane")` is present.
- Result: cards can be created with `component/workflow_state` set but `plan_lane` unset.

Evidence:
- `planningops/scripts/compile_plan_to_backlog.py:52`
- `planningops/scripts/compile_plan_to_backlog.py:112`
- `planningops/scripts/compile_plan_to_backlog.py:558`

## Proposed Solutions

### Option 1: Make plan_lane required in PEC contract

**Approach:** Add `plan_lane` to `REQUIRED_ITEM_KEYS` and fail validation when missing.

**Pros:**
- Deterministic field sync for every created card.
- Contract behavior matches current operating policy.

**Cons:**
- Existing contracts without lane need migration.

**Effort:** 1-2 hours

**Risk:** Medium

---

### Option 2: Keep optional in contract, force default lane mapping

**Approach:** If missing, derive lane from `workflow_state` or execution range.

**Pros:**
- Backward compatible with older contracts.

**Cons:**
- Introduces implicit policy and hidden behavior.
- Harder to reason about in audits.

**Effort:** 2-3 hours

**Risk:** Medium

## Recommended Action

Option 1 implemented: make `plan_lane` required and enforce it through runtime validator, JSON schema, contract doc, fixtures, and projection verification.


## Technical Details

**Affected files:**
- `planningops/scripts/compile_plan_to_backlog.py`
- `planningops/scripts/test_compile_plan_to_backlog_contract.sh`
- `planningops/scripts/verify_plan_projection.py`
- `planningops/scripts/test_verify_plan_projection_contract.sh`
- `planningops/contracts/plan-execution-contract-v1.md`
- `planningops/schemas/plan-execution-contract.schema.json`
- `planningops/fixtures/plan-execution-contract-sample.json`
- `planningops/fixtures/plan-projection-snapshot-sample.json`

## Resources

- Review context: field auto-sync workstream (`plan_lane/workflow_state/component`)

## Acceptance Criteria

- [x] PEC validation fails when `plan_lane` is missing (or deterministic default is explicitly documented and tested).
- [x] Created/updated cards always have `plan_lane` set after `compile_plan_to_backlog --apply`.
- [x] Contract docs and fixtures are aligned.

## Work Log

### 2026-03-05 - Initial Discovery

**By:** Codex

**Actions:**
- Reviewed `compile_plan_to_backlog.py` lane integration path.
- Confirmed optional lane behavior in validation and apply paths.

**Learnings:**
- Sync support exists, but contract guarantee is incomplete.

### 2026-03-11 - Contract Hardening Applied

**By:** Codex

**Actions:**
- Added `plan_lane` to `REQUIRED_ITEM_KEYS` in compile and projection validators.
- Made `plan_lane` required in PEC JSON schema and v1 contract doc.
- Updated sample PEC/snapshot fixtures with canonical lane values.
- Added regression coverage for missing-lane validation and lane projection mismatch.
- Ran:
  - `bash planningops/scripts/test_compile_plan_to_backlog_contract.sh`
  - `bash planningops/scripts/test_verify_plan_projection_contract.sh`
  - `python3 -m py_compile planningops/scripts/compile_plan_to_backlog.py planningops/scripts/verify_plan_projection.py`

**Learnings:**
- Requiring lane in both compile and projection validation closes the contract/runtime gap and keeps project lane sync deterministic.

## Notes

- This is a contract/consistency finding, not an immediate runtime crash.
