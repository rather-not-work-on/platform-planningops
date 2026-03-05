---
title: brainstorm: Monday Target UX Scenarios
type: brainstorm
date: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Freezes two Monday target UX scenarios for Track 2 prototype work before implementation.
---

# brainstorm: Monday Target UX Scenarios

## Objective
Track 2에서 구현 전에 Monday 사용자 경험을 2개 시나리오로 고정한다.

## Non-Goals
- 구현 코드 작성
- 추가 시나리오 확장
- UI/브랜딩 결정

## Frozen Scenario 1: Issue-to-Loop Execution
### User Intent
사용자는 Project 카드의 `Todo + ready-contract|ready-implementation` 상태 작업을 하나씩 안정적으로 실행하고 결과를 본다.

### Input Contract
- Project fields: `Status`, `workflow_state`, `execution_order`, `depends_on`, `target_repo`, `component`, `loop_profile`
- Issue body metadata: `plan_item_id`, `primary_output`

### System Behavior
1. Intake가 pull 조건을 만족하는 카드만 선택한다.
2. Selector가 `loop_profile`을 결정한다.
3. Runner가 산출물과 검증 리포트를 생성한다.
4. Feedback가 issue comment + project 필드를 갱신한다.

### User-Visible Output
- Issue comment: `verdict`, `reason_code`, evidence 경로
- Project card: `Status`, `workflow_state`, `loop_profile`, `last_verdict`, `last_reason`

## Frozen Scenario 2: Failure-to-Replan Recovery
### User Intent
사용자는 반복 실패에서 자동으로 멈추고 재계획 카드/근거가 남는지 확인한다.

### Trigger Contract
- `same_reason_x3`
- `inconclusive_x2`

### System Behavior
1. Escalation gate가 trigger를 감지한다.
2. 현재 루프를 auto-pause 처리한다.
3. `blocked` 상태와 `L5 Recovery-Replan`로 전환한다.
4. replan decision artifact를 생성한다.

### User-Visible Output
- `planningops/artifacts/replan/issue-<n>-<timestamp>.md`
- `planningops/artifacts/validation/transition-log.ndjson` 전이 이벤트

## Freeze Boundaries
- 이번 freeze에서 Monday UX는 위 2개만 canonical prototype 대상으로 인정한다.
- 신규 UX 요청은 Track 2 completion 이후 별도 카드로 분리한다.
- Scenario 1/2의 입력 필드 계약은 변경 금지(변경 시 replan 경로 필수).

## Dependencies
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`
- `planningops/contracts/requirements-contract.md`
- `planningops/contracts/escalation-gate-contract.md`

## Validation Checklist
- [x] scenario count fixed to 2
- [x] trigger rules aligned to escalation contract
- [x] user-visible outputs defined

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-03T16:10:00+09:00
