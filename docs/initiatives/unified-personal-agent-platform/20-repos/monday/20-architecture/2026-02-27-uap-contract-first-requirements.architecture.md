---
doc_id: uap-contract-first-requirements
title: UAP Contract-First Requirements Refinement
doc_type: architecture
domain: architecture
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-contract-first-requirements
tags:
  - uap
  - requirements
  - ddd
  - contracts
summary: Defines bounded contexts, topology, boundary rules, and contract ownership model for the platform.
related_docs:
  - ../10-discovery/2026-02-27-uap-core.brainstorm.md
  - ../../../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md
  - ../30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
---

# Contract-First Requirements Refinement

## Refined Problem Definition
우리가 해결하려는 문제는 "에이전트를 잘 만드는 것"이 아니라 "독립 모듈을 깨지지 않게 조립해 다양한 에이전트를 일관되게 실행하는 것"이다.

성공 기준:
- provider/agent 교체 시 orchestrator 변경 없이 실행 가능
- run 상태와 결과 해석이 executor 내부 구현과 독립적
- 장애/중단/재시도 상황에서 계약 수준의 일관성 유지

## Domain Identification (DDD Lite)

### Bounded Context A: Mission Control
- 책임: 미션 생성, run 상태 수명주기, 정책 적용
- 핵심 엔티티: `Mission`, `Run`
- 규칙: 외부에는 coarse status만 공개

### Bounded Context B: Execution Engine (`ralph-loop`)
- 책임: 반복 실행, 내부 완료 판단, 실패/재시도
- 핵심 엔티티: `ExecutionAttempt`, `CompletionEvidence`
- 규칙: 내부 판단 로직은 외부로 유출 금지

### Bounded Context C: Planning & Delegation (`nanoclaw core`)
- 책임: 목표 해석, 서브태스크 분해, handoff 생성
- 핵심 엔티티: `TaskPlan`, `SubtaskHandoff`

### Bounded Context D: Provider Runtime
- 책임: 모델 호출/도구호출 추상화
- 핵심 엔티티: `ProviderProfile`, `InvocationRecord`

### Bounded Context E: Messaging Gateway (`codex2message` lineage)
- 책임: user/channel I/O, ack/dispatch
- 핵심 엔티티: `InboundCommand`, `OutboundUpdate`

### Bounded Context F: Observability
- 책임: run/task/span/event 추적
- 핵심 엔티티: `TraceEnvelope`, `RunTimelineEvent`

## Ubiquitous Language
- Mission: 사용자 목적 단위
- Run: 실행 인스턴스
- Task/Subtask: 미션 분해 단위
- Handoff: 하위 실행 위임 계약
- Completion Evidence: 완료 증거(산출물/요약/검증 정보)
- Policy: budget/depth/timeout/cancel 규칙

## Non-Negotiable Requirements
- 계약 기반 통신(직접 내부 의존 금지)
- 명시적 완료 신호
- 취소/예산/깊이 제한 정책 강제
- LangFuse 기반 종단 추적 가능성
- 권한/비밀키 경계 분리

## Negotiable Requirements (Phase 1)
- 재시작 복구
- 고급 UI
- 고도 병렬 스케줄링
- provider 자동 튜닝

## Recommended Topology (Hybrid: Agent Monorepo + External Repos)

### Repo A: `monday` (main agent repo)
- `packages/agent-kernel`
- `packages/executor-ralph-loop`
- `packages/orchestrator`
- `packages/contract-bindings` (중앙 계약 패키지 consumer)
- `packages/provider-client-adapter`
- `packages/o11y-client-adapter`
- `packages/messaging-adapter`
- `apps/control-plane` (optional thin app)

### Repo B: `platform-provider-gateway` (independent)
- `services/provider-runtime`
- `adapters/provider-codex`
- `adapters/provider-claude`
- `adapters/provider-local-llm`

### Repo C: `platform-observability-gateway` (independent)
- `services/telemetry-gateway`
- `sinks/langfuse-sink`
- `buffer/replay-worker`

### Repo D: `platform-contracts` (independent)
- `schemas/run-lifecycle.schema.json`
- `schemas/subtask-handoff.schema.json`
- `schemas/executor-result.schema.json`
- `schemas/provider-invocation.schema.json`
- `schemas/observability-event.schema.json`
- `compat/compatibility-report.md`

## Package Boundary Rules (Encapsulation Discipline)
- 공용 경계 타입은 `platform-contracts` 배포 패키지 경유 import만 허용
- 로컬 DTO/event는 해당 레포 내부에서만 사용(타 레포 공유 금지)
- `agent-kernel`은 provider 구현체를 직접 참조하지 않고 `ProviderPort`만 의존
- `orchestrator`는 executor 내부 상태/구조를 해석하지 않음
- `messaging-adapter`는 run state를 생성하지 않고 relay/ack만 담당
- boundary lint 실패 시 배포/병합 차단

## Contract Ownership Model (Hybrid)
- 중앙 소유: C1~C5(run lifecycle, handoff, result, provider invocation, observability event)
- 로컬 소유: 성능/운영 최적화용 내부 이벤트, 저장용 read-model, 내부 오류 payload
- 강제 규칙: 로컬 계약은 외부 I/O 경계에서 반드시 C1~C5로 매핑되어야 한다
- 검증: compatibility test + consumer-driven contract test를 release gate에 포함

## Candidate Interface Contracts (No Implementation)
- `RunLifecyclePort`: start, updateStatus, finish, fail, cancel
- `ExecutorPort`: execute(runContext, handoff?) -> completion/result
- `PlannerPort`: plan(mission) -> taskPlan
- `SubtaskPort`: delegate(subtaskHandoff) -> runRef
- `ProviderPort`: invoke(requestProfile) -> providerResult
- `TelemetryPort`: emit(runEvent/spanEvent)

## Candidate Service/Class Map (For Design Review)
- `MissionOrchestrator` (Mission Control): run 생성/정책 적용/상태 집계
- `RalphLoopExecutor` (Execution Engine): 반복 실행/완료 증거 산출
- `SubtaskDelegator` (Planning): handoff 생성 및 위임
- `ProviderGateway` (Provider Runtime): provider profile 적용/호출 기록
- `TimelineEmitter` (Observability): trace/span/event 표준화 전송
- `MessageBridge` (Messaging): inbound 명령과 outbound 상태 메시지 중재

## Technology Candidates (Provisional)
- 언어/런타임: TypeScript(Node.js) 우선, executor는 필요 시 Rust 분리 가능
- 계약 정의: JSON Schema 우선 + SemVer 관리
- 메시징: NATS 또는 Redis Streams (idempotency key 기반 dedupe 지원 필수)
- 관측: LangFuse + OpenTelemetry bridge
- 정책/설정: typed config + environment contract 문서화

## Methodology Stance
- DDD Lite: 경계/언어/정책을 먼저 고정하고 구현은 이후 결정
- TDD: contract test -> policy test -> integration test 순서
- ADR discipline: 핵심 경계 변경은 짧은 ADR 필수
- YAGNI: core loop + contracts 밖 기능은 extension으로 분리

## Anti-Bloat Guardrails (NanoClaw Discipline)
- 새 기능은 먼저 prompt/policy/contract 변경으로 해결 가능한지 검토
- 새 모듈 추가는 기존 모듈 책임을 침범하지 않는 경우에만 허용
- \"범용 유틸\" 추가 전 재사용 근거 2개 이상 요구
- 계약 변경 없는 대규모 추상화 추가는 원칙적으로 거부
- 문서/코드 증가량보다 경계 명확성 증가를 우선 KPI로 본다

## Validation Order
1. 계약 테스트
2. 정책 테스트(cancel/budget/depth)
3. provider 교차 테스트
4. end-to-end timeline 테스트
5. 실패 주입 테스트(장애/중복/지연)

## Risks to Track
- 계약 과도설계 vs 미래 파손 사이 균형
- provider 편차로 인한 품질 변동
- 모듈 경계 lint 미비로 인한 결합 누수
- 독립 레포 간 버전 불일치로 인한 런타임 계약 깨짐
