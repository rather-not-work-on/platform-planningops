---
doc_id: uap-issue-closure-matrix
title: UAP Issue Closure Matrix
doc_type: quality
domain: quality
status: active
date: 2026-02-27
updated: 2026-02-28
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-issue-closure-matrix
tags:
  - uap
  - quality
  - issue-tracking
  - gates
summary: Maps review issues to architecture documents, closure conditions, and quality gates.
related_docs:
  - ../../../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md
  - ../20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
  - ../30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ../../../30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md
  - ../../../40-quality/uap-planningops-tradeoff-decision-framework.quality.md
---

# Issue Closure Matrix (Review -> Brainstorm Integration)

## Purpose
리뷰에서 식별된 이슈가 브레인스토밍 문서 어디에서 어떤 게이트로 닫히는지 명확히 연결한다.

`001~007` legacy TODO의 canonical 추적 기준은 이 문서다. `todos/`는 작업 이력/증빙 보조 용도로만 사용한다.

게이트 네임스페이스 규칙:
- 이 매트릭스의 `Gate A~G`는 Foundation 실행계획 게이트를 의미한다.
- PlanningOps Sync 문서의 `Sync Gate A~F`와 혼용하지 않는다.

## Mapping Table

| Issue | Priority | Risk Theme | Primary Document Target | Gate | Closure Condition |
|---|---|---|---|---|---|
| 001 Status state-machine drift | P1 | 계약 일관성 | `../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` (Canonical Enums, C1/C3) | Gate A | 상태 enum 단일화 + 결과 매핑 규칙 확정 |
| 002 Missing idempotency contract | P1 | 중복 실행/비용 폭주 | `../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` (C1/C2) | Gate F | idempotency/dedupe 필드 + 재생 테스트 통과 |
| 003 Weak completion evidence | P1 | false completion | `../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` (C3 evidence schema) | Gate E | strong evidence 필수 + 검증 실패 시 success 거부 |
| 004 Cancel ack semantics missing | P2 | 제어권/운영 SLO | `../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` (C1 cancel timeline) | Gate B | 요청/ack/적용 시점 측정 가능 |
| 005 O11y fallback semantics gap | P2 | 추적 단절 | `../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` (C5 delivery fields) | Gate C | event identity/order/retry 규칙 고정 |
| 006 Policy ownership ambiguity | P2 | DDD 경계 충돌 | `../20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md` (authority rule) | Gate B | policy authority 컨텍스트 단일화 |
| 007 Provider auth scope gap | P2 | 보안 경계 붕괴 | `../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` (C4 auth fields) | Gate D | scope/secret_ref 계약화 + 회귀 기준 확정 |

## Sequencing Rule
1. P1 전부 닫기
2. P2 운영 강건성 닫기
3. Gate A~G 재검증
4. `/workflows-work` 진입

## Pruning Rule
- 같은 이슈를 여러 문서에서 반복 설명하지 않는다.
- 이 매트릭스는 "링크 허브" 역할만 하며 상세 논의는 대상 문서에서 유지한다.
