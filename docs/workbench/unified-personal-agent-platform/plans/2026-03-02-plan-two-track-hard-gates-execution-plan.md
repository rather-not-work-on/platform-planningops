---
title: plan: Two-Track Hard-Gate Execution for Post-Wave-B
type: plan
date: 2026-03-02
updated: 2026-03-02
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Comprehensive execution plan for the post-Wave-B phase with non-periodic Kanban pull, Track 1 reliability hard gate, and gate-sequenced Track 2 progression.
---

# plan: Two-Track Hard-Gate Execution for Post-Wave-B

## Enhancement Summary
**Planned on:** 2026-03-02  
**Source brainstorm:** `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-02-uap-post-waveb-next-phase-brainstorm.md`  
**Planning mode:** non-periodic Kanban pull + hard gate progression

### Key Improvements
1. `Two-Track + Hard Gate`를 선언 수준이 아니라 운영 계약으로 구체화했다.
2. `Track 1 Exit Gate`를 판정 가능한 증빙/KPI/검증 체인으로 고정했다.
3. Track 2를 Gate 전 `prototype-only`, Gate 후 `implementation-eligible`로 분리했다.
4. 전이로그 기반 재계획 트리거를 강제해 실패 전파를 제어한다.
5. GitHub Project 필드 스키마를 현재 운영 값과 정합되게 명시했다.

## Idea Refinement Input
`2026-03-02` 브레인스토밍(`uap-post-waveb-next-phase`)을 planning input으로 확정했다.

브레인스토밍에서 재사용한 핵심 결정:
- 운영 모델: `Two-Track with Hard Gates`
- 실행 방식: 스프린트가 아닌 비정기 Kanban pull
- 우선순위: Track 1(PlanningOps reliability) 선행
- 경계: Foundation Gate / Sync Gate와 Track 1 Exit Gate 혼용 금지

## Research Consolidation
### Repository Research Summary
- canonical vs workbench 분리 규약이 고정되어 있다.
  - canonical: `docs/initiatives/unified-personal-agent-platform/*`
  - workbench: `docs/workbench/unified-personal-agent-platform/*`
- 문서 검증 표준 명령은 `uap-docs.sh check --profile all`이다.
- Project schema/loop selection은 이미 런타임 스크립트와 validator에 구현되어 있다.
  - `planningops/scripts/issue_loop_runner.py`
  - `planningops/scripts/validate_project_field_schema.py`
- 현재 GitHub open issue는 0건이다(2026-03-02 기준).

### Institutional Learnings Search Results
- `docs/solutions/` 기준 학습 문서 검색 결과: 0건.
- 따라서 이번 계획은 기존 workbench plan/audit/todo를 대체 학습 입력으로 사용한다.

### Relevant Existing Signals (to reuse)
- `todos/008-pending-p2-loop-profile-l2-unreachable.md`
- `todos/009-pending-p2-loop-profile-field-drift-crash.md`
- `todos/010-pending-p3-loop-profile-validator-state-coverage-gap.md`

### External Research Decision
- 이번 범위는 신규 외부 기술 도입이 아니라 내부 운영 계약/검증 정합성 강화가 핵심이므로 외부 리서치는 생략한다.
- 외부 문서 리서치는 Phase E(implementation readiness)에서 실제 도입 기술 범위가 확정된 후 수행한다.

## Issue Planning & Structure
- **Issue title (plan artifact):** `enhancement: Two-Track Hard-Gate execution system`
- **Issue type:** enhancement
- **Audience:** planning owner, execution agent runner, docs governance owner, project operator
- **Detail level:** A LOT (comprehensive)
- **Why this level:** 실행 순서/게이트/필드 계약이 결합된 고위험 운영 설계이며 모호성 여지가 크다.

## Overview
이 계획의 목적은 "무엇을 먼저 만들지"보다 "어떤 조건에서 다음 단계로 넘어갈지"를 고정하는 것이다.

운영 원칙:
- 스프린트 시간박스는 사용하지 않는다.
- 에이전트는 준비된 카드를 Kanban pull로 비정기 실행한다.
- `Track 2`는 `Track 1 Exit Gate` 통과 전까지 구조 설계/프로토타입에 한정한다.
- Gate 실패 또는 증빙 불충분 시 구현 확장을 중단하고 재계획 루프로 복귀한다.

## Problem Statement
현재 남아 있는 리스크:
- `Hard Gate`가 선언되어 있으나 판정 데이터/합격선이 운영 레벨로 고정되지 않았다.
- Track 분리가 실행 중 혼합될 수 있어 경계 붕괴 위험이 있다.
- 반복 실패 시 재계획 진입 기준이 부족해 실패가 누적 전파될 수 있다.
- Project field 값과 실제 실행 상태 간 drift를 조기 차단하는 정책이 약하다.

## Proposed Solution
1. `Track 1 Exit Gate`를 must-pass 운영 계약으로 고정한다.
2. Track 1/Track 2를 gate-sequenced backlog로 분해한다.
3. `transition-log.ndjson` 기반 재계획 트리거를 자동 판정한다.
4. Project 필드 스키마와 runtime selection/verification 결과를 1:1 연결한다.
5. 초기에는 로컬 우선 실행을 유지하고 OCI 이행 경계만 문서화한다.

## Scope
### In Scope
- `Track 1 Exit Gate` 판정 계약
- Track 1/2 실행 단계와 산출물
- Replan trigger/transition log 계약
- GitHub Project field 스키마/상태 매핑
- local-first 실행 및 OCI migration boundary 정의

### Out of Scope
- Monday 프로덕션 기능 전체 구현
- NanoClaw/기존 에이전트 코드 대규모 재작성
- 멀티 initiative 공통 프레임워크 일반화

## Stakeholder Analysis
- **Planning owner:** 게이트 판정 기준과 재계획 기준의 해석 일관성이 필요하다.
- **Execution agent:** 모호성 없는 입력 계약(C1/C2/C8, workflow_state, loop_profile)이 필요하다.
- **Project operator:** field drift 탐지/보정 정책과 감사 로그가 필요하다.
- **Repo maintainers (monday/contracts/gateway):** Track 2 이전에 인터페이스 경계가 고정되어야 한다.

## SpecFlow Analysis
### User Flow Overview
1. Planner가 backlog 카드 생성/갱신
2. Runner가 pull 조건(`Status=Todo`, `workflow_state` 허용 집합, `depends_on` 충족) 검사
3. Selector가 `loop_profile` 결정
4. Loop 실행 후 evidence bundle 생성
5. Verifier가 `pass|fail|inconclusive` 판정
6. Feedback sync가 issue comment + project fields 갱신
7. Trigger evaluator가 재계획 조건 검사
8. 조건 충족 시 `Recovery/Replan` 카드 생성 또는 기존 카드 `blocked` 전환

### Flow Permutations Matrix
| Scenario | Entry state | loop_profile | Expected transition | Required evidence |
|---|---|---|---|---|
| Contract ambiguity | `ready-contract` | `L1` | `ready-contract -> review-gate -> done` | `contract-terminology-lock.md`, `verification-report.json` |
| High uncertainty | `ready-contract` | `L2` | `ready-contract -> review-gate -> done` | `scenario-matrix.json`, `simulation-report.md` |
| Stable implementation prep | `ready-implementation` | `L3` | `ready-implementation -> in-progress -> review-gate` | `test-report.json`, `verification-report.json` |
| Cross-repo drift | `ready-implementation` | `L4` | `ready-implementation -> in-progress -> review-gate` | `drift-report.json`, `sync-summary.json` |
| Repeated failures | `blocked` | `L5` | `blocked -> review-gate -> done|blocked` | `replan-decision.md`, `transition-log.ndjson` |

### Missing Elements and Gap Closures
- **Category: Validation coverage**
  - Gap: `workflow_state`별 `loop_profile` 허용 범위가 일부 상태만 강제됨.
  - Closure: validator 상태 커버리지 확장 카드 추가(T1-3).
- **Category: Schema drift tolerance**
  - Gap: field 옵션 drift 시 runner crash 위험.
  - Closure: drift fail-safe + reconcile 정책 문서화(T1-3).
- **Category: Gate ambiguity**
  - Gap: `inconclusive` 처리 기준이 정량화 부족.
  - Closure: 2회 연속 inconclusive 시 replan 강제(T1-4/T1-5).

### Critical Questions Requiring Clarification and Defaults
1. **Critical:** `schema_drift_recovery_time_p95` 목표값은 얼마인가?
- Default: Track 1 파일럿 동안은 `<= 24h` 임시 기준 적용.
2. **Important:** `component` 분류에서 monday/infra 작업을 어떻게 투영할 것인가?
- Default: 현재 schema 유지(`runtime`/`orchestrator`로 투영), schema v3에서 재평가.
3. **Important:** Gate verdict 승인자는 누구인가?
- Default: planning owner 1인 + execution owner 1인 공동 승인.

## Hard Gate Contract
### `Track 1 Exit Gate` (must-pass)
아래 3개를 모두 만족해야 `Track 2`가 구현 단계로 이동 가능하다.

1. **Docs and contract integrity**
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all` 통과
- canonical/workbench 경로 계약 위반 0건

2. **Project schema integrity**
- `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch` 통과
- `component`, `initiative`, `target_repo`, `workflow_state`, `loop_profile` 필드 누락 0건

3. **Track 1 KPI evidence**
- `loop_success_rate >= 0.80`
- `replan_without_evidence = 0`
- `schema_drift_recovery_time_p95 <= 24h` (임시 기준)

### Gate Verdict
- `pass`: 3개 축 모두 충족
- `fail`: 1개라도 미충족
- `inconclusive`: 데이터 부족 또는 검증 실행 불완전

### Gate Failure Policy
- `fail` 또는 `inconclusive`면 Track 2는 prototype-only 유지
- `inconclusive` 2회 연속이면 `Recovery/Replan` 카드 자동 생성

## Kanban Operating Model
### Lane and WIP
- `L1 PlanningOps Reliability`: WIP 2
- `L2 Monday/Infra Prototype`: WIP 2
- `L3 Integration/Reconcile`: WIP 1
- `L4 Recovery/Replan`: WIP 1

WIP 초과 시 신규 pull 금지, 기존 카드 완료/차단 해소만 허용한다.

### Card Pull Policy
1. `Status=Todo`
2. `workflow_state in {ready-contract, ready-implementation}`
3. `depends_on` 충족
4. 상위 Gate 선행조건 충족

### Transition States
- `backlog`
- `ready-contract`
- `ready-implementation`
- `in-progress`
- `review-gate`
- `blocked`
- `done`

## Track 1: PlanningOps Reliability Proof
### Objective
계획/계약/검증/프로젝션 경계를 먼저 고정해 이후 구현 루프의 오류 증폭을 차단한다.

### Work Packages
#### T1-1. Contract and terminology lock
- 용어 사전 고정: `Planner`, `Runner`, `Verifier`, `loop_profile`, `replan_trigger`
- C1/C2/C8 소유 경계 재검토
- Output file: `docs/workbench/unified-personal-agent-platform/audits/track1-contract-terminology-lock.md`

#### T1-2. Verification chain hardening
- docs check + schema check + transition log validator를 단일 체인으로 점검
- Output file: `planningops/artifacts/validation/track1-validation-chain-report.json`

#### T1-3. Drift and reconcile policy
- field 누락/옵션 변경/상태 불일치 drift 대응 정책 고정
- todo #008/#009/#010 기반 회귀 시나리오 포함
- Output file: `docs/workbench/unified-personal-agent-platform/audits/track1-drift-reconcile-policy.md`

#### T1-4. KPI baseline capture
- 최소 10회 루프 또는 20개 카드 처리 기준 KPI 베이스라인 확보
- Output file: `planningops/artifacts/validation/track1-kpi-baseline.json`

#### T1-5. Gate verdict dry-run
- 실제 차단 없이 gate 판정만 연속 2회 실행해 재현성 검증
- Output file: `planningops/artifacts/validation/track1-gate-dryrun-report.json`

## Track 2: Monday/Infra Structure and Prototype
### Objective
Track 1 통과 전에는 설계/프로토타입으로만 불확실성을 축소한다.

### Allowed Before Gate Pass
- LiteLLM/LangFuse/NanoClaw 로컬 compose/profile 점검
- Monday 핵심 UX 1~2개 시나리오 정의
- NanoClaw/기존 에이전트 코드 분석 + target architecture draft

### Not Allowed Before Gate Pass
- 프로덕션 경로로 직접 연결되는 대규모 구현
- 계약 미고정 상태의 인터페이스 확장
- 다중 레포 동시 마이그레이션 실행

### Work Packages
#### T2-1. Monday target UX freeze
- 핵심 시나리오 1~2개 고정
- Output file: `docs/workbench/unified-personal-agent-platform/brainstorms/monday-target-ux-scenarios.md`

#### T2-2. Infra profile map
- local profile vs OCI profile 경계 및 migration trigger 정의
- Output file: `docs/workbench/unified-personal-agent-platform/audits/infra-profile-boundary-map.md`

#### T2-3. NanoClaw fit assessment
- 재사용/대체/폐기 후보 분류
- Output file: `docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md`

#### T2-4. Implementation readiness packet
- Gate 통과 후 첫 구현 스프린트 대신 첫 implementation packet 정의
- Output file: `docs/workbench/unified-personal-agent-platform/plans/track2-implementation-readiness-packet.md`

## Transition Log and Replan Triggers
### Required Transition Log Fields
- `transition_id`
- `run_id`
- `card_id`
- `from_state`
- `to_state`
- `transition_reason`
- `loop_profile`
- `verdict`
- `decided_at_utc`
- `replanning_flag`

### Replan Trigger Rules
1. 동일 `reason_code` 3회 반복 -> `Recovery/Replan` 카드 생성
2. `inconclusive` 2회 연속 -> `blocked` 전환 + 재계획 필수
3. `dependency_blocked` 임계 시간 초과 -> 의존성 분해 카드 생성
4. 동일 `schema_drift` 2회 재발 -> Gate 재판정 강제

### Replan SLA
- trigger 발생 후 24시간 이내 triage
- triage 이후 48시간 이내 verdict(`resume|split|stop`) 확정

## GitHub Project Integration
### Field Schema (Current Contract)
- `initiative` (text)
- `target_repo` (text, `owner/repo` 형식)
- `component` (single select): `planningops`, `contracts`, `provider_gateway`, `observability_gateway`, `runtime`, `orchestrator`
- `workflow_state` (single select): `backlog`, `ready-contract`, `ready-implementation`, `in-progress`, `review-gate`, `blocked`, `done`
- `loop_profile` (single select): `L1 Contract-Clarification`, `L2 Simulation`, `L3 Implementation-TDD`, `L4 Integration-Reconcile`, `L5 Recovery-Replan`
- `status` (single select): `Todo`, `In Progress`, `Blocked`, `Done`

### Component Mapping Policy (Track 2 interim)
- Monday UX/agent runtime 관련 카드 -> `runtime`
- orchestration/harness/run-loop 관련 카드 -> `orchestrator`
- LiteLLM/provider profile 연동 관련 카드 -> `provider_gateway`
- LangFuse/o11y 연동 관련 카드 -> `observability_gateway`
- contract/schema/compatibility 관련 카드 -> `contracts`
- planning governance/validation 관련 카드 -> `planningops`

### Status Mapping
- `backlog|ready-*` -> `Todo`
- `in-progress|review-gate` -> `In Progress`
- `blocked` -> `Blocked`
- `done` -> `Done`

### Sync Policy
- 문서/계약이 canonical source
- GitHub Project는 projection surface
- 불일치 감지 시 canonical 기준으로 보정

## Technical Approach
### Architecture
- Source of truth: initiative canonical docs + approved workbench plans
- Runtime decision engine: `planningops/scripts/issue_loop_runner.py`
- Schema enforcement: `planningops/scripts/validate_project_field_schema.py`
- Evidence storage: `planningops/artifacts/validation/*` + workbench audits/reviews

### Pseudo Contract Example
#### `planningops/contracts/track1-exit-gate.contract.json` (new)
```json
{
  "gate_id": "track1-exit-gate",
  "must_pass": [
    "uap_docs_profile_all",
    "project_schema_validation",
    "track1_kpi_thresholds"
  ],
  "verdict": ["pass", "fail", "inconclusive"]
}
```

## Implementation Phases (Gate-Sequenced)
### Phase A: Gate Definition Freeze
- Gate 계약, 체크리스트, 템플릿 경로 확정
- Exit: `track1-gate-evidence-manifest.md` 초안 생성

### Phase B: Track 1 Reliability Cycle
- T1-1 ~ T1-5 실행
- Exit: KPI baseline + dry-run verdict 재현성 확보

### Phase C: Gate Verdict
- `pass|fail|inconclusive` 판정
- Exit: `pass`이면 Phase D로 진입, 아니면 Recovery/Replan

### Phase D: Track 2 Prototype Cycle
- T2-1 ~ T2-4 실행
- Exit: implementation readiness packet 제출

### Phase E: Implementation Readiness Review
- Track 2 구현 착수 조건과 리스크 재평가
- Exit: implementation plan 분기(`go|hold|replan`) 확정

## Issue-Ready Backlog (Initial)
| execution_order | Title | Track | component | target_repo | workflow_state | loop_profile | depends_on | Primary output |
|---|---|---|---|---|---|---|---|---|
| 100 | Gate contract and terminology lock | T1 | planningops | rather-not-work-on/platform-planningops | ready-contract | L1 Contract-Clarification | - | `track1-contract-terminology-lock.md` |
| 110 | Validation chain runner and evidence manifest | T1 | planningops | rather-not-work-on/platform-planningops | ready-contract | L1 Contract-Clarification | 100 | `track1-validation-chain-report.json` |
| 120 | loop_profile drift and state-coverage hardening (#008/#009/#010) | T1 | planningops | rather-not-work-on/platform-planningops | ready-contract | L2 Simulation | 110 | `track1-drift-reconcile-policy.md` |
| 130 | Transition log schema and trigger evaluator alignment | T1 | orchestrator | rather-not-work-on/platform-planningops | ready-contract | L2 Simulation | 120 | `transition-log-contract-report.md` |
| 140 | KPI baseline capture run | T1 | planningops | rather-not-work-on/platform-planningops | ready-implementation | L3 Implementation-TDD | 130 | `track1-kpi-baseline.json` |
| 150 | Track 1 Exit Gate dry-run verdict x2 | T1 | planningops | rather-not-work-on/platform-planningops | review-gate | L3 Implementation-TDD | 140 | `track1-gate-dryrun-report.json` |
| 160 | Monday target UX freeze | T2 | runtime | rather-not-work-on/monday | ready-contract | L2 Simulation | 120 | `monday-target-ux-scenarios.md` |
| 170 | Infra local/OCI profile boundary map | T2 | provider_gateway | rather-not-work-on/platform-provider-gateway | ready-contract | L2 Simulation | 120 | `infra-profile-boundary-map.md` |
| 180 | LangFuse integration boundary map | T2 | observability_gateway | rather-not-work-on/platform-observability-gateway | ready-contract | L2 Simulation | 120 | `langfuse-boundary-map.md` |
| 190 | NanoClaw fit assessment and adapter strategy | T2 | orchestrator | rather-not-work-on/monday | ready-contract | L2 Simulation | 160,170,180 | `nanoclaw-fit-assessment.md` |
| 200 | Track 2 implementation readiness packet | T2 | runtime | rather-not-work-on/monday | ready-implementation | L3 Implementation-TDD | 150,190 | `track2-implementation-readiness-packet.md` |
| 210 | Recovery/Replan policy automation | cross | planningops | rather-not-work-on/platform-planningops | blocked | L5 Recovery-Replan | 150 | `replan-policy-automation-report.md` |

## Deliverables and Evidence Bundle
필수 산출물:
- `docs/workbench/unified-personal-agent-platform/audits/track1-gate-evidence-manifest.md`
- `planningops/artifacts/validation/track1-kpi-baseline.json`
- `planningops/artifacts/validation/project-field-schema-report.json`
- `planningops/artifacts/validation/transition-log.ndjson`
- `docs/workbench/unified-personal-agent-platform/plans/track2-implementation-readiness-packet.md`

모든 산출물은 workbench 경로에 보관하고 canonical 승격 전까지 운영 산출물로 취급한다.

## Dependencies and Prerequisites
- GitHub CLI 인증 및 project write 권한
- `planningops/config/project-field-ids.json` 최신화
- `uap-docs.sh`, `validate_project_field_schema.py` 실행 가능 환경
- local LiteLLM/LangFuse/NanoClaw 테스트 실행 환경

## Acceptance Criteria
### Functional Requirements
- [ ] `Track 1 Exit Gate` 판정 기준이 문서/체크리스트/프로젝트 필드에 일치한다.
- [ ] Gate fail/inconclusive 시 Track 2 구현 확장이 차단된다.
- [ ] Replan trigger가 전이로그로 재현 가능하다.
- [ ] Project 필드와 실행 상태 매핑 drift가 자동 탐지된다.
- [ ] 초기 backlog 12개 카드가 execution_order/depends_on을 포함해 등록 가능하다.

### Non-Functional Requirements
- [ ] 동일 입력에서 동일 gate verdict를 재현한다.
- [ ] 로컬 프로파일 기준 실행 절차가 OCI 프로파일로 이행 가능하다.
- [ ] 용어 불일치(`Executor/Worker` 등) 없이 문서 전반이 일관된다.

### Quality Gates
- [ ] `uap-docs.sh check --profile all` 통과
- [ ] `validate_project_field_schema.py --fail-on-mismatch` 통과
- [ ] gate dry-run 2회에서 verdict 불일치 0건
- [ ] replan trigger without transition log = 0건

## Success Metrics
- `gate_verdict_reproducibility` = 100%
- `projection_drift_incidents_per_week <= 1`
- `replan_trigger_without_transition_log = 0`
- `prototype_to_impl_rework_rate` 감소 추세 유지

## Alternative Approaches Considered
- **Approach A: PlanningOps only first**
  - 장점: 안정성 최대화
  - 단점: 제품 체감 진척 지연
- **Approach B: Monday/Infra first**
  - 장점: 데모 속도
  - 단점: 계약/정합 재작업 위험
- **Chosen: Approach C (Two-Track + Hard Gate)**
  - 이유: 속도와 안정성의 균형, 경계 붕괴 방지

## Risk Analysis and Mitigation
- Risk: Gate 기준 과도 엄격으로 진행 정체
- Mitigation: `inconclusive` 경로 분리, 재판정 SLA 고정

- Risk: Track 2가 Gate 이전에 구현으로 팽창
- Mitigation: 허용/금지 작업을 카드 템플릿에 고정

- Risk: field schema drift로 sync 실패
- Mitigation: report-only 1회 후 hard-fail 전환

- Risk: component taxonomy 불일치(monday/infra vs current enum)
- Mitigation: interim mapping policy 적용 후 schema v3 개선 카드 별도 분리

## Documentation Plan
- workbench 운영 산출물 작성 후 canonical 승격 후보를 분리한다.
- 승격 후보는 `docs/initiatives/unified-personal-agent-platform/30-execution-plan` 또는 `40-quality`로 반영한다.
- 승격 이후 해당 workbench 문서는 `status: reference`로 전환한다.

## References and Research
### Internal References
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-02-uap-post-waveb-next-phase-brainstorm.md`
- `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md`
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/uap-github-planningops-sync.execution-plan.md`
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md`
- `planningops/config/project-field-ids.json`
- `planningops/scripts/issue_loop_runner.py`
- `planningops/scripts/validate_project_field_schema.py`
- `todos/008-pending-p2-loop-profile-l2-unreachable.md`
- `todos/009-pending-p2-loop-profile-field-drift-crash.md`
- `todos/010-pending-p3-loop-profile-validator-state-coverage-gap.md`

### External References
- 없음 (이번 pass는 내부 정합성 강화 범위)

## Next Actions
1. Issue-Ready Backlog 12개를 Project에 등록하고 `execution_order` 순서대로 정렬한다.
2. Track 1 evidence 템플릿 파일부터 생성한다.
3. Gate dry-run 2회 수행 후 `pass|fail|inconclusive`를 확정한다.
4. Gate `pass` 전까지 Track 2는 prototype-only 규칙을 유지한다.

## Execution Progress
- [x] Register issue-ready backlog 12 cards to GitHub Project
- [x] Create Track 1 evidence template files
- [x] Run Track 1 gate dry-run twice and capture reports
- [x] Re-run docs/schema quality checks and summarize readiness
