---
doc_id: uap-failure-simulation
title: Unified Personal Agent Platform Failure Simulation Playbook
doc_type: simulation
domain: discovery
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-simulation-playbook
tags:
  - uap
  - simulation
  - failure-mode
  - validation
summary: Enumerates failure thought experiments, rebuttal loops, and must-pass gates before implementation.
related_docs:
  - ./2026-02-27-uap-core.brainstorm.md
  - ../../../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md
  - ../30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
---

# Unified Personal Agent Platform - Simulation Playbook

## Goal
구현 전에 실패 경로를 먼저 탐색해 요구사항을 날카롭게 만든다. 핵심은 OpenClaw식 비대화를 피하고, NanoClaw식 핵심 경계를 끝까지 유지하는 것이다.

## Priority Ladder (What Must Never Break)
1. 계약 무결성: 모듈 간 계약이 깨지면 기능보다 우선해서 중단한다.
2. 안전 경계: 권한/비밀키/실행 범위 분리는 비용을 치르더라도 유지한다.
3. 완료 의미론: 완료 신호는 명시적이어야 하며 휴리스틱으로 대체하지 않는다.
4. 추적 가능성: run -> task -> subtask -> span이 단일 체인으로 추적 가능해야 한다.
5. 확장성/비용 최적화: 위 1~4를 만족한 뒤 최적화한다.

## Negotiable (Can Compromise Early)
- 재시작 복구/체크포인트
- 고급 UI 및 자동화 편의 기능
- 멀티에이전트 병렬도 상향
- 고급 캐시/성능 튜닝

## Thought Experiments

### S01 Contract Drift (orchestrator vs ralph-loop)
- 가설: 한쪽만 배포되어 `Run Lifecycle` 필드가 달라진다.
- 위험: run stuck, 잘못된 성공 판정.
- 최우선 보호: 계약 버전 협상 실패 시 실행 차단.
- 타협 가능: 새 필드 기능 비활성화.
- 게이트: 계약 적합성 테스트 + 하위호환 시뮬레이션 통과.

### S02 Provider Behavioral Variance
- 가설: Codex/Claude/local LLM이 동일 프롬프트에서 다른 도구 호출 패턴을 낸다.
- 위험: 성공률 편차, 비용 급증.
- 최우선 보호: provider 독립 결과 계약(artifact + completion evidence).
- 타협 가능: provider별 prompt/profile 분기 허용.
- 게이트: provider 교차 회귀 테스트(동일 임무 3종).

### S03 Subtask Explosion
- 가설: 서브태스크가 재귀적으로 늘어나 실행이 폭주한다.
- 위험: 비용/시간 폭증, 관측 난이도 증가.
- 최우선 보호: max depth, max concurrent subtasks, budget ceiling.
- 타협 가능: 일부 task 직렬화.
- 게이트: worst-case 트리 시뮬레이션에서 ceiling 작동 확인.

### S04 Scheduler Storm
- 가설: 외부 이벤트 중복으로 동일 미션이 다중 실행된다.
- 위험: 중복 작업, 충돌, 채널 스팸.
- 최우선 보호: idempotency key + dedupe window.
- 타협 가능: 지연 증가(큐잉).
- 게이트: 중복 이벤트 재생 테스트.

### S05 False Completion
- 가설: executor가 조기 완료를 보고한다.
- 위험: 사용자 신뢰 붕괴.
- 최우선 보호: completion contract에 증거(artifact/hash/summary) 강제.
- 타협 가능: 승인 대기 상태 추가.
- 게이트: negative test(증거 누락 시 완료 거부).

### S06 O11y Blackout (LangFuse down)
- 가설: 관측 백엔드 장애.
- 위험: 디버깅 불가, 운영 블라인드.
- 최우선 보호: 로컬 fallback 로그 + 재전송 큐.
- 타협 가능: 실시간 대시보드 지연.
- 게이트: LangFuse 장애 주입 테스트.

### S07 Secret Boundary Leak
- 가설: provider adapter에서 비밀키가 상위 계층 로그로 유출.
- 위험: 보안 사고.
- 최우선 보호: redaction + 계층별 secret scope.
- 타협 가능: 디버그 로그 상세도 축소.
- 게이트: 로그 스캔 정책 테스트.

### S08 Messaging Split-Brain
- 가설: codex2message 계열 채널 ack 불일치.
- 위험: 사용자에게 상충 상태 노출.
- 최우선 보호: source of truth를 run store 하나로 고정.
- 타협 가능: 메시지 재정렬/지연.
- 게이트: 네트워크 지연/재전송 시뮬레이션.

### S09 Human Override Race
- 가설: 사용자가 중단 요청했지만 executor는 계속 진행.
- 위험: 제어권 상실.
- 최우선 보호: cancel token 전파는 best effort가 아닌 hard requirement.
- 타협 가능: 안전 정지까지 짧은 지연.
- 게이트: cancel latency SLO 검증.

### S10 Monorepo Boundary Erosion
- 가설: 빠른 개발을 이유로 내부 모듈 직접 import가 늘어난다.
- 위험: 독립성 붕괴, 분리 불가.
- 최우선 보호: 의존성 규칙 lint + contract package 외 직접참조 금지.
- 타협 가능: 임시 adapter 레이어.
- 게이트: 아키텍처 경계 검사 CI.

### S11 Cost Runaway
- 가설: 반복 루프/재시도 누적으로 비용 폭증.
- 위험: 운영 불가능.
- 최우선 보호: per-run/per-day budget policy.
- 타협 가능: 품질 낮은 fallback provider 사용.
- 게이트: 비용 한도 초과 시 graceful degradation 테스트.

### S12 Minimalism Drift (OpenClaw-style bloat)
- 가설: 기능 요청마다 새 abstraction을 추가해 핵심 경계가 흐려진다.
- 위험: 유지보수 난이도 증가.
- 최우선 보호: "핵심 루프 + 계약" 외 기능은 extension으로 분리.
- 타협 가능: 확장 모듈 비활성화.
- 게이트: 기능 추가 PR마다 YAGNI 리뷰 체크.

### S13 Status Vocabulary Split-Brain
- 가설: 모듈별로 `started/created` 해석이 달라 상태 집계가 어긋난다.
- 위험: 잘못된 성공/실패 집계, 운영판단 오류.
- 최우선 보호: canonical enum + mapping table 단일화.
- 타협 가능: 레거시 alias를 단기 허용.
- 게이트: 상태 전이 계약 회귀 테스트.

### S14 Idempotency Key Collision
- 가설: 잘못된 키 생성으로 서로 다른 미션이 충돌한다.
- 위험: 정상 작업이 dedupe로 누락.
- 최우선 보호: 키 스코프 규칙(`mission_id+intent_hash`) 고정.
- 타협 가능: 충돌 의심 시 수동 승인 경로.
- 게이트: collision fuzz 테스트.

### S15 Weak Evidence Acceptance
- 가설: evidence가 요약 문자열만 포함해도 `complete`로 처리된다.
- 위험: false completion.
- 최우선 보호: `strong evidence` 구조 필수화.
- 타협 가능: `partial`로 다운그레이드.
- 게이트: evidence schema validation test.

### S16 Cancel Ack Gap
- 가설: cancel 요청은 기록되지만 ack 시점이 누락된다.
- 위험: SLO 측정 불가, race 원인 분석 실패.
- 최우선 보호: 요청/ack/적용 시점 3단계 필드 강제.
- 타협 가능: 초기에는 대시보드 미표시.
- 게이트: cancel latency 측정 가능성 검증.

### S17 O11y Replay Storm
- 가설: 장애 복구 시 재전송이 폭주해 중복 이벤트가 대량 발생한다.
- 위험: 타임라인 왜곡, 저장소 비용 급증.
- 최우선 보호: `event_id` 안정성 + dedupe + backoff.
- 타협 가능: 일부 저가치 이벤트 드롭.
- 게이트: 재전송 부하 테스트.

### S18 Policy Ownership Conflict
- 가설: Mission Control과 Executor가 서로 다른 budget 규칙을 적용한다.
- 위험: run 결과 비결정성.
- 최우선 보호: policy authority 단일화.
- 타협 가능: 전환기간 동안 shadow evaluation.
- 게이트: policy consistency test.

### S19 Provider Auth Escalation
- 가설: provider 교체 과정에서 `allowed_tool_scope`가 넓어진다.
- 위험: 과권한 실행, 비밀 접근 확대.
- 최우선 보호: auth scope 계약 필드 + deny-by-default.
- 타협 가능: 임시 allowlist 승인 프로세스.
- 게이트: 권한 회귀 테스트.

### S20 Schema Evolution Mismatch
- 가설: minor 버전 업데이트로 optional 필드가 사실상 required처럼 동작한다.
- 위험: 구버전 consumer 장애.
- 최우선 보호: consumer contract test matrix.
- 타협 가능: adapter fallback 경로.
- 게이트: 다중 버전 상호운용 테스트.

## Rebuttal Loop (Critique/Counter-Critique)
- 주장: "초기에 복잡한 계약은 과하다."
- 반박: 독립 모듈 전략에서는 계약이 코드보다 먼저 고정돼야 분리가 가능하다.
- 재반박: MVP 속도 저하 우려.
- 결론: 계약은 최소 필드로 시작하되 버전 전략은 즉시 도입.

- 주장: "멀티에이전트는 나중에."
- 반박: 지금 서브태스크 계약을 넣지 않으면 이후 확장이 파괴적이다.
- 결론: 실행은 단일 메인으로 시작하되 handoff 계약은 1단계부터 포함.

- 주장: "idempotency는 구현에서 처리하면 충분하다."
- 반박: 독립 모듈 구조에서는 구현 규칙이 공유되지 않으므로 계약에 올라와야 한다.
- 결론: idempotency는 C1/C2 필수 필드로 고정.

- 주장: "완료는 모델이 판단하니 evidence를 강제할 필요가 없다."
- 반박: 모델별 편차가 크고 false completion은 신뢰 붕괴를 만든다.
- 결론: `complete`는 strong evidence 검증 통과 시에만 허용.

## Phase Gates (Must Verify Before Moving On)
- Gate A (계약): lifecycle/handoff/o11y 계약 검증 통과 전 구현 확장 금지
- Gate B (제어): cancel/budget/depth limit 동작 검증 전 자동화 확장 금지
- Gate C (관측): run-to-span 추적 누락 0% 달성 전 운영 전환 금지
- Gate D (경계): 모듈 직접 결합 탐지 시 배포 차단
- Gate E (증거): evidence schema 검증 실패율 0% 달성 전 success 판정 금지
- Gate F (중복): idempotency/dedupe 회귀 테스트 통과 전 scheduler 연동 금지

## Exit Criteria for Brainstorm Quality
- 실패 시나리오 12개 이상에 대해 보호 우선순위가 명시됨
- 타협 가능한 영역과 불가 영역이 분리됨
- 단계별 게이트가 구현 순서와 연결됨
- 핵심 경계(contracts)가 독립 문서로 분리됨
