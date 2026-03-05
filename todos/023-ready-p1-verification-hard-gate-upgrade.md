---
status: ready
priority: p1
issue_id: "023"
tags: [planningops, verifier, contracts, reliability]
dependencies: ["022"]
---

# Verification Hard Gate Upgrade

## Problem Statement
Current verification can mark runs as pass with weak evidence checks, which risks false-positive completion signals.

## Findings
- `ralph_loop_local.py` pass path currently relies on sync-summary existence.
  - `planningops/scripts/ralph_loop_local.py:356`
- `verify_loop_run.py` validates required artifacts, but execution-attempt semantics are not yet contract-enforced.
  - `planningops/scripts/verify_loop_run.py:60`
- Reliability plan requires stronger evidence gate linked to worker attempt history.
  - `docs/workbench/unified-personal-agent-platform/plans/2026-03-05-refactor-worker-reliability-hardening-plan.md`

## Proposed Solutions

### Option 1: Add execution-attempt schema and verifier checks (Recommended)

**Approach:** Add `execution-attempts.schema.json` and enforce it in verification logic together with verdict consistency checks.

**Pros:**
- Explicit, testable evidence contract
- Prevents pass verdict on incomplete runtime evidence

**Cons:**
- Requires additional artifact writes from executor path

**Effort:** 3-5 hours

**Risk:** Medium

---

### Option 2: Keep verifier simple and tighten only loop-side checks

**Approach:** Expand `ralph_loop_local.py` checks but avoid new schema/validator.

**Pros:**
- Smaller immediate change

**Cons:**
- Harder to audit and reuse
- More fragile against drift

**Effort:** 2-4 hours

**Risk:** Medium

## Recommended Action
Implement Option 1 and bind verifier to a schema-backed execution evidence contract.

## Technical Details
**Affected files:**
- `planningops/schemas/execution-attempts.schema.json` (new)
- `planningops/scripts/verify_loop_run.py`
- `planningops/scripts/ralph_loop_local.py`
- `planningops/contracts/requirements-contract.md`

## Acceptance Criteria
- [ ] Verification fails when execution-attempt evidence is missing or schema-invalid.
- [ ] Final verdict consistency is enforced across loop report and project payload.
- [ ] Pass verdict requires execution-attempt evidence and required artifact set.
- [ ] Regression tests cover missing/malformed attempt artifacts.

## Work Log

### 2026-03-05 - Backlog Split

**By:** Codex

**Actions:**
- Derived this backlog issue from reliability hardening plan Phase 2.
- Linked dependency to issue `022` because attempt artifacts are produced by executor enforcement.

**Learnings:**
- Verifier strictness must follow executor artifact model; otherwise pass/fail semantics diverge.

