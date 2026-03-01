---
title: plan: Ralph Loop Issue Resolution Loop and Harness Strategy
type: plan
date: 2026-02-28
updated: 2026-03-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Deepened plan for situation-driven loop selection, per-loop verification contracts, replan triggers, and GitHub Project schema integration.
---

# plan: Ralph Loop Issue Resolution Loop and Harness Strategy

## Enhancement Summary
**Deepened on:** 2026-03-01  
**Scope expanded:** single-loop MVP -> loop-catalog operating model (`L1~L5`)  
**Research and review lenses applied:** agent-native architecture, spec flow analysis, architecture integrity, security, performance

### Key Improvements
1. 단일 루프 운영에서 상황 기반 루프 선택 정책으로 확장했다.
2. 루프별 종료조건/증빙/재계획 트리거를 분리해 반복 실패 전파를 줄이도록 설계했다.
3. GitHub Project 필드 스키마(`component`, `target_repo`, `initiative`)에 `loop_profile`을 추가하는 확장안을 포함했다.
4. 비정기 실행 전제에 맞게 스프린트형이 아닌 Kanban pull + WIP 제한 운영으로 명시했다.
5. 장기 자율 실행 안정성을 위해 bounded Sisyphus guardrails(`attempt budget`, `checkpoint/resume`, `lease lock`, `watchdog`, `escalation gate`)를 단계적으로 도입하도록 확장했다.

### External Practice Signals Incorporated
- Kanban WIP 제한은 병목 가시화와 완료 중심 흐름 유지에 유효하다.  
  - [Atlassian: WIP limits](https://www.atlassian.com/agile/kanban/wip-limits)
- TDD는 Red-Green-Refactor의 짧은 피드백 루프로 설계/구현 품질을 높인다.  
  - [Martin Fowler: Test Driven Development (2023-12-11)](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- 신뢰성 운영은 오류예산 기반으로 변경 동결/재계획 기준을 고정하는 것이 효과적이다.  
  - [Google SRE Workbook: Error Budget Policy](https://sre.google/workbook/error-budget-policy/)
- GitHub Projects 자동 추가는 기존 항목 소급(backfill)을 하지 않으므로 reconcile 루프가 별도로 필요하다.  
  - [GitHub Docs: Adding items automatically](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/adding-items-automatically)
- Project field 갱신은 GraphQL mutation(`updateProjectV2ItemFieldValue`) 기반으로 타입별 제약을 지킨다.  
  - [GitHub GraphQL Mutations](https://docs.github.com/en/graphql/reference/mutations)
  - [GitHub Docs: Understanding fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields)

## Section Manifest
1. **Operating Context**: 왜 단일 루프가 부족한지와 목표 운영 모델
2. **Loop Catalog**: `L1~L5` 루프 정의(진입/종료/증빙)
3. **Selector Policy**: 어떤 상황에서 어떤 루프를 선택할지
4. **Verification & Replan Contract**: 전이로그/판정/재계획 트리거
5. **GitHub Schema Integration**: Project 필드 스키마 확장
6. **Harness Topology**: 로컬 우선 + 클라우드 전환 경로
7. **Kanban Execution Plan**: 실행 순서, WIP, 수용 기준

## Goal
`platform-planningops`에 등록된 이슈를 에이전트가 비정기적으로 pull해 처리하되, 이슈 성격에 맞는 루프(`L1~L5`)를 선택해 해결될 때까지 반복한다.  
모든 루프는 검증 가능한 증빙을 남기고, 실패 시 자동 재계획 경로를 생성한다.

## Problem Definition
현재 구조는 `issue_loop_runner -> ralph_loop_local -> verify_loop_run`의 단일 실행 경로가 강해서, 문제 유형별로 적합한 피드백 루프를 강제하지 못한다.

이로 인해 아래가 불명확하거나 과도하게 일반화된다.

- 어떤 이슈를 먼저 가져올지(우선순위/의존성)
- 어떤 유형의 루프를 써야 수렴이 빠른지(선택 규칙)
- 루프별 완료 기준과 증빙이 무엇인지(검증 규칙)
- 반복 실패 시 언제 재계획을 강제할지(전이로그/트리거)

## Target UX
1. 사용자가 planningops 문서와 이슈를 갱신한다.
2. `issue_loop_runner`가 `Status=Todo` + `workflow_state in {ready-contract, ready-implementation}` 카드 중 우선순위/의존성을 만족하는 카드를 pull한다.
3. selector가 카드 신호를 기반으로 `loop_profile(L1~L5)`를 결정한다.
4. 선택된 루프를 1회 실행하고 증빙을 생성한다.
5. `verify_loop_run`이 `pass|fail|inconclusive`를 판정한다.
6. 결과가 issue comment + project fields(`Status`, `workflow_state`, `last_verdict`, `last_reason`, `loop_profile`)로 반영된다.
7. 실패 누적 시 자동 replan trigger가 생성되어 backlog 재정렬로 복귀한다.

## Loop Catalog (Phase 1)
| Loop | Purpose | Entry Signals | Exit Condition | Required Evidence |
|---|---|---|---|---|
| `L1 Contract-Clarification` | 목표/요구사항/완료조건 고정 | `missing_input`, 문서 모호성, DoR 미충족 | Problem/Requirements contract 충족, Open question 0 | `intake-check.json`, `contract-gap-report.md`, `verification-report.json` |
| `L2 Simulation` | 구현 전 경우의 수/실패 전이 검증 | high uncertainty, dependency ripple risk | 시나리오/반박 루프 문서화 완료, gate 가정 고정 | `simulation-report.md`, `scenario-matrix.json`, `verification-report.json` |
| `L3 Implementation-TDD` | 코드/동작 수렴 | 요구사항 고정 + 구현 필요 + 회귀 위험 | 테스트 추가/통과 + 품질 체크 통과 | `patch-summary.md`, `test-report.json`, `verification-report.json` |
| `L4 Integration-Reconcile` | multi-repo/projection 정합 | field mismatch, drift, cross-repo sync change | dry-run/apply/reconcile 수렴, drift 허용범위 이내 | `sync-summary.json`, `drift-report.json`, `verification-report.json` |
| `L5 Recovery-Replan` | 반복 실패에서 운영 복구 | 동일 reason 반복, inconclusive 연속, 권한/의존성 block 장기화 | blocker 해소 또는 replan issue/ADR 생성 완료 | `replan-decision.md`, `transition-log.ndjson`, `verification-report.json` |

## Selector Policy (Situation -> Loop)
### Default Mapping
- 요구사항 모호/컨텍스트 결손: `L1 -> L2`
- 계약 변경/경계 불안정: `L2 -> L4`
- 버그/회귀/기능 구현: `L3`
- 동기화 불일치/필드 매핑 문제: `L4`
- 반복 실패/하드스톱: `L5`

### Deterministic Rule Set
1. `reason_code in {missing_input, dependency_blocked}`이면 `L1` 우선.
2. `workflow_state=ready-contract`이면 기본 `L1`, 단 시뮬레이션 필요 플래그가 있으면 `L2`.
3. `workflow_state=ready-implementation`이고 acceptance가 고정되면 `L3`.
4. `target_repo`가 control repo 외부이거나 projection drift가 감지되면 `L4`.
5. 동일 이슈에서 `inconclusive` 2회 연속 또는 동일 `reason_code` 3회면 `L5`.

### WIP Policy (Kanban)
- Contracts lane(L1/L2): max 2
- Runtime lane(L3): max 2
- Integration lane(L4): max 2
- Recovery lane(L5): max 1

WIP 초과 시 신규 pull 금지, blocker 해소 작업만 허용한다.

## Functional Requirements
- intake 규칙: `execution_order` 오름차순 + `depends_on` 충족 필수
- selector 규칙: issue metadata + transition history + failure taxonomy를 입력으로 `loop_profile` 결정
- 루프 입력 계약: objective, contract refs(C1~C8), source docs, acceptance checks
- 루프 출력 계약: per-loop required artifacts + `verification-report.json`
- 판정 계약: `pass|fail|inconclusive` + reason code
- 프로젝트 반영: `Status`, `workflow_state`, `last_verdict`, `last_reason`, `loop_profile`
- 재계획 계약: trigger 충족 시 `replan-decision.md`와 follow-up issue 생성/연결

## Non-Functional Requirements
- 같은 이슈 재실행 시 중복 처리 방지(idempotency key)
- 루프별 최대 실행시간/재시도 상한 강제
- 실패 재현 가능한 로그 보관(JSON + markdown summary)
- 비정기 실행에서도 deterministic selection trace 보존
- 로컬 우선 운영 + profile 전환으로 Oracle Cloud 이행 가능
- least privilege 토큰/권한 모델 유지

## Per-Loop Validation Contract (Expanded)
모든 루프는 공통 산출물 4개를 필수로 생성한다.

1. `intake-check.json`
2. `simulation-report.md`
3. `verification-report.json`
4. `transition-log.ndjson`

루프별 추가 산출물:
- `L1`: `contract-gap-report.md`
- `L2`: `scenario-matrix.json`
- `L3`: `test-report.json`
- `L4`: `sync-summary.json`, `drift-report.json`
- `L5`: `replan-decision.md`

판정 규칙:
- 필수 산출물 누락: `fail`
- 요구사항 일부만 충족: `inconclusive`
- 요구사항/증빙 모두 충족: `pass`

## Transition Log and Replan Trigger Contract
전이로그는 최소 필드(`transition_id, run_id, card_id, from_state, to_state, transition_reason, actor_type, actor_id, decided_at_utc, replanning_flag`)를 유지한다.

재계획 트리거:
1. 동일 `reason_code` 3회 반복 -> follow-up issue 생성 + `L5` 강제
2. `inconclusive` 2회 연속 -> `workflow_state=blocked` + `L5` 강제
3. `dependency_blocked` 24시간 초과 -> dependency 분해 또는 owner 재지정
4. `permission_denied` 재시도 후 실패 -> 권한 복구 이슈 자동 생성

SRE식 운영 가드레일(적용 방식):
- 4주 기준 실패 예산(예: fail+inconclusive 비율)이 임계치 초과 시 신규 feature loop(`L3`) pull을 일시 중단하고 안정화 루프(`L1/L4/L5`) 우선 처리한다.

## Document Topology (Proposed)

### Canonical (rules/contracts)
- `docs/initiatives/unified-personal-agent-platform/20-architecture/*`
  - problem/requirement contract
  - harness boundary contract
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/*`
  - loop orchestration steps
  - issue intake/update policy
- `docs/initiatives/unified-personal-agent-platform/40-quality/*`
  - validation checklist
  - verdict and escalation policy

### Workbench (operations/runs)
- `docs/workbench/unified-personal-agent-platform/plans/*`
  - 실행 순서/의존성 계획
- `docs/workbench/unified-personal-agent-platform/audits/*`
  - 루프 실행 결과
- `docs/workbench/unified-personal-agent-platform/reviews/*`
  - 회귀/실패 분석

### Path Reference Rule
- 문서 본문 경로: initiative 루트 상대경로 우선
- 실행 명령 경로: repo 루트 상대경로 사용
- 동일 표/목록 내부에서 두 기준 혼용 금지

## GitHub Project Schema Integration
기존 필수 필드(`initiative`, `component`, `target_repo`, `execution_order`, `workflow_state`)는 유지한다.

Phase 1 확장 필드:
- `loop_profile` (single select): `L1`, `L2`, `L3`, `L4`, `L5`
- `last_loop_started_at` (date/text)
- `last_loop_finished_at` (date/text)
- `last_reason` (text)

동기화 규칙:
1. selector 결정 직후 `loop_profile` 업데이트
2. 루프 시작 시 `last_loop_started_at` 기록
3. verifier 완료 시 `last_loop_finished_at`, `last_verdict`, `last_reason` 기록
4. `Status`/`workflow_state`는 기존 매핑 계약 유지

주의:
- built-in auto-add는 기존 항목 소급이 안 되므로 nightly reconcile에서 누락 항목을 보정한다.
- field update는 `updateProjectV2ItemFieldValue` 타입 제약을 준수한다.

## Harness Topology Decision

### Option A: dedicated harness repository
- 장점: 런타임 독립성, 배포/권한 경계 명확
- 단점: 초기 세팅 비용과 운영 복잡도 증가

### Option B: existing repo internal harness
- 장점: 코드/컨텍스트 접근 빠름
- 단점: 경계 오염 가능성, 책임 혼합

### Option C: local scripts first (recommended now)
- 장점: 가장 빠른 검증, 리스크 낮음, 즉시 반복 가능
- 단점: 운영 자동화/재사용성은 제한적

### Decision
- Phase 1: Option C(로컬 스크립트) 채택
- Phase 2: 안정화 후 Option B 또는 A로 승격
- 재평가 트리거:
  - 누적 10회 이상 loop 실행
  - 동일 실패 유형 3회 이상 반복
  - 다중 레포 동시 처리 필요 발생

## Execution Plan (Kanban, 2026-03)
### Phase A: Selector Foundation (Milestone A)
1. `issue_loop_runner`에 `loop_profile` 선택 로직 + selection trace 확장
2. `planningops/contracts`에 selector 결정표 반영
3. `validate_project_field_schema.py`에 `loop_profile` 필수 검증 추가

### Phase B: Per-Loop Evidence Split (Milestone B)
1. `verify_loop_run.py`에서 loop별 required artifacts 체크
2. `planningops/quality/loop-verification-checklist.md`를 loop별 체크리스트로 확장
3. `L5`용 replan decision artifact 템플릿 추가

### Phase C: GitHub Integration + Reconcile (Milestone C)
1. project field 스키마 확장(`loop_profile`, timestamps)
2. feedback update 루틴에 loop_profile/시간 필드 반영
3. nightly reconcile에서 누락 카드/필드 보정

### Phase D: Bounded Sisyphus Guardrails (Milestone D)
1. issue 단위 budget 계약(`max_attempts`, `max_duration_minutes`, `max_token_budget`) 추가
2. checkpoint/resume 아티팩트와 재개 로직 추가
3. lease lock + watchdog으로 중복/좀비 실행 방지
4. escalation gate(`same reason x3`, `inconclusive x2`)와 auto-pause 전이 추가

### Phase E: Pilot and Tune (Milestone E)
1. 비정기 실행 파일럿 운영(최소 10회 loop 또는 20개 카드 처리)
2. KPI 측정: lead time, retry count, replan rate, drift recovery time
3. WIP limits/selector 규칙 미세 조정

## Issue Alignment (`2026-03-01`)
| Execution Order | Issue | Work Item |
|---|---|---|
| 220 | #25 | repo-specific execution adapter hooks |
| 230 | #26 | local LiteLLM stack launcher |
| 240 | #27 | local LangFuse stack launcher |
| 250 | #28 | C1~C8 consumer conformance checks |
| 260 | #29 | scheduler-runner integration handoff |
| 265 | #32 | bounded Sisyphus guardrails |
| 270 | #30 | federated CI check matrix |
| 280 | #31 | 7-day local-first pilot + Oracle rehearsal |

## Definition of Ready (for each loop)
- depends_on 이슈 완료 또는 명시적 우회 승인
- ECP 필수 필드 충족
- target docs/contract refs 명시
- 검증 스크립트 실행 가능 상태
- `loop_profile` 결정 가능(또는 기본값 정책 존재)

## Definition of Done (for each loop)
- 변경 요약 + 검증 리포트 + 전이로그 생성
- 이슈 코멘트에 결과 기록
- 프로젝트 필드(status/verdict/loop_profile) 반영
- 실패 시 재계획 트리거 생성 또는 blocker 등록

## Acceptance Criteria (Deepened)
- [ ] selector가 동일 입력에서 동일 `loop_profile`을 결정한다.
- [ ] loop별 required artifacts 누락 시 반드시 `fail`로 판정된다.
- [ ] `loop_profile`이 project card에 누락 없이 반영된다.
- [ ] `inconclusive x2` 및 `same reason x3` 트리거가 `L5`로 전환된다.
- [ ] WIP 초과 시 신규 pull이 차단된다.
- [ ] budget 초과 시 auto-pause가 deterministic하게 기록된다.
- [ ] 중단 이후 checkpoint 기반 resume이 deterministic하게 동작한다.
- [ ] 파일럿 기준(최소 10회 loop 또는 20개 카드)에서 무한 재시도/중복 업데이트 0건을 유지한다.

## Risks and Mitigations
- Risk: selector 규칙 과적합으로 잘못된 루프 선택
  - Mitigation: selection trace 저장 + 샘플 리뷰 + 규칙 버전 관리
- Risk: 필드 스키마 변경으로 GitHub 업데이트 실패
  - Mitigation: field schema validator 선행 + dry-run gate
- Risk: L5 남용으로 실제 구현 지연
  - Mitigation: L5 진입 기준 엄격화 + owner 승인 필요
- Risk: local-only assumptions가 cloud 전환 때 붕괴
  - Mitigation: runtime profile 계약 불변 유지 + profile switch smoke

## Next Step
1. 이 문서를 기준으로 `workflows-plan`에서 실행 이슈(카드) 단위로 쪼갠다.
2. `loop_profile` 필드 스키마/검증/동기화를 먼저 구현한다.
3. 이후 `selector -> verifier -> replan` 순서로 단계적 적용한다.
