---
status: done
priority: p2
issue_id: "020"
tags: [code-review, planningops, schema, governance]
dependencies: []
---

# Meta Graph Schema Validation Not Enforced At Runtime

## Problem Statement

`build_meta_plan_graph.py` and `meta_plan_orchestrator.py` rely on custom structural checks, but do not enforce `meta-plan-graph.schema.json` at runtime. Invalid enum/pattern values can bypass strict mode.

## Findings

- Runtime validation uses `validate_meta_graph()` only (required-key and basic type checks).
  - `planningops/scripts/build_meta_plan_graph.py:22`
  - `planningops/scripts/meta_plan_orchestrator.py:78`
- No schema-load/JSON-schema validation path exists in either script.
- Contract and runbook require schema validation as gate.

## Proposed Solutions

### Option 1: Add JSON-Schema Validation In Both Entrypoints (Recommended)

**Approach:** Load `planningops/schemas/meta-plan-graph.schema.json` and validate contract input before orchestration/build.

**Pros:**
- Contract alignment
- Prevents invalid enum/pattern drift

**Cons:**
- Adds dependency/validation step

**Effort:** 3-5 hours

**Risk:** Low

---

### Option 2: Reuse Existing Local Validator Wrapper

**Approach:** Create one shared schema-validate helper and call from both scripts.

**Pros:**
- Single-source validation logic

**Cons:**
- Slight refactor overhead

**Effort:** 4-6 hours

**Risk:** Low

## Recommended Action

## Technical Details

**Affected files:**
- `planningops/scripts/build_meta_plan_graph.py`
- `planningops/scripts/meta_plan_orchestrator.py`
- `planningops/schemas/meta-plan-graph.schema.json`

## Acceptance Criteria

- [x] Runtime path fails on schema-invalid graph input
- [x] Strict mode returns non-zero on schema violations
- [x] Regression test includes invalid enum/pattern case

## Work Log

### 2026-03-04 - Resolution

**By:** Codex

**Actions:**
- Added runtime schema validation function (`validate_meta_graph_schema`) driven by `meta-plan-graph.schema.json`.
- Enforced schema validation in both `build_meta_plan_graph.py` and `meta_plan_orchestrator.py` before orchestration logic.
- Added schema-invalid regression cases in build/orchestrator contract tests.

**Validation:**
- `bash planningops/scripts/test_build_meta_plan_graph_contract.sh`
- `bash planningops/scripts/test_meta_plan_orchestrator_contract.sh`

### 2026-03-04 - Code Review Finding

**By:** Codex

**Actions:**
- Reviewed validation call path in build/orchestrator scripts.
- Compared implementation behavior against schema contract expectations.

**Learnings:**
- Strict mode currently protects structure/cycle but not full schema domain.
