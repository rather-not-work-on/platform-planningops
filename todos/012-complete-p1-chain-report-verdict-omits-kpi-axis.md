---
status: complete
priority: p1
issue_id: "012"
tags: [code-review, reliability, reporting, gate, planningops]
dependencies: []
---

# Chain Report Verdict Omits KPI Axis and Can Misreport Gate Pass

Validation chain report can show `pass` while dry-run final gate verdict is `inconclusive` due to missing KPI evidence, creating contradictory gate signals.

## Findings

- `planningops/scripts/run_track1_gate_dryrun.py:236-244` computes `chain_report.verdict` from docs/schema/transition checks only.
- KPI axis is evaluated (`evaluate_kpi`) and used for dry-run verdict, but not included in chain report verdict.
- Observed artifact mismatch:
  - `planningops/artifacts/validation/track1-validation-chain-report.json` -> `"verdict": "pass"`
  - `planningops/artifacts/validation/track1-gate-dryrun-report.json` -> `"final_verdict": "inconclusive"`
- Impact: Operators may read wrong source and promote Track 2 prematurely.

## Proposed Solutions

### Option 1: Include KPI axis in chain report verdict

**Approach:** Compute `chain_report.verdict` using same final rule as dry-run final verdict.

**Pros:**
- Single truth model
- Eliminates contradictory status

**Cons:**
- Requires careful migration of current report consumers

**Effort:** Small

**Risk:** Low

---

### Option 2: Separate report semantics explicitly

**Approach:** Keep chain report scoped to technical checks, but rename verdict to `chain_verdict` and add `overall_gate_verdict` field.

**Pros:**
- Backward compatibility possible
- Makes semantics explicit

**Cons:**
- More fields and documentation burden

**Effort:** Small

**Risk:** Low

---

### Option 3: Deprecate chain verdict field

**Approach:** Remove `chain_report.verdict`; use only `track1-gate-dryrun-report.final_verdict` as canonical.

**Pros:**
- No ambiguity

**Cons:**
- Breaking change for existing dashboards/scripts

**Effort:** Medium

**Risk:** Medium

## Recommended Action

완료. chain report에 KPI 축을 포함하고 canonical verdict source를 `final_verdict`로 통일해 불일치 신호를 제거했다.

## Technical Details

**Affected files:**
- `planningops/scripts/run_track1_gate_dryrun.py:218-245`
- `planningops/artifacts/validation/track1-validation-chain-report.json`
- `planningops/artifacts/validation/track1-gate-dryrun-report.json`

## Resources

- `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`

## Acceptance Criteria

- [x] Chain report and gate dry-run report cannot disagree on overall gate outcome.
- [x] Canonical gate verdict source is documented.
- [x] Existing consumers updated or migration noted.
- [x] Test validates KPI-missing scenario produces consistent verdict fields.

## Work Log

### 2026-03-02 - Review Finding Created

**By:** Codex

**Actions:**
- Compared verdict construction paths in script.
- Verified artifact-level contradiction.
- Documented options to unify semantics.

**Learnings:**
- Parallel reports need explicit canonical ownership to avoid operational drift.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/run_track1_gate_dryrun.py`의 chain report에 `kpi_gate_validation`을 추가했다.
- `overall_gate_verdict`, `verdict`, `reasons`, `verdict_source`를 `final_verdict` 기준으로 동기화했다.
- KPI-missing 시나리오에서 chain/dryrun verdict 일치 여부를 회귀 테스트로 검증했다.

**Learnings:**
- 운영 보고서가 여러 개일 때는 canonical source 경로를 명시해야 해석 오차가 줄어든다.

## Notes

- Merge-blocking because this can yield false promotion decisions.
