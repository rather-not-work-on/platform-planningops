---
doc_id: uap-contract-boundaries
title: UAP Contract Boundaries
doc_type: architecture
domain: architecture
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-contract-boundaries
tags:
  - uap
  - contracts
  - run-lifecycle
  - schema
summary: Defines canonical enums, C1-C5 contract fields, invariants, mapping rules, and compatibility policy.
related_docs:
  - ../20-repos/monday/10-discovery/2026-02-27-uap-core.brainstorm.md
  - ../20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md
  - ../20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
---

# Contract Boundaries (Draft for Planning)

## Design Principle
"구현을 숨기고, 계약으로 협업한다." 모든 모듈 간 통신은 버전된 계약을 통해서만 진행한다.

## Contract Ownership
- 공용 계약(C1~C5)은 `platform-contracts` 독립 레포를 단일 소스로 사용한다.
- 각 서비스 레포는 내부 DTO/event를 로컬 소유할 수 있지만, 외부 경계 통신 시 공용 계약으로만 송수신한다.
- 공용 계약 변경은 SemVer + compatibility report + consumer contract test를 동반한다.

## Canonical Enums (Single Source of Meaning)
- `RunStatus`: `queued | running | blocked | terminal`
- `TerminalOutcome`: `succeeded | failed | canceled`
- `ResultType`: `complete | partial | failed | canceled`
- `EventDelivery`: `pending | delivered | retriable_failed | terminal_failed`

매핑 규칙:
- `ResultType=complete` -> `RunStatus=terminal` + `terminal_outcome=succeeded`
- `ResultType=failed` -> `RunStatus=terminal` + `terminal_outcome=failed`
- `ResultType=canceled` -> `RunStatus=terminal` + `terminal_outcome=canceled`
- `ResultType=partial` -> `RunStatus`는 `running` 또는 `blocked` 유지 + resume/blocked 정보 필수

## C1. Run Lifecycle Contract
목적: orchestrator와 상위 시스템이 run의 진행을 일관되게 해석한다.

필수 필드:
- `run_id`, `mission_id`, `status`, `timestamp`, `source_module`, `contract_version`
- `terminal_outcome`, `reason_code`
- `idempotency_key`, `dedupe_window_ms`
- `cancel_requested_at`, `cancel_ack_at`, `cancel_effective_at`, `cancel_reason`

상태 전이 규칙:
- `queued -> running|blocked|terminal`
- `running -> running|blocked|terminal`
- `blocked -> running|blocked|terminal`
- 종료 상태 이후 추가 전이는 금지

불변성:
- 동일 `run_id`의 상태 전이는 단조 증가
- `status=terminal`이면 `terminal_outcome` 필수
- 종료 이벤트에는 `completion_evidence_ref` 또는 `failure_reason` 또는 `cancel_reason` 필수
- 동일 `idempotency_key`와 dedupe window 내 중복 실행은 거부 또는 기존 run 참조로 수렴

## C2. Subtask Handoff Contract
목적: 메인 에이전트에서 서브 실행기로 의도를 손실 없이 전달한다.

필수 필드:
- `parent_run_id`, `subtask_id`, `objective`, `constraints`, `budget`, `timeout`, `expected_artifact`, `return_contract_version`
- `idempotency_key`, `dedupe_window_ms`, `policy_version`

불변성:
- `subtask_id`는 parent run 내 유일
- `budget`과 `timeout`은 정책 상한 이내

## C3. Executor Result Contract
목적: executor 내부 로직과 무관하게 완료/실패를 외부에서 판단 가능하게 한다.

필수 필드:
- `run_id`, `result_type`(`complete|partial|failed|canceled`), `evidence`, `metrics`, `policy_consumption`

불변성:
- `complete`면 `evidence` 비어있으면 안 됨
- `partial`이면 `resume_hint` 또는 `remaining_objectives` 중 하나 필수

`evidence` 최소 구조:
- `artifact_ref`, `artifact_hash`, `verification_method`, `verifier`, `verified_at`
- `evidence_quality`(`strong|weak`) - `complete`는 `strong`만 허용

## C4. Provider Invocation Contract
목적: provider 교체 시 상위 계층 영향 최소화.

필수 필드:
- `provider_id`, `model_id`, `input_ref`, `tool_policy`, `cost_budget`, `latency_budget`
- `auth_scope`, `allowed_tool_scope`, `secret_ref`, `data_classification`

결과 필드:
- `provider_status`, `output_ref`, `tool_calls`, `token_usage`, `cost_usage`

## C5. Observability Event Contract
목적: run/task/span 연결이 끊기지 않도록 표준화.

필수 필드:
- `trace_id`, `span_id`, `parent_span_id`, `run_id`, `event_type`, `event_time`, `attributes`
- `event_id`, `sequence_no`, `delivery_status`, `delivery_attempt`

불변성:
- 모든 span은 동일 run chain에 귀속 가능해야 함
- 민감정보는 redaction policy 적용 후만 전송
- `event_id`는 재전송 시에도 안정적으로 유지되어 중복 제거 가능해야 함
- `sequence_no` 역전이 감지되면 `retriable_failed`로 전환 후 재전송 정책 적용

## Error Taxonomy (Cross-Contract)
- `CONTRACT_VALIDATION_ERROR`
- `POLICY_VIOLATION`
- `PROVIDER_UNAVAILABLE`
- `EXECUTION_TIMEOUT`
- `CANCELLED_BY_USER`
- `OBSERVABILITY_BACKEND_DOWN`
- `IDEMPOTENCY_CONFLICT`
- `EVIDENCE_VERIFICATION_FAILED`
- `INSUFFICIENT_AUTH_SCOPE`

## Compatibility Rules
- major: breaking 변경
- minor: optional 필드 추가
- patch: 의미 변경 없는 수정
- consumer는 알 수 없는 필드를 무시하고 필수 필드만 엄격 검증

## Contract Quality Checklist
- 필수 필드가 실제 운영 의사결정에 필요한가?
- 상태 전이/불변성이 테스트 가능한가?
- 실패 코드가 복구 전략과 직접 연결되는가?
- provider/engine 교체 시 상위 코드 변경이 0에 가까운가?
- 보안/민감정보 규칙이 계약 수준에 반영됐는가?
- cancel latency, dedupe, evidence 검증을 지표로 계산할 수 있는가?
