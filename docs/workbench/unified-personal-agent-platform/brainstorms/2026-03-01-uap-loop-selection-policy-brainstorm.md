---
title: UAP Loop Selection Policy Brainstorm
type: brainstorm
date: 2026-03-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Analyzes current Ralph Loop behavior and defines a situation-driven loop catalog with entry and exit rules.
topic: uap-loop-selection-policy
---

# UAP Loop Selection Policy Brainstorm

## What We're Building
현재의 단일 Ralph Loop 중심 운영을 유지하되, 문제 유형과 불확실성 수준에 따라 서로 다른 루프를 선택하는 운영 정책을 정의한다.

핵심 목표는 다음이다.
- 루프 시작 전에 판단 기준을 고정한다.
- 같은 유형 문제에 같은 루프를 반복 적용한다.
- 종료 조건과 증빙 경로를 루프별로 분리해 재작업을 줄인다.

즉, "모든 문제를 한 루프로 해결"이 아니라 "문제 유형에 맞는 루프를 선택해 수렴시키는 체계"를 만든다.

## Why This Approach
현재 계약/스크립트 기준으로는 `issue_loop_runner -> ralph_loop_local -> verify_loop_run` 경로가 강하게 구현되어 있다.  
이 방식은 `Todo` 큐 처리와 결과 반영에는 효과적이지만, 요구사항 모호성 해소/계약 경계 정리/테스트 수렴 같은 성격이 다른 문제까지 동일 루프로 처리하면 비용이 커진다.

검토한 접근은 3가지다.

### Approach A: Single Universal Loop 유지
- 모든 항목을 기존 Ralph Loop 하나로 처리

Pros
- 단순함, 운영 표면 최소
- 현재 자산 재사용 최대

Cons
- 문제 유형별 최적화 부재
- 초기 불확실성 단계에서 불필요한 반복 증가

### Approach B (Recommended): Loop Catalog + Selection Policy
- 루프를 4~5개 유형으로 고정하고, 카드 조건으로 선택

Pros
- 문제 유형별 진입/종료 기준 명확
- 검증 산출물과 재계획 트리거를 루프별로 분리 가능
- Kanban pull 정책과 자연스럽게 결합

Cons
- 초기 정책 문서화/학습 비용
- selector 규칙 검증 자동화 필요

### Approach C: Adaptive Meta-Loop (자가학습 선택)
- 실행 결과를 기반으로 루프 선택 규칙을 동적으로 변경

Pros
- 장기적으로 자동 최적화 가능

Cons
- 현재 단계에서 과도한 복잡도
- 오판 시 오류 전파 위험 증가

추천은 B다. 이유는 현재 목표(불확실성/판단 요소/계약 불일치 최소화)를 가장 직접적으로 해결하면서도 YAGNI를 지킬 수 있기 때문이다.

## Key Decisions
- 운영 모델은 `Kanban + Loop Selector`로 고정한다.
- 기본 intake/pull 규칙(`Status=Todo`, `workflow_state in {ready-contract, ready-implementation}`)은 유지한다.
- loop 선택은 "카드 상태 + 리스크 신호 + 산출물 결손"의 조합으로 결정한다.
- Phase 1 루프 카탈로그는 최소 5개로 제한한다.

### Phase 1 Loop Catalog
1. `L1 Contract-Clarification Loop`
   - 언제: 목표/요구사항/완료조건이 모호할 때
   - 종료: problem/requirements contract가 충족되고 미결정 항목이 사라질 때
2. `L2 Simulation Loop`
   - 언제: 구현 전 경우의 수/실패 전이를 확인해야 할 때
   - 종료: 실패 시나리오와 반박 루프가 문서화되고 gate 가정이 고정될 때
3. `L3 Implementation-TDD Loop`
   - 언제: 코드 동작/회귀 위험을 직접 줄여야 할 때
   - 종료: 테스트 추가 + 테스트 통과 + 검증 리포트 통과
4. `L4 Integration-Reconcile Loop`
   - 언제: multi-repo/project field 동기화 정합을 맞춰야 할 때
   - 종료: dry-run/apply/reconcile가 수렴하고 drift가 허용 범위 이내일 때
5. `L5 Recovery-Replan Loop`
   - 언제: `inconclusive` 반복, reason_code 반복, 권한/의존성 block이 누적될 때
   - 종료: block 해소 또는 replan issue/ADR 생성으로 경로가 다시 고정될 때

### Situation-to-Loop Defaults
- 요구사항 모호/컨텍스트 결손: `L1 -> L2`
- 계약 변경/경계 불안정: `L2 -> L4`
- 버그/회귀 수정: `L3`
- 동기화/프로젝션 불일치: `L4`
- 반복 실패/하드스톱: `L5`

## Resolved Questions
- 비정기 실행 운영 방식: 스프린트보다 Kanban이 적합하다.
- 루프 선택 기준 우선순위: 속도보다 정합성과 재현성 우선.
- 시뮬레이션 역할: 구현 전 pseudo-code 수준 검증을 필수 단계로 둔다.

## Open Questions
- 없음 (다음 단계는 선택 정책을 계약/필드 스키마에 반영하는 계획 수립으로 충분)

## Next Steps
1. GitHub Project/contract에 `loop_profile` 필드를 추가해 루프 선택 신호를 명시한다.
2. `C1/C2/C8`에 loop_profile 매핑 규칙(입력/프로젝션/검증)을 확장한다.
3. `issue_loop_runner`에 loop selector 훅을 추가해 `L1~L5` 분기 실행을 지원한다.
4. 루프별 필수 증빙 체크리스트(`required artifacts by loop`)를 분리 정의한다.
5. 2주 파일럿에서 루프별 lead time/재시도율/재계획율을 측정해 카탈로그를 재조정한다.
