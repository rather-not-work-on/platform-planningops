---
title: refactor: Kanban-Aligned Loop Selector and Contract Hardening
type: plan
date: 2026-03-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Aligns loop operations with non-periodic Kanban policy and hardens loop_profile contract boundaries across docs, contracts, and project schema validation.
---

# refactor: Kanban-Aligned Loop Selector and Contract Hardening

## Overview
`platform-planningops`의 loop 운영 문서를 "비정기 Kanban pull" 원칙에 정확히 맞추고, `loop_profile`을 C1/C2/C8 및 GitHub Project schema에서 일관되게 다루도록 계약을 고정한다.

이번 계획은 구현 자체보다 "실행 전 정합성 고정"에 초점을 둔다. 목표는 에이전트가 같은 맥락에서 같은 선택을 하게 만들고, 재계획 트리거가 흔들리지 않도록 하는 것이다.

## Context and Research Consolidation
### Found brainstorm context
- Found brainstorm from `2026-03-01`: `uap-loop-selection-policy`
- Decision reuse:
  - loop catalog(`L1~L5`) 유지
  - selector 정책 유지
  - Kanban pull + WIP 운영 유지
  - 다음 우선순위는 `loop_profile` 계약/필드 정합

### Local references
- plan baseline:
  - `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md`
- contracts:
  - `planningops/contracts/problem-contract.md`
  - `planningops/contracts/requirements-contract.md`
- project schema/config:
  - `planningops/config/project-field-ids.json`
  - `planningops/scripts/validate_project_field_schema.py`

### External research decision
- Skip external research.
- Reason: 현재 과제는 외부 프레임워크 신규 도입이 아니라 내부 계약/검증 체계 정합성 강화다. 레포 내 기준 문서와 스크립트가 충분히 구체적이다.

## Problem Statement / Motivation
리뷰 결과 핵심 문제는 2개다.

1. 비정기 Kanban 운영과 시간박스 표현 충돌
- 현재 문서가 `1주/2주`, `주 10회`와 같은 시간 기준을 포함해 비정기 pull 정책과 충돌할 수 있다.
- 결과적으로 loop 종료조건보다 일정 추정이 우선 해석될 위험이 있다.

2. `loop_profile` 계약 경계 미고정
- `loop_profile` 필드 확장안은 있지만 C1/C2/C8 어디에 어떤 키/검증으로 고정할지 명확하지 않다.
- 문서/스크립트/프로젝트 필드가 부분적으로만 연결되어 drift 가능성이 남아 있다.

## Proposed Solution
다음 4개 축으로 정리한다.

1. 시간 기반 표현 제거 -> 이벤트 기반 진행 기준으로 전환
2. `loop_profile` 계약 소유 경계 고정(C1/C2/C8)
3. GitHub Project schema/validator에 `loop_profile` 필수 검증 추가
4. selector/verification/replan trigger 전이로그를 계약 테스트로 고정

## Scope
### In scope
- deepened plan 문서의 시간박스 표현 정리
- `loop_profile` 계약 맵 정의 문서화(C1/C2/C8 책임 분리)
- project field schema와 validator 요구사항 업데이트 계획
- acceptance criteria를 이벤트/증빙 중심으로 재정의

### Out of scope
- 실제 런타임 엔진 대규모 리팩터링
- 새로운 loop 유형 추가(`L6+`)
- multi-initiative generalization

## SpecFlow Analysis
### User flow overview
1. Planner updates docs/contracts -> card remains `Todo`.
2. Runner pulls eligible card (`Status=Todo`, allowed `workflow_state`).
3. Selector assigns `loop_profile`.
4. Loop executes and emits artifacts.
5. Verifier decides verdict and trigger flags.
6. Feedback updates issue + project fields.
7. If trigger condition met, system routes to `L5` and records replan evidence.

### Flow permutations matrix
| Case | Entry state | Primary signal | Selected loop | Expected result |
|---|---|---|---|---|
| A | `ready-contract` | missing input | `L1` | contract gap resolved or blocked with reason |
| B | `ready-contract` | high uncertainty | `L2` | simulation evidence complete |
| C | `ready-implementation` | stable acceptance | `L3` | tests/evidence pass |
| D | cross-repo/drift | projection mismatch | `L4` | reconcile convergence |
| E | repeated fail/inconclusive | trigger threshold reached | `L5` | replan issue/decision artifact |

### Critical gaps to close
- `loop_profile` 미기입 카드 처리 정책 필요(deny vs default).
- `L5` 진입 후 원복 정책 필요(`blocked -> ready-contract` 조건).
- validator 실패 시 동작 정책 필요(hard fail vs report-only in dry-run).

### Default assumptions (if unresolved)
- `loop_profile`가 비어 있으면 selector가 계산하여 즉시 기록한다.
- `L5` 완료 조건은 "blocker 해소" 또는 "replan issue 연결 완료" 중 하나로 본다.
- apply 모드에서는 schema mismatch를 hard fail로 본다.

## Technical Approach
## Architecture
- Source of truth: `docs/workbench` plan + `planningops/contracts/*`
- Enforcer: `planningops/scripts/validate_project_field_schema.py`
- Projection surface: GitHub Project fields in `planningops/config/project-field-ids.json`

### Contract boundary mapping (C1/C2/C8)
- C1 (Run lifecycle):
  - run-level `loop_profile`, `selection_reason`, `selected_at_utc`
  - 상태 전이와 trigger detection 입력
- C2 (Subtask handoff):
  - handoff payload에 `loop_profile` 상속 규칙
  - 하위 실행에서 profile override 허용 여부
- C8 (Plan-to-GitHub projection):
  - `loop_profile` -> Project field mapping
  - `last_verdict/last_reason/replanning_triggered`와 함께 projection consistency 검증

### Required update targets
1. `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md`
2. `planningops/contracts/requirements-contract.md`
3. `planningops/config/project-field-ids.json`
4. `planningops/scripts/validate_project_field_schema.py`
5. `planningops/quality/loop-verification-checklist.md`

## Implementation Phases
### Phase 1: Policy normalization (event-based)
- 시간박스 표현을 이벤트/증빙 조건으로 치환
- `주 n회` 같은 cadence 문구 제거
- 결과물: policy diff + updated acceptance criteria

### Phase 2: Contract hardening (`loop_profile`)
- C1/C2/C8 책임과 필수 키 정의
- selector input/output 최소 스키마 정의
- 결과물: contract update draft + mapping table

### Phase 3: Schema and validator alignment
- `project-field-ids.json`에 `loop_profile` 필드 카탈로그 정의
- `validate_project_field_schema.py`의 required field check 확장
- 결과물: schema validation report format update

### Phase 4: Trigger and quality gate alignment
- `inconclusive x2`, `same reason x3` trigger를 quality checklist에 명시
- verifier 산출물 요구사항(`L1~L5`)과 acceptance criteria 연결
- 결과물: gate checklist update draft

## Acceptance Criteria
### Functional
- [x] plan 문서에서 시간 기반 진행 기준이 제거되고 이벤트 기반 기준으로 대체된다.
- [x] `loop_profile` 계약 소유가 C1/C2/C8에 분리 정의된다.
- [x] project schema 검증 기준에 `loop_profile` 필수 항목이 포함된다.
- [x] trigger 조건(`inconclusive x2`, `same reason x3`)이 재계획 절차와 1:1로 연결된다.

### Non-functional
- [x] 동일 입력에서 selector 결과(`loop_profile`)가 결정론적으로 재현된다.
- [x] dry-run/apply 모두에서 schema mismatch 처리 정책이 명시된다.
- [x] 문서/계약/검증 스크립트 사이 용어 불일치가 없다(`Executor`, `Worker`, `loop_profile`).

## Success Metrics
- `loop_profile_missing_rate` = 0%
- `selector_reproducibility_failures` = 0 per verification replay set
- `replan_trigger_without_evidence` = 0
- `status-workflow-loop mismatch` violations trend 감소

## Dependencies & Risks
### Dependencies
- 기존 project 필드 운용 계약 (`component`, `initiative`, `target_repo`, `workflow_state`)
- requirements/failure taxonomy 계약 유지

### Risks
- validator strict mode 도입 시 기존 카드가 대량 fail 가능
- `loop_profile` 옵션 정의와 실제 운영 용어가 어긋날 가능성
- 문서만 먼저 변경되고 스크립트가 늦게 반영되는 시차 리스크

### Mitigations
- 도입 순서 고정: doc -> contract -> schema -> validator -> gate
- initial rollout은 report-only로 1회 관찰 후 hard fail 전환
- migration note로 기존 카드 backfill 절차 명시

## References & Research
### Internal references
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-01-uap-loop-selection-policy-brainstorm.md`
- `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md`
- `planningops/contracts/problem-contract.md`
- `planningops/contracts/requirements-contract.md`
- `planningops/config/project-field-ids.json`
- `planningops/scripts/validate_project_field_schema.py`

## Next Actions
1. 이 plan을 기준으로 작업 이슈를 4개(Phase 1~4)로 분할 등록
2. `loop_profile` 필드 카탈로그 데모 생성 및 validator 확장안 검증
3. 문서 리뷰 1회 후 `workflows-work`로 실행 전환
