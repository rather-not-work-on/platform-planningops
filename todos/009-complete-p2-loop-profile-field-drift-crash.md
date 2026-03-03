---
status: complete
priority: p2
issue_id: "009"
tags: [code-review, reliability, github-project, planningops]
dependencies: []
---

# loop_profile 필드 드리프트 시 런너 비정상 종료

## Problem Statement

`loop_profile` 필드 옵션이 Project에서 변경/누락되면 `issue_loop_runner`가 예외를 발생시키고 즉시 종료됩니다.
이 경우 실패가 `feedback_failed` 같은 계약 코드로 수렴하지 않고, 실행 상태 기록도 불완전해질 수 있습니다.

## Findings

- `ensure_single_select_field`는 옵션 누락 시 `RuntimeError`를 throw 합니다.
- 호출부에서 예외를 처리하지 않아 프로세스가 중단됩니다.
- 실패 분류/재시도 정책(`failure-taxonomy`)과 연결되지 않습니다.

근거:
- `planningops/scripts/issue_loop_runner.py:154`
- `planningops/scripts/issue_loop_runner.py:165`
- `planningops/scripts/issue_loop_runner.py:432`

## Proposed Solutions

### Option 1: 예외를 feedback_failed로 강등 처리 (권장)

**Approach:**
필드 조회/수정 예외를 잡아 `feedback_failed`로 기록하고, 결과 JSON/transition-log를 남긴 뒤 종료 코드를 정책적으로 반환합니다.

**Pros:**
- 실패가 계약된 reason code로 수렴
- 운영 가시성/재시도 자동화 유지

**Cons:**
- 에러 핸들링 코드 추가

**Effort:** 2-4 hours

**Risk:** Low

---

### Option 2: 사전 스키마 검증 강제

**Approach:**
`issue_loop_runner` 시작 시 schema validator를 선실행해 mismatch 시 즉시 종료합니다.

**Pros:**
- 명확한 fail-fast
- 런타임 중간 실패 감소

**Cons:**
- 실행 시간 증가
- 운영 중 스키마 일시 drift에 더 취약

**Effort:** 2-3 hours

**Risk:** Medium

## Recommended Action

완료. feedback 단계의 필드 드리프트/옵션 누락 예외를 `feedback_failed`로 표준화해 런너 크래시 없이 증거와 결과를 남기고 종료하도록 수정했다.

## Technical Details

Affected files:
- `planningops/scripts/issue_loop_runner.py`
- `planningops/contracts/failure-taxonomy-and-retry-policy.md`

## Resources

- Related script: `planningops/scripts/validate_project_field_schema.py`

## Acceptance Criteria

- [x] Project field drift가 발생해도 런너가 예외 크래시 대신 계약된 reason code를 기록한다.
- [x] `last-run.json`과 transition evidence가 항상 생성된다.
- [x] feedback 단계 실패가 retry/escalation 정책과 연동된다.

## Work Log

### 2026-03-01 - Review finding capture

**By:** Codex

**Actions:**
- field 옵션 검증 코드와 호출부 예외 흐름 점검
- 예외 미처리 경로 확인
- 운영 영향 및 완화안 정리

**Learnings:**
- 외부 시스템(Project schema)에 의존하는 단계는 예외를 reason code로 표준화해야 운영 자동화가 안정적임

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/issue_loop_runner.py`의 feedback 적용 블록을 `try/except`로 감싸 예외를 `feedback_failed`로 강등 처리했다.
- feedback 실패 시 `payload.reason_code=feedback_failed`, transition-log 이벤트(`feedback.failed`), watchdog 실패 이벤트, `last-run.json`을 모두 기록하도록 보강했다.
- lock release 및 checkpoint clear를 실패 경로에서도 보장하도록 정리했다.

**Learnings:**
- 런타임 외부 의존 단계는 “예외 전파”보다 “계약된 실패 코드+증거 기록”이 운영 복구에 훨씬 유리하다.

## Notes

- apply 모드와 dry-run 모드의 처리정책을 분리해 정의하면 운영 충격을 줄일 수 있음.
