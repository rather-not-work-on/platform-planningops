---
title: audit: NanoClaw Fit Assessment and Adapter Strategy
type: audit
date: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Assesses NanoClaw fit for monday orchestration and defines adapter-first integration strategy for Track 2.
---

# audit: NanoClaw Fit Assessment and Adapter Strategy

## Objective
NanoClaw 관련 기능을 재작성 없이 재사용/적응/보류로 분류해 monday 오케스트레이션 경계와 맞춘다.

## Input Dependencies
- `docs/workbench/unified-personal-agent-platform/brainstorms/monday-target-ux-scenarios.md`
- `docs/workbench/unified-personal-agent-platform/audits/infra-profile-boundary-map.md`
- `docs/workbench/unified-personal-agent-platform/audits/langfuse-boundary-map.md`

## Fit Matrix
| area | decision | reason | action |
|---|---|---|---|
| goal decomposition (`nanoclaw core`) | reuse | monday bounded context C와 의미가 일치 | adapter로 연결 |
| loop execution control | adapt | ralph-loop와 역할 중첩 가능성 | interface 경계로 분리 |
| provider invocation details | defer | provider_gateway가 이미 책임 소유 | monday direct coupling 금지 |
| observability emission | adapt | LangFuse continuity 요구 존재 | o11y-client-adapter 경유 |
| task scheduler internals | defer | Track 2 범위는 contract freeze 우선 | readiness packet 이후 |

## Adapter Strategy
1. `nanoclaw core`는 planning/delegation 계약만 노출한다.
2. `orchestrator`는 `PlannerPort`/`SubtaskPort`로만 NanoClaw를 호출한다.
3. provider/o11y는 외부 gateway 경계를 유지한다.
4. 내부 구현 용어는 `Worker`, 외부 계약 용어는 `Executor`를 유지한다.

## Anti-Bloat Guardrails
- 신규 공통 유틸 추가 금지(재사용 근거 2개 이상 전까지)
- NanoClaw 내부 DTO를 외부 계약 타입으로 직접 사용 금지
- Track 2에서는 adapter skeleton까지만 허용, 기능 확장은 Gate 이후

## Risks and Mitigations
- risk: NanoClaw 책임 범위 팽창
  - mitigation: planner/delegator 계약 외 직접 의존 차단
- risk: orchestrator-ralph loop 책임 중복
  - mitigation: `ExecutorPort` 단일 진입점 강제
- risk: profile/O11y 결합으로 테스트 불안정
  - mitigation: local-first smoke + profile override 테스트 분리

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-03T16:11:00+09:00
