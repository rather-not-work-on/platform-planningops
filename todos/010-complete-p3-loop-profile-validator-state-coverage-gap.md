---
status: complete
priority: p3
issue_id: "010"
tags: [code-review, validation, planningops, quality]
dependencies: []
---

# loop_profile-validator 상태 커버리지 불균형

## Problem Statement

validator는 `ready-contract`, `ready-implementation`, `blocked`에 대해서만 `loop_profile` 정합을 검사하고, `backlog`, `in-progress`, `review-gate`, `done`은 허용 범위 검증이 없습니다.
운영 규칙이 확대될 경우 상태별 drift가 늦게 발견될 수 있습니다.

## Findings

- 정합성 검사 분기가 일부 상태에만 적용됩니다.
- 현재는 필수값 존재만 검사하므로 상태-프로파일 부정합이 통과할 수 있습니다.

근거:
- `planningops/scripts/validate_project_field_schema.py:251`
- `planningops/scripts/validate_project_field_schema.py:253`

## Proposed Solutions

### Option 1: 상태별 기대 프로파일 매트릭스 전면 적용 (권장)

**Approach:**
모든 `workflow_state`에 허용 프로파일 집합을 선언하고 validator에서 공통 검증합니다.

**Pros:**
- drift 탐지 정확도 향상
- 규칙이 코드로 명시됨

**Cons:**
- 초기에 false positive 조정 필요

**Effort:** 2-3 hours

**Risk:** Low

---

### Option 2: 현재 범위 유지 + 리포트 전용 경고 추가

**Approach:**
정합성 강제는 유지하되, 미커버 상태에서는 warning/info를 리포트에 추가합니다.

**Pros:**
- 운영 충격 최소
- 점진 도입 용이

**Cons:**
- 강제력이 낮음

**Effort:** 1-2 hours

**Risk:** Low

## Recommended Action

완료. 상태별 `loop_profile` 허용 매트릭스를 전면 선언하고 validator에서 공통 검증하도록 변경했다.

## Technical Details

Affected files:
- `planningops/scripts/validate_project_field_schema.py`

## Resources

- Related config: `planningops/config/project-field-ids.json`

## Acceptance Criteria

- [x] 모든 상태에 대해 허용 `loop_profile` 규칙이 정의되거나, 미정 상태가 명시적으로 경고된다.
- [x] validator report에 상태-프로파일 정합성 결과가 일관되게 반영된다.

## Work Log

### 2026-03-01 - Review finding capture

**By:** Codex

**Actions:**
- validator 분기 로직 점검
- 상태별 커버리지 격차 확인
- 점진/강제 두 가지 개선안 정리

**Learnings:**
- schema strictness를 단계적으로 올릴 때는 warning->fail 전환 기준을 함께 문서화하는 것이 효과적임

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/validate_project_field_schema.py`에 `WORKFLOW_LOOP_PROFILE_MATRIX`를 추가해 `backlog/in-progress/review-gate/done` 포함 전 상태 커버리지를 선언했다.
- `expected_loop_profiles_for_workflow_state` 함수로 규칙 해석을 통일하고, 미정 상태는 `WORKFLOW_STATE_UNCOVERED` info로 보고하도록 개선했다.
- `planningops/scripts/test_validate_project_field_schema_matrix.sh`를 추가해 상태 매트릭스 계약을 회귀 테스트로 고정했다.

**Learnings:**
- 상태-프로파일 규칙은 코드 상수로 고정해야 품질 검증의 예측 가능성이 높아진다.

## Notes

- 현재 변경의 merge blocker는 아니므로 P3로 분류.
