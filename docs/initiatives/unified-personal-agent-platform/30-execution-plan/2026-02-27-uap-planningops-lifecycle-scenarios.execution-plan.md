---
doc_id: uap-planningops-lifecycle-scenarios-plan
title: UAP PlanningOps Lifecycle Scenario Playbook
doc_type: execution-plan
domain: planning
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
tags:
  - uap
  - planningops
  - lifecycle
  - scenarios
  - operations
summary: Defines concrete post-planning scenarios for plan item update, deletion, completion, reopen, and drift handling with deterministic operational steps.
related_docs:
  - ./2026-02-27-uap-github-planningops-sync.execution-plan.md
  - ../20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md
  - ../40-quality/2026-02-27-uap-planningops-tradeoff-decision-framework.quality.md
  - ../20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md
---

# UAP PlanningOps Lifecycle Scenario Playbook

## Purpose
계획 수립 이후 실제 운영에서 발생하는 `수정/삭제/완료/재개/분할/병합`을 표준 시나리오로 고정한다.
목표는 두 가지다.
- 어떤 변경 요청이 들어와도 같은 절차로 처리
- GitHub 동기화 결과와 문서 상태가 항상 재현 가능하도록 유지

## Scope
이 문서는 `plan item` 라이프사이클 운영 규칙만 다룬다.
- 포함: 상태 전이, 동기화 순서, 증빙, 롤백, 에스컬레이션
- 제외: 세부 구현 코드, UI 설계, 도메인 기능 설계

## Lifecycle Vocabulary
- Plan item state: `draft | active | blocked | done`
- Sync run state: `queued | collecting | diffing | applying | reconciling | completed | failed`
- External projection: `running | terminal`
- Drift class: `MISSING_ENTITY | FIELD_MISMATCH | ILLEGAL_MANUAL_CHANGE | ORPHAN_ITEM`

## Action Taxonomy
- `EDIT_META`: 제목/설명/owner/priority 등 메타 수정
- `EDIT_SCOPE`: 수용기준/하위작업/게이트 요구 변경
- `SPLIT`: 한 항목을 다수 항목으로 분해
- `MERGE`: 다수 항목을 하나로 통합
- `COMPLETE`: 완료 처리
- `DELETE`: 항목 제거(미착수 중심)
- `CANCEL`: 진행 중 종료
- `REOPEN`: 완료/취소 항목 재개
- `MOVE_REPO`: 대상 레포 변경

## State Transition Matrix (Decision-Free Defaults)
| Current state | Action | Allowed | Default outcome | Notes |
|---|---|---|---|---|
| `draft` | `EDIT_META` | Yes | same state | version 증가 |
| `draft` | `EDIT_SCOPE` | Yes | same state | gate_refs 재평가 |
| `draft` | `DELETE` | Yes | tombstone 처리 | hard delete 금지 |
| `draft` | `COMPLETE` | No | reject | evidence 없음 |
| `active` | `EDIT_META` | Yes | same state | issue update |
| `active` | `EDIT_SCOPE` | Yes | `active` or `blocked` | 영향도 크면 split 권장 |
| `active` | `CANCEL` | Yes | `done` with canceled outcome | cancel timeline 기록 |
| `active` | `DELETE` | No | convert to `CANCEL` | 이력 보존 우선 |
| `blocked` | `EDIT_META` | Yes | same state | unblock 조건 유지 |
| `blocked` | `COMPLETE` | Conditional | gate pass 필요 | 없으면 reject |
| `done` | `EDIT_META` | Conditional | `done` 유지 | audit-only 수정 권장 |
| `done` | `REOPEN` | Yes | `active` | reopen reason 필수 |

## Scenario Catalog
| ID | Scenario | Trigger | Plan action | GitHub action | Evidence | Escalation |
|---|---|---|---|---|---|---|
| L1 | Metadata update | owner/priority 변경 | `EDIT_META` | issue/project field update | sync-summary delta | none |
| L2 | Scope expansion | acceptance criteria 증가 | `EDIT_SCOPE` + version bump | issue body/milestone check | diff artifact | lead review |
| L3 | Split item | 과대 작업 분해 | parent `superseded` + child items 생성 | parent issue close + child issue create | mapping update | architecture review |
| L4 | Merge items | 중복 작업 통합 | source items `superseded` | source close + target link | merge rationale | lead review |
| L5 | Complete with gate | gate pass 충족 | `COMPLETE` | issue close + status Done | gate evidence bundle | none |
| L6 | Issue closed first | 수동 close 발생 | state 유지 + drift 기록 | reopen or hold per policy | drift report high | manual approval |
| L7 | Delete draft item | 착수 전 제거 | tombstone (`deleted_at`, reason) | issue close + label archived | deletion record | none |
| L8 | Cancel active item | 중단 요청 | cancel timeline 필드 기록 | issue close + canceled label | cancel SLA logs | ops review |
| L9 | Reopen done item | 재작업 필요 | `REOPEN` + reopen_reason | issue reopen + status In Progress | reopen record | lead review |
| L10 | Move repo | 소유 레포 이전 | `MOVE_REPO` + mapping migration | old close, new create/link | migration report | manual approval |
| L11 | Permission mismatch | 401/403 | state unchanged + fail-fast | partial apply stop | run failure log | security owner |
| L12 | Illegal manual edit | protected field 변경 | drift high + auto-correct attempt | corrective update | drift report | manual approval |

## Scenario Selection (Document Review Outcome)
시나리오를 전부 동시에 도입하면 운영 복잡도가 급격히 증가하므로, `핵심`과 `후순위`를 분리한다.

### Phase 1 MVP Scenario Pack (Recommended)
- L1 Metadata update
- L5 Complete with gate
- L6 Issue closed first (manual close drift)
- L7 Delete draft item (tombstone)
- L8 Cancel active item
- L11 Permission mismatch
- L12 Illegal manual edit

### Phase 1 Extended Pack (Optional)
- L2 Scope expansion
- L9 Reopen done item

진입 기준:
- MVP 시나리오 2주 연속 운영에서 `drift_recovery_time_p95` 목표 충족
- duplicate creation 0% 유지
- permission mismatch(401/403)가 주간 1회 이하

### Phase 2 Deferred Scenario Pack
- L3 Split item
- L4 Merge items
- L10 Move repo

## Recommended Composition (How to Structure)
핵심 시나리오는 3개 레인으로 구성하면 구현/검증이 단순해진다.

### Lane A: Content Mutation
- L1, L7
- 목적: plan 문서 변경과 동기화 정합성 검증

### Lane B: State Transition
- L5, L8
- 목적: 완료/취소/재개의 상태 의미론 검증

### Lane C: Integrity and Exception
- L6, L11, L12
- 목적: 수동 개입/권한 오류/불법 변경의 복구 경로 검증

권장 적용 순서:
1. Lane A
2. Lane B
3. Lane C
4. Phase 1 Extended(L2/L9)
5. Phase 2 deferred 시나리오(L3/L4/L10)

## Per-Scenario Runbook (Standard 6 Steps)
모든 시나리오는 아래 절차를 따른다.
1. `classify`: 요청을 action taxonomy로 분류
2. `validate`: 상태 전이 가능 여부와 선행조건 검증
3. `stage`: plan 문서 변경(버전 증가, 이유 필드 기록)
4. `sync`: dry-run -> apply 순서로 동기화
5. `verify`: issue/milestone/project field 정합 검증
6. `archive`: 증빙 아카이브 및 변경 요약 기록

## Deletion and Completion Policy
### Deletion
- 기본 정책: hard delete 금지, tombstone 사용
- tombstone 필수 필드:
  - `deleted_at`
  - `deleted_by`
  - `delete_reason`
  - `replacement_plan_item_id` (선택)

### Completion
- `done` 판정은 `gate pass` 선행
- issue close가 먼저 발생하면 `drift`로 분류
- completion evidence 누락 시 `done` 전이 거부

## Conflict Scenarios and Resolution Order
동시 변경 충돌 시 우선순위:
1. 계약 무결성(C1~C8)
2. 상태 의미론(C3)
3. 매핑 안정성(C2/C8)
4. 운영 편의성

해결 규칙:
- 충돌 항목은 `inconclusive`로 종료하고 강제 완료 금지
- 동일 `sync_key` 충돌은 오래된 run 중단 후 최신 run만 적용

## Rollback and Recovery
- 단일 엔터티 실패: 엔터티 단위 재시도
- 부분 성공: 성공분 유지 + 실패분 큐잉
- 대규모 오류: apply 중단 후 dry-run 재실행
- rollback 기준:
  - protected field 오염
  - 잘못된 milestone 재매핑
  - 동일 item 중복 생성

## Decision Sensitivity Map
판단 유예가 결과에 영향을 주는 시나리오를 표시한다.
| Scenario | High sensitivity decision |
|---|---|
| L5/L6 (Complete/Issue-first close) | done source precedence |
| L8 (Cancel active) | override strictness |
| L11 (Permission mismatch) | trigger cadence + webhook mode |
| L12 (Illegal manual edit) | override strictness |

추가:
- L2/L9는 Phase 1 Extended이므로, MVP 검증 이후에 민감도 분석에 포함한다.
- L3/L4/L10은 Phase 2 deferred이므로, Phase 1에서는 참고 항목으로만 유지한다.

## Operational Metrics (Lifecycle-Specific)
- `reopen_rate`: 완료 후 재개 비율
- `tombstone_ratio`: 삭제/전체 항목 비율
- `scope_change_rate`: scope edit 비율
- `manual_override_frequency`: 주간 override 요청 수
- `drift_recovery_time_p95`: drift high 해소 시간

## Minimum Artifacts Per Lifecycle Event
- `planningops/artifacts/lifecycle/<event_id>.json`
- `planningops/artifacts/sync-summary/<run_id>.json`
- `planningops/artifacts/drift-report/<date>.md`
- `planningops/artifacts/decision-pack/<decision_id>.md` (판단 관련 이벤트인 경우)

## Ready Check Before Enabling Lifecycle Automation
- [ ] action taxonomy와 state matrix를 팀 규칙으로 승인
- [ ] tombstone 필드 스키마 확정
- [ ] completion evidence 검증기 준비
- [ ] conflict resolution 책임자(lead/ops/security) 지정
- [ ] lifecycle metrics 수집 경로 확정
