---
doc_id: uap-module-refactor-hygiene-loop-plan
title: feat: UAP Module Refactor Hygiene Loop Plan
doc_type: execution-plan
domain: planning
status: active
date: 2026-03-01
updated: 2026-03-01
initiative: unified-personal-agent-platform
tags:
  - uap
  - refactor
  - module
  - dependency
  - hygiene
  - kanban
summary: Defines a periodic, bounded module-level refactor loop that enforces external dependency cleanup before internal dependency cleanup with mandatory context-pruning checkpoints.
related_docs:
  - ../AGENT-START.md
  - ./2026-02-28-uap-topology-priority-expansion.execution-plan.md
  - ./uap-github-planningops-sync.execution-plan.md
  - ../40-quality/uap-planningops-tradeoff-decision-framework.quality.md
  - ../../../workbench/unified-personal-agent-platform/plans/2026-03-01-refactor-kanban-loop-selector-contract-hardening-plan.md
---

# feat: UAP Module Refactor Hygiene Loop Plan

## Objective
모듈 단위 리팩토링을 주기적으로 수행하되, 과도한 변경과 문맥 오염을 방지하는 bounded loop를 운영 표준으로 고정한다.

핵심 원칙:
1. 외부 의존성 정리를 먼저 수행한다.
2. 내부 의존성 정리는 그 다음에 수행한다.
3. 작업 중간마다 정리 정돈(checkpoint)을 강제한다.

## Why This Is Needed
- 코딩 에이전트가 긴 문맥에서 연속 변경을 수행할 때, 초기 가정 오류가 누적 전파될 수 있다.
- 모듈 토폴로지를 관찰하지 않은 리팩토링은 스파게티 구조와 over-engineering을 강화한다.
- 레거시 제거와 인터페이스 통합은 일회성 작업이 아니라 반복 운영 작업이다.

## Execution Contract
### Input
- `planningops/config/refactor-hygiene-policy.json`
  - `scan_roots`
  - `include_extensions`
  - `exclude_dirs`
  - `max_modules_per_cycle`
  - `max_files_per_module`
  - `checkpoint_every_tasks`

### Analyzer
- script: `planningops/scripts/refactor_hygiene_loop.py`
- outputs:
  - `planningops/artifacts/refactor-hygiene/<run-id>/report.json`
  - `planningops/artifacts/refactor-hygiene/<run-id>/summary.md`
  - `planningops/artifacts/refactor-hygiene/latest.json`

### Queue Order (Mandatory)
1. `external_first`:
  - 불필요한 외부 의존성 제거
  - 버전/호환성 핀 정리
  - 모듈 경계 외부 호출 단순화
2. `internal_next`:
  - 모듈 간 방향성 정리
  - 순환 의존성 해소
  - 인터페이스 단순화 및 레거시 통합/제거

## Checkpoint Policy (Context Hygiene)
`checkpoint_every_tasks`마다 아래를 수행한다.
1. 현재 결정/가정/제약을 10줄 이내로 재요약
2. 이번 사이클과 무관한 TODO/문맥 제거
3. 다음 작업 전에 dependency topology를 다시 읽고 drift 여부 확인

## Kanban Integration
- 이 루프는 스프린트가 아니라 비정기 Kanban 보강 루프로 운영한다.
- 기본 pull 조건:
  - `Status=Todo`
  - `workflow_state in {ready-contract, ready-implementation}`
- 리팩토링 작업 카드는 `component=planningops`, `plan_lane=quality`를 권장한다.

## Git/Review Integration
- direct push 금지, PR-first 운영.
- 리팩토링 작업은 작은 단위 PR로 분할한다.
- PR 템플릿의 `Validation`에 analyzer report 경로를 포함한다.

## Periodic Cadence
1. manual run: 큰 변경 전/후 즉시 실행
2. scheduled run: 주 1회(월요일) 자동 실행
  - workflow: `.github/workflows/refactor-hygiene.yml`
3. event-driven run: 아래 트리거 발생 시 즉시 실행
  - `cycle_count` 급증
  - 특정 모듈 external deps 급증
  - same reason failure 반복으로 auto-pause 발생

## Definition of Done
1. analyzer report가 생성되고 queue가 `external_first -> internal_next` 순서를 만족한다.
2. 사이클 내 변경이 policy budget을 초과하지 않는다.
3. 체크포인트 기록이 남고, 다음 task 시작 전 재검증이 수행된다.
4. 레거시 제거/인터페이스 통합 변경은 영향 범위와 rollback 경로가 명시된다.
