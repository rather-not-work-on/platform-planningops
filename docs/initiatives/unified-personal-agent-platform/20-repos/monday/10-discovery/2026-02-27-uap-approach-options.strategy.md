---
doc_id: uap-approach-options
title: UAP Implementation and Verification Approach Options
doc_type: strategy
domain: discovery
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-plan-options
tags:
  - uap
  - strategy
  - alpha-beta-gamma
  - execution
summary: Compares Alpha, Beta, Gamma execution strategies and defines a blended recommendation path.
related_docs:
  - ./2026-02-27-uap-core.brainstorm.md
  - ./2026-02-27-uap-failure-simulation.simulation.md
  - ../30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
---

# Plan Options for Implementation and Verification

## Global Precondition
- P1 이슈(상태 vocabulary, idempotency, completion evidence)가 문서 계약에서 해소되기 전 구현 착수 금지

## Option Alpha: Contract-First Strict (Recommended)
설명: 계약과 정책 게이트를 먼저 잠그고 구현은 최소 루프부터 확장한다.

단계:
1. contracts(lifecycle/handoff/result/o11y) 고정
2. orchestrator + ralph-loop 최소 연동
3. nanoclaw 단일 메인 에이전트 연결
4. provider adapters 순차 추가
5. messaging/scheduler 연결

장점:
- 독립성/캡슐화 보존에 가장 강함
- 장기 유지보수 리스크 최소

단점:
- 초기 가시 기능이 느리게 보일 수 있음

적합:
- "NanoClaw식 핵심 유지"를 최우선으로 둘 때

## Option Beta: Vertical Slice Fast Feedback
설명: 단일 사용자 플로우를 끝까지 빠르게 붙인 뒤 계약을 강화한다.

단계:
1. 한 미션 플로우(E2E) 우선 연결
2. observability 최소 연결
3. 병목/실패 분석 후 계약 보강

장점:
- 데모 속도 빠름
- 사용자 피드백 빨리 획득

단점:
- 경계 누수가 생기면 이후 수정 비용 큼

적합:
- 매우 빠른 실사용 검증이 최우선일 때

## Option Gamma: Provider-Agnostic First
설명: provider 편차를 먼저 제어하기 위해 provider 계약/회귀를 선행한다.

단계:
1. provider invocation/result 계약 확정
2. codex/claude/local LLM 교차 벤치
3. 이후 planner/executor/orchestrator 연결

장점:
- 다중 provider 전략 안정성 확보

단점:
- 핵심 루프 검증이 늦어짐

적합:
- provider 락인 회피가 절대 목표일 때

## Recommendation
- 기본은 `Option Alpha`
- 단, Alpha 단계 2 완료 시점에 Beta식 E2E smoke를 삽입해 현실 검증을 빠르게 수행
- Gamma 요소는 Alpha 단계 4에서 병렬 반영
- 즉, `Alpha core + Beta feedback + Gamma provider hardening`의 혼합 경로를 표준으로 삼는다.

## Must-Pass Gates by Option
- Alpha: 계약/정책/경계 게이트 통과가 전진 조건
- Beta: 사용자 플로우 성공만으로 전진 금지, 계약 회귀를 동반
- Gamma: provider 회귀 통과만으로 전진 금지, executor 통합 안정성 동시 검증

## Critique and Counter-Critique
- 비판: Alpha는 느리다.
- 반박: 독립 모듈 전략에서 계약 선행 없이 빠른 구현은 재작업 비용을 키운다.
- 결론: Alpha를 기본으로 하되 Beta smoke를 조기에 삽입해 속도/안정성 균형을 맞춘다.
