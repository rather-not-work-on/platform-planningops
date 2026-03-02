---
title: fix: Resolve Gate Verdict and Backlog Bootstrap Review Findings
type: plan
date: 2026-03-03
updated: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Deep plan to resolve P1-P3 review findings (#011-#015) for Track1 gate verdict consistency and backlog bootstrap idempotency at scale.
---

# fix: Resolve Gate Verdict and Backlog Bootstrap Review Findings

## Overview
본 계획은 리뷰에서 식별된 5개 이슈(`011~015`)를 한 번에 수습하기 위한 안정화 계획이다.

핵심 목적:
1. Track1 gate 판정 신호를 단일/일관 규칙으로 고정
2. gate 실패/미결정 결과를 자동화 파이프라인에서 확실히 차단
3. backlog bootstrap 스크립트를 대규모 이슈/프로젝트에서도 재실행 가능하게 강화

## Problem Statement / Motivation
현재 상태의 주요 리스크:
- `run_track1_gate_dryrun.py`가 `inconclusive/fail`이어도 exit code `0`으로 종료 가능 (`#011`, P1)
- chain report와 final gate report가 서로 다른 verdict를 낼 수 있음 (`#012`, P1)
- bootstrap dedup/lookup이 고정 limit(`200/500`)로 스케일에 취약 (`#013`, `#015`)
- closed issue를 암묵 재사용할 수 있어 backlog 상태 일관성이 깨질 수 있음 (`#014`)

이 리스크는 "게이트 통과/차단"과 "카드 식별/매핑" 두 축의 신뢰도를 직접 훼손하므로 선제 수습이 필요하다.

## Review Finding Mapping
| Todo | Priority | Theme | Merge impact |
|---|---|---|---|
| #011 | P1 | gate exit contract | blocks merge |
| #012 | P1 | verdict consistency | blocks merge |
| #013 | P2 | issue dedup pagination | important |
| #014 | P2 | closed-issue reuse policy | important |
| #015 | P3 | project item lookup scale | nice-to-have |

## Proposed Solution
해결 전략은 두 트랙이 아닌 "P1 먼저 + bootstrap 안정화"의 단일 수렴 모델을 사용한다.

1. **Gate semantics hardening (P1) first**
- canonical verdict source를 `final_verdict`로 고정
- chain report는 동일 verdict를 따르거나 보조 verdict로 명시 분리
- strict 모드에서 `final_verdict != pass`면 non-zero exit 강제

2. **Bootstrap idempotency/scalability hardening (P2/P3)**
- dedup에 pagination 도입(issues, project items)
- closed issue 매칭 기본 정책을 명시(open-only default)
- 재실행 시 duplicate 생성 0건 보장

## Scope
### In Scope
- `planningops/scripts/run_track1_gate_dryrun.py` verdict/exit 계약 수정
- `planningops/scripts/bootstrap_two_track_backlog.py` dedup/lookup/state 정책 수정
- 관련 artifact schema 및 문서 업데이트
- regression test/fixture 추가

### Out of Scope
- 새로운 loop_profile 종류 추가
- project field taxonomy(v3) 전면 개편
- gate KPI 기준값 자체 변경

## Technical Approach
### A. Gate Verdict Contract Unification (`#012 -> #011`)
#### Decision
- Canonical verdict source: `track1-gate-dryrun-report.json.final_verdict`
- Chain report는 아래 중 하나로 정리:
  - 옵션 A(권장): `overall_gate_verdict`를 추가하고 기존 `verdict`는 deprecated
  - 옵션 B: `verdict`를 canonical verdict로 동일화

#### Exit Code Contract
- 기본 모드: report-only (`0`) 유지 가능
- strict 모드(`--strict`):
  - `pass` -> `0`
  - `inconclusive|fail` -> `1`

#### Why this default
- 기존 로컬 사용성 보존 + CI에서 명시적 strict 강제 가능
- 향후 strict default로 전환할 수 있도록 migration path 확보

### B. Bootstrap Dedup and Lookup Hardening (`#013`, `#014`, `#015`)
#### Issue dedup strategy
- 현재: `gh issue list --limit 200 --state all`
- 변경:
  1. open issue 우선 스캔(기본)
  2. closed scan은 명시 플래그(`--allow-reopen-closed`)일 때만
  3. pagination으로 전체 대상 탐색

#### Project item lookup strategy
- 현재: `gh project item-list --limit 500`
- 변경:
  - pagination 추가 또는 issue-node-id 기반 targeted lookup 도입
  - fallback path에서도 fixed cap 의존 제거

#### Closed issue handling policy
- 기본: closed match는 재사용하지 않음(open-only)
- 옵션 플래그 활성 시:
  - reopen 후 재사용 또는 새 이슈 생성 정책을 explicit하게 선택

## Implementation Phases
### Phase 0: Baseline Freeze (0.5d)
- 현재 artifact/report 스냅샷 보존
- 재현 케이스 고정: inconclusive report + duplicate 위험 시나리오
- deliverable:
  - `planningops/artifacts/validation/review-findings-baseline-2026-03-03.json`

### Phase 1: P1 Gate Fix (1d)
- `run_track1_gate_dryrun.py` verdict contract 통합
- `--strict` 플래그 도입 및 exit contract 적용
- chain/dryrun report 필드 정합화
- tests:
  - KPI missing -> final inconclusive
  - strict mode exit code = 1
  - non-strict exit code behavior 검증

### Phase 2: P2 Bootstrap Policy Fix (1d)
- open-only dedup 기본 정책 도입
- `--allow-reopen-closed` 정책 플래그 도입
- issue pagination 구현
- tests:
  - closed match 기본 미재사용
  - allow-reopen-closed 동작 검증
  - repeated apply duplicate 0

### Phase 3: P3 Scalability Fix (0.5~1d)
- project item lookup pagination/targeted query 구현
- large set(>500) 시나리오 fixture 추가
- fallback 안정성 검증

### Phase 4: Validation and Rollout (0.5d)
- docs/schema checks 재실행
- gate dryrun strict/non-strict 비교 실행
- bootstrap dry-run/apply 재실행
- todo status 전환(`pending -> ready/complete`) 및 work log 업데이트

## Execution Order Plan (Issue-first)
| order | todo | task | depends_on |
|---|---|---|---|
| 1 | #012 | verdict source unification | - |
| 2 | #011 | strict exit contract | #012 |
| 3 | #014 | closed issue policy | - |
| 4 | #013 | issue pagination dedup | #014 |
| 5 | #015 | project item lookup scaling | #013 |
| 6 | #011~#015 | integrated validation + docs update | all |

## Test Strategy
### Unit/contract checks
- `python3 -m py_compile planningops/scripts/run_track1_gate_dryrun.py planningops/scripts/bootstrap_two_track_backlog.py`

### Behavioral checks
- Gate script:
  - non-strict mode: report generated + verdict persisted
  - strict mode: inconclusive/fail에서 exit 1
- Bootstrap:
  - dry-run repeat: same plan_item_id no duplicate simulation
  - apply repeat: duplicate issue/card 생성 0건

### System checks
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
- `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch`

## Acceptance Criteria
### Functional
- [x] `#011`: strict mode에서 non-pass verdict는 반드시 non-zero exit
- [x] `#012`: chain/dryrun report 간 overall verdict 불일치 0건
- [x] `#013`: issue count >200에서도 dedup 성공
- [x] `#014`: closed issue 처리 정책이 명시적(open-only default)
- [x] `#015`: project item count >500에서도 lookup 실패 없음

### Non-functional
- [x] repeat apply 2회 이상에서 duplicate issue/card 생성 0건
- [x] 운영자가 canonical verdict source를 문서만 보고 식별 가능
- [x] 기존 workflow와의 호환 모드(report-only) 보존

## Risks & Mitigations
- Risk: strict 모드 도입으로 기존 자동화가 실패로 전환
- Mitigation: `--strict` opt-in 시작 + CI 명시 설정 + migration note

- Risk: pagination 구현 중 API rate limit 증가
- Mitigation: page size 튜닝 + early-stop 조건 + targeted query fallback

- Risk: closed issue 재사용 정책 변경으로 과거 관행과 충돌
- Mitigation: 기본 open-only + explicit override flag + 운영 가이드 추가

## Documentation Plan
- 업데이트 대상:
  - `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`
  - `docs/workbench/unified-personal-agent-platform/audits/2026-03-02-track1-gate-evidence-manifest-audit.md`
  - 필요 시 `planningops/contracts/requirements-contract.md`
- todos `#011~#015` work log를 구현 진행에 맞춰 갱신

## Success Metrics
- `gate_verdict_conflict_count` = 0
- `strict_mode_false_pass_count` = 0
- `bootstrap_duplicate_issue_count` = 0
- `bootstrap_lookup_failure_count` = 0

## Next Actions
1. `#012`부터 착수해 verdict contract를 먼저 단일화
2. `#011` strict exit 적용 후 CI/로컬 실행 모드 분리 검증
3. `#014 -> #013 -> #015` 순서로 bootstrap 안정화 적용
4. 통합 검증 후 todo 상태를 `ready/complete`로 전환

## Execution Progress
- [x] Phase 0 baseline freeze
- [x] Phase 1 P1 gate fix
- [x] Phase 2 P2 bootstrap policy fix
- [x] Phase 3 P3 scaling fix
- [x] Phase 4 validation and rollout
