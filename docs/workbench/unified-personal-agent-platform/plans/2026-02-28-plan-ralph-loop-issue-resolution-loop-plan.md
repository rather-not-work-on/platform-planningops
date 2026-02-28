---
title: plan: Ralph Loop Issue Resolution Loop and Harness Strategy
type: plan
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines problem/requirement contracts, per-loop verification, document topology, and harness topology decisions for autonomous Ralph Loop issue resolution.
---

# plan: Ralph Loop Issue Resolution Loop and Harness Strategy

## Goal
`platform-planningops`에 등록된 이슈를 Ralph Loop가 주기적으로 가져와 해결 시도하고, 각 루프마다 검증 가능한 증빙을 남긴다.

## Problem Definition
현재 이슈는 등록/정렬은 되어 있지만, 에이전트가 반복적으로 가져가 해결하는 실행 루프 계약이 없다.
이로 인해 아래가 불명확하다.

- 어떤 이슈를 먼저 가져올지(우선순위/의존성)
- 한 루프에서 무엇을 완료로 볼지(검증 규칙)
- 실패 시 어떻게 중단/재계획할지(전이 로그/트리거)

## Target UX
1. 사용자가 planningops 문서와 이슈를 갱신한다.
2. Ralph Loop가 `Todo` 이슈를 선택해 루프 1회를 수행한다.
3. 결과를 검증 스크립트가 판정한다(`pass/fail/inconclusive`).
4. 결과가 이슈 코멘트 + Project field로 반영된다.
5. 실패/충돌 시 재계획 트리거가 자동 생성된다.

## Functional Requirements
- 이슈 intake 규칙: `execution_order` 오름차순 + `depends_on` 충족 필수
- 루프 입력 계약: objective, contract refs, source docs, acceptance checks
- 루프 출력 계약: patch summary, verification report, transition log, next action
- 판정 계약: `pass/fail/inconclusive` + reason code
- 프로젝트 반영: status, lane, execution order, last verdict

## Non-Functional Requirements
- 같은 이슈 재실행 시 중복 처리 방지(idempotency key)
- 루프별 최대 실행시간/재시도 상한 강제
- 실패 재현 가능한 로그 보관(JSON + markdown summary)
- 로컬 스크립트만으로 최소 루프 재현 가능

## Per-Loop Validation Contract
각 루프는 아래 4개 산출물이 없으면 무효 처리한다.

1. `intake-check.json`
2. `simulation-report.md`
3. `verification-report.json`
4. `transition-log.ndjson`

판정 규칙:
- 필수 산출물 누락: `fail`
- 요구사항 일부만 충족: `inconclusive`
- 요구사항/증빙 모두 충족: `pass`

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
  - 주 10회 이상 반복 실행
  - 동일 실패 유형 3회 이상 반복
  - 다중 레포 동시 처리 필요 발생

## Execution Backlog (Issue Mapping)

| Order | Issue | Purpose |
|---|---|---|
| 10 | [#2](https://github.com/rather-not-work-on/platform-planningops/issues/2) | bootstrap metadata/owner/preflight |
| 12 | [#7](https://github.com/rather-not-work-on/platform-planningops/issues/7) | 문제정의/요구사항 계약 확정 |
| 14 | [#8](https://github.com/rather-not-work-on/platform-planningops/issues/8) | 하네스 토폴로지 의사결정(ADR) |
| 20 | [#3](https://github.com/rather-not-work-on/platform-planningops/issues/3) | C1~C5 계약 스키마 |
| 22 | [#6](https://github.com/rather-not-work-on/platform-planningops/issues/6) | ECP/시뮬레이션 템플릿 |
| 30 | [#4](https://github.com/rather-not-work-on/platform-planningops/issues/4) | parser/diff/dry-run |
| 35 | [#9](https://github.com/rather-not-work-on/platform-planningops/issues/9) | 로컬 Ralph Loop 하네스 |
| 40 | [#5](https://github.com/rather-not-work-on/platform-planningops/issues/5) | GitHub adapter baseline |
| 42 | [#10](https://github.com/rather-not-work-on/platform-planningops/issues/10) | 루프 검증 스크립트/전이로그 검사 |
| 45 | [#12](https://github.com/rather-not-work-on/platform-planningops/issues/12) | `validate-contracts -> dry-run` CI 체인 |
| 48 | [#11](https://github.com/rather-not-work-on/platform-planningops/issues/11) | GitHub issue intake + feedback update |

## Definition of Ready (for each loop)
- depends_on 이슈 완료 또는 명시적 우회 승인
- ECP 필수 필드 충족
- target docs/contract refs 명시
- 검증 스크립트 실행 가능 상태

## Definition of Done (for each loop)
- 변경 요약 + 검증 리포트 + 전이로그 생성
- 이슈 코멘트에 결과 기록
- 프로젝트 필드(status/verdict) 반영
- 실패 시 재계획 트리거 생성 또는 blocker 등록

## Next Step
1. #7, #8을 먼저 완료해 문제정의/토폴로지 결정을 고정한다.
2. #9, #10으로 로컬 루프 MVP를 만든다.
3. #11에서 GitHub intake/feedback 자동 반영을 연결한다.
