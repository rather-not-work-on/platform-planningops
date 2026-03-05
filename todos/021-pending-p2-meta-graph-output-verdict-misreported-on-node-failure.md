---
status: done
priority: p2
issue_id: "021"
tags: [code-review, planningops, ci, reliability]
dependencies: []
---

# Meta Graph Output Verdict Misreported On Node Failure

## Problem Statement

`meta_plan_orchestrator.py` always writes `meta_graph_output` with `"verdict": "pass"` after execution, even when node pipeline fails and report verdict is fail. This can mislead downstream consumers.

## Findings

- `meta_graph_output` write uses hardcoded pass verdict in normal tail path.
  - `planningops/scripts/meta_plan_orchestrator.py:196`
- Failure classification is correctly computed in report (`node_pipeline_failure`) but not reflected in `meta_graph_output`.
  - `planningops/scripts/meta_plan_orchestrator.py:193`

## Proposed Solutions

### Option 1: Mirror Final Report Verdict In Meta Graph Output (Recommended)

**Approach:** Use computed `report["verdict"]` when writing `meta_graph_output`.

**Pros:**
- Consistent artifact semantics
- Minimal code change

**Cons:**
- None significant

**Effort:** <1 hour

**Risk:** Low

---

### Option 2: Remove Verdict Field From Meta Graph Output

**Approach:** Keep only graph payload and force consumers to read execution report for verdict.

**Pros:**
- Eliminates dual-source verdict ambiguity

**Cons:**
- Breaking change for consumers expecting verdict field

**Effort:** 1-2 hours

**Risk:** Medium

## Recommended Action

## Technical Details

**Affected files:**
- `planningops/scripts/meta_plan_orchestrator.py`

## Acceptance Criteria

- [x] `meta_graph_output.verdict` equals execution report verdict
- [x] Regression test asserts fail-path output consistency

## Work Log

### 2026-03-04 - Resolution

**By:** Codex

**Actions:**
- Fixed orchestrator to write `meta_graph_output.verdict` from computed execution verdict.
- Added fail-path regression assertion to ensure graph output and execution report verdicts stay consistent.

**Validation:**
- `bash planningops/scripts/test_meta_plan_orchestrator_contract.sh`

### 2026-03-04 - Code Review Finding

**By:** Codex

**Actions:**
- Compared report verdict branch and output artifact write path.
- Confirmed inconsistent pass write on fail branch.

**Learnings:**
- Artifact consumers can receive false-positive graph health signal.
