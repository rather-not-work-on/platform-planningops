---
status: complete
priority: p2
issue_id: "008"
tags: [code-review, planningops, loop-selector, contracts]
dependencies: []
---

# loop_profile L2 경로 비도달 문제

## Problem Statement

`loop_profile` 카탈로그에 `L2 Simulation`이 정의되어 있지만, 현재 selector 구현에서는 사실상 `L2`가 선택되지 않습니다.
이로 인해 계약/문서에 선언된 루프 카탈로그와 실제 실행 동작이 불일치합니다.

## Findings

- `determine_loop_profile`는 `ready-contract`에서 항상 `L1`을 반환합니다.
- `L2`를 반환하는 분기 조건이 없습니다.
- 문서/계약은 `L1|L2` 선택 가능성을 전제로 정의되어 있습니다.

근거:
- `planningops/scripts/issue_loop_runner.py:193`
- `planningops/scripts/issue_loop_runner.py:199`
- `planningops/scripts/validate_project_field_schema.py:253`
- `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md:70`

## Proposed Solutions

### Option 1: Selector 입력 신호 확장 (권장)

**Approach:**
`ready-contract` 상태에서 `simulation_required` 또는 `uncertainty_level` 같은 카드/문맥 신호를 읽어 `L1`/`L2`를 분기합니다.

**Pros:**
- 문서/계약과 실행 동작이 일치
- 향후 룰 튜닝이 용이

**Cons:**
- 신호 정의와 backfill 필요

**Effort:** 3-5 hours

**Risk:** Medium

---

### Option 2: L2를 계획/계약에서 제거

**Approach:**
현재 구현에 맞춰 `L2`를 카탈로그에서 제외하고 `L1` 중심으로 단순화합니다.

**Pros:**
- 즉시 정합
- 구현 변경 최소

**Cons:**
- 시뮬레이션 전용 루프 전략 상실

**Effort:** 1-2 hours

**Risk:** Medium

## Recommended Action

완료. `ready-contract`에서 `simulation_required`/`uncertainty_level` 신호를 읽어 `L2 Simulation`으로 분기하도록 selector를 확장했다.

## Technical Details

Affected files:
- `planningops/scripts/issue_loop_runner.py`
- `planningops/contracts/requirements-contract.md`
- `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md`

## Resources

- Related change set: local working tree (2026-03-01 loop_profile hardening)

## Acceptance Criteria

- [x] `L2`를 선택할 수 있는 명시적 조건이 코드에 존재한다.
- [x] selector 단위 테스트에 `L2` 선택 케이스가 추가된다.
- [x] 계약/문서/검증 규칙이 selector 동작과 일치한다.

## Work Log

### 2026-03-01 - Review finding capture

**By:** Codex

**Actions:**
- selector 구현과 loop catalog 문서를 교차 검토
- `L2` 비도달 상태 확인
- 개선 옵션 2가지 정리

**Learnings:**
- 카탈로그 확장 시 코드 분기 신호 정의를 동시에 고정해야 drift를 줄일 수 있음

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/issue_loop_runner.py`에 `parse_selector_hints`를 추가해 issue body의 `simulation_required`, `uncertainty_level`을 파싱하도록 구현했다.
- `determine_loop_profile`를 확장해 `ready-contract`에서도 시뮬레이션 신호가 있으면 `L2 Simulation`을 반환하게 수정했다.
- `planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`에 `L2` 선택 회귀 케이스를 추가했다.

**Learnings:**
- 루프 카탈로그는 “정의만 존재”하면 드리프트가 생기므로, 선택 신호 파싱 규칙까지 계약으로 고정해야 안정적이다.

## Notes

- 구현 단순화를 택할 경우 문서/계약에서 L2 관련 서술 정리가 선행되어야 함.
