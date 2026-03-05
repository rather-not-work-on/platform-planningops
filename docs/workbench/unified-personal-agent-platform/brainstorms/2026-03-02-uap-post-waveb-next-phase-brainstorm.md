---
title: UAP Post-Wave-B Next Phase Brainstorm
type: brainstorm
date: 2026-03-02
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next-phase priority after Wave B completion, balancing PlanningOps reliability proof, infra onboarding, and Monday/NanoClaw architecture shaping.
topic: uap-post-waveb-next-phase
---

# UAP Post-Wave-B Next Phase Brainstorm

## What We're Building
Wave B 완료 이후의 "다음 우선순위 체계"를 고정한다.  
목표는 세 가지다.
- PlanningOps가 실제로 안정 운영 가능한지 검증한다.
- LiteLLM/LangFuse/NanoClaw 등 인프라/에이전트 기반을 Monday 수행 관점에서 정렬한다.
- 과도한 동시 추진을 막고, 단계별 게이트로 리스크를 제어한다.

즉, 지금부터는 "기능 추가"보다 "운영 가능성 + 구조 일관성"을 먼저 확정하는 단계다.

## Why This Approach
현재 상태는 정합성 기준에서 양호하다.
- PlanningOps 이슈/프로젝트는 정리 완료
- Project field schema 검증 통과
- refactor hygiene 단일/멀티레포 루프 존재

이 시점에서 가능한 접근은 3가지다.

### Approach A: PlanningOps Reliability First
- 2~3주 동안 PlanningOps 루프 신뢰성 증명(비정기 Kanban pull 실행, 재현성, 알람/리포트)만 집중

Pros
- 실패 전파 위험 최소화
- 나중 단계 의사결정 정확도 상승

Cons
- Monday 기능 체감 진척이 느려 보임
- 인프라 세팅이 뒤로 밀림

### Approach B: Monday/Infra First
- LiteLLM/LangFuse/NanoClaw + Monday 실행 기능을 먼저 밀어붙임

Pros
- 빠른 데모/제품 체감
- 기능 중심 동기 부여

Cons
- 계획/계약 정합성 흔들릴 가능성
- 재작업 비용 증가 위험

### Approach C (Recommended): Two-Track with Hard Gates
- Track 1: PlanningOps 운영 신뢰성 증명
- Track 2: Monday/Infra 설계·프로토타입
- 단, `Track 1 Exit Gate` 통과 전에는 Track 2를 "구조/프로토타입" 범위로 제한

Pros
- 속도와 안정성 균형
- 과도한 병렬개발 방지
- 의사결정 타이밍을 게이트로 명확히 제어

Cons
- 운영 규율이 필요
- 게이트 정의/측정 비용이 있음

추천은 C다. 지금 단계에서 YAGNI를 지키면서도 Monday 실행력을 잃지 않는 최적점이다.

## Key Decisions
- 다음 단계 운영 모델은 `Two-Track + Hard Gate`로 고정한다.
- `Hard Gate`는 `Track 1 Exit Gate`를 의미하며, 최소 판정 근거는 `uap-docs.sh check --profile all` 통과 + Project schema 검증 통과 + Track 1 KPI 증빙으로 둔다.
- Track 1(PlanningOps Reliability)이 `Track 1 Exit Gate` 통과 전에는 Track 2(Monday/Infra)를 프로토타입 범위로 제한한다.
- 멀티레포 refactor hygiene는 비정기 Kanban pull 기반으로 운영하되, 큐 상위 항목만 이슈화한다.
- NanoClaw/기존 에이전트 코드는 즉시 재작성하지 않고 "분석 -> 적합 구조 설계 -> 최소 통합" 순서로 진행한다.

### Priority Order (WHAT Level)
1. PlanningOps 운영 신뢰성 증명(반복 실행 안정화)
2. Monday 중심 목표/사용자 흐름 재정의(제품 관점)
3. LiteLLM/LangFuse/NanoClaw 기반 실행 토폴로지 확정
4. 기존 에이전트 코드(NanoClaw 포함) 분석 및 target architecture 결정
5. 통합 프로토타입 -> 정식 구현 플랜 전환

## Resolved Questions
- 지금 우선순위는 "새 기능 추가"보다 "운영 가능성과 구조 정합성"이 맞다.
- 스프린트보다 Kanban 기반 비정기 실행 모델을 유지한다.
- PlanningOps와 Monday를 분리 운영하되, 게이트 기반으로 연결 강도를 올린다.
- 멀티레포 일관성은 공통 계약+매트릭스 실행기로 유지한다.
- Foundation Gate(A~G)와 Sync Gate(A~F)는 혼용하지 않으며, 본 문서의 `Hard Gate`는 Track 1 운영 신뢰성 게이트로 해석한다.

## Open Questions
- 없음 (현 시점에서는 planning 단계로 진행 가능한 수준으로 결정됨)

## Next Steps
1. `/prompts:workflows-plan`에서 Track 1/Track 2를 병렬이 아닌 gate-sequenced backlog로 상세화
2. Track 1의 운영 신뢰성 KPI(루프 성공률, 재시도율, drift 수렴시간) 확정
3. Track 2의 Monday 목표 시나리오(핵심 UX 1~2개) 고정
4. NanoClaw/기존 에이전트 코드 분석 산출물 포맷(입력/출력/계약 적합성 체크리스트) 정의
5. LiteLLM/LangFuse 로컬 운영 기준과 OCI 마이그레이션 경계 문서화
6. `Track 1 Exit Gate` fail/reopen 시 재계획 트리거(조건/승인자/타임박스) 명시
