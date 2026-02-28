---
title: audit: Ralph Loop Issue Resolution Loop Simulation
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Simulates end-to-end behavior of the Ralph Loop issue-resolution UX across issue intake, execution, verification, and GitHub project feedback updates.
---

# audit: Ralph Loop Issue Resolution Loop Simulation

## Scope
이 문서는 `platform-planningops` 이슈(#2~#12)를 Ralph Loop가 자동으로 가져가 해결하는 운영 흐름을 시뮬레이션한다.
기준 문서는 다음이다.

- `docs/workbench/unified-personal-agent-platform/plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md`
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/uap-github-planningops-sync.execution-plan.md`

## Simulation Assumptions
- 날짜 기준: `2026-02-28` 이후 실행
- 프로젝트 필드: `Status`, `execution_order`, `plan_lane`, `component`, `initiative`, `target_repo`
- intake 규칙: `Status=Todo` + `execution_order` 오름차순 + `depends_on` 충족
- 루프 산출물: `intake-check.json`, `simulation-report.md`, `verification-report.json`, `transition-log.ndjson`

## End-to-End Loop Model
1. Intake
- 다음 후보 이슈를 조회한다.
- `depends_on` 미충족이면 `blocked` 판정 후 다음 이슈로 넘어간다.

2. Context Load
- ECP(Execution Context Pack)와 contract refs를 로드한다.
- 필수 입력 누락 시 즉시 `fail`.

3. Execute
- 로컬 하네스(Phase 1)로 작업을 수행한다.
- dry-run/apply 모드 중 정책에 맞는 모드를 사용한다.

4. Verify
- 검증 스크립트가 요구사항 충족 여부를 점검한다.
- verdict는 `pass/fail/inconclusive` 중 하나로 고정한다.

5. Feedback
- 이슈 코멘트에 결과를 남긴다.
- Project field(`Status`, `last_verdict` 확장 시 포함)를 업데이트한다.
- 재계획 트리거 충족 시 follow-up card를 생성한다.

## Sequence Simulation (Issue #2 -> #12)
### S1: Bootstrap / Problem-Contract Freeze
대상: #2 -> #7 -> #8

예상 동작:
- #2 완료 후 metadata/owner/preflight 기준이 고정된다.
- #7에서 문제정의/요구사항 계약이 고정되어 루프 검증 기준이 명확해진다.
- #8에서 하네스 토폴로지가 `local scripts first`로 확정된다.

예상 산출물:
- `planningops/contracts/problem-contract.md`
- `planningops/contracts/requirements-contract.md`
- `planningops/adr/adr-harness-topology.md`

판정:
- 세 이슈 모두 `pass`면 M0 lane은 `Done` 또는 `In Progress -> Done`으로 수렴.

### S2: Contract + Template Baseline
대상: #3 + #6

예상 동작:
- #3에서 C1~C5 schema/validator가 고정된다.
- #6에서 ECP/시뮬레이션 템플릿이 고정된다.
- 이후 루프는 "입력 계약 + 검증 계약"을 공통 프레임으로 사용한다.

예상 산출물:
- `platform-contracts/schemas/*.json`
- `planningops/templates/ecp-template.md`
- `planningops/templates/simulation-template.md`

판정:
- schema 테스트와 템플릿 체크리스트가 모두 통과하면 `pass`.
- schema는 통과했지만 ECP 필드 누락이 있으면 `inconclusive`.

### S3: Loop Runtime MVP
대상: #4 -> #9 -> #10

예상 동작:
- #4 parser/diff/dry-run 완료로 루프의 입력 처리 파이프라인이 준비된다.
- #9에서 로컬 Ralph Loop 하네스가 루프 1회 실행을 수행한다.
- #10에서 전이로그/검증 스크립트가 결과를 판정한다.

예상 산출물:
- `planningops/src/parser/*`
- `planningops/src/loop/harness.*`
- `planningops/src/verify/verify_loop.*`
- `planningops/artifacts/transition-log/<date>.ndjson`

판정:
- dry-run/apply 분기 + 전이로그 무결성 + verdict 산출이 되면 `pass`.

### S4: GitHub Integration
대상: #5 + #12 + #11

예상 동작:
- #5에서 GitHub adapter와 idempotency replay가 준비된다.
- #12에서 CI 체인(`validate-contracts -> dry-run`)이 병합 게이트가 된다.
- #11에서 intake/feedback 자동 반영이 연결되어 UX가 완성된다.

예상 산출물:
- `.github/workflows/planningops-sync.yml` (또는 동등 체인)
- 이슈 코멘트 자동 기록 로그
- 프로젝트 필드 자동 업데이트 로그

판정:
- 중복 생성 0%, idempotent convergence 100%, verdict 반영 성공이면 `pass`.

## Example Transition Log (Simulated)
```ndjson
{"transition_id":"t-001","issue":2,"from":"Todo","to":"In Progress","reason":"intake-selected","verdict":null}
{"transition_id":"t-002","issue":2,"from":"In Progress","to":"Done","reason":"preflight-complete","verdict":"pass"}
{"transition_id":"t-003","issue":7,"from":"Todo","to":"In Progress","reason":"depends-satisfied","verdict":null}
{"transition_id":"t-004","issue":7,"from":"In Progress","to":"Done","reason":"problem-contract-frozen","verdict":"pass"}
{"transition_id":"t-005","issue":11,"from":"Todo","to":"Blocked","reason":"depends_on #12 not done","verdict":"inconclusive"}
```

## Failure Path Simulation
### F1: ECP 누락
- 현상: intake는 성공했지만 Context Load에서 필수 필드 누락
- 결과: `fail`, 이슈 상태 `Blocked`, 원인 `context`
- 조치: #6 산출물에서 ECP 템플릿 보강 후 재실행

### F2: idempotency 충돌
- 현상: 동일 이슈 재실행 시 중복 issue update 발생
- 결과: `fail`, 원인 `idempotency_conflict`
- 조치: #5에서 dedupe key 생성 규칙 강화

### F3: CI 체인 미연결
- 현상: 로컬은 pass인데 PR에서 dry-run 누락
- 결과: `inconclusive` -> 운영상 `fail` 취급
- 조치: #12 완료 전 #11 전진 금지

## Replanning Trigger Simulation
아래 조건이 충족되면 자동으로 follow-up issue를 생성하도록 설계한다.

- 동일 실패 사유 3회 반복
- `inconclusive` 2회 연속
- `ready` 또는 `blocked` 상태 24시간 초과
- contract drift(C1~C8 변경) 감지

생성 이슈 형태(예시):
- `fix: loop verification false-negative on issue intake`
- `chore: strengthen idempotency key derivation for project updates`

## Expected UX After Implementation
- 사용자는 planningops에 이슈만 등록/정렬하면 된다.
- Ralph Loop가 순서대로 가져가 실행/검증/보고를 반복한다.
- 실패는 자동으로 분류되어 재계획 이슈로 전환된다.
- 프로젝트 보드에서 현재 실행 상태와 병목 지점을 바로 볼 수 있다.

## Readiness Verdict (Simulation)
- 현재 설계 기준 verdict: `provisionally-pass`
- 이유:
  - 문제정의/요구사항/검증/피드백 루프가 문서/이슈로 연결됨
  - 실행 순서와 의존성 모델이 명시됨
- 남은 핵심 리스크:
  - GitHub API rate limit 및 권한 실패 시 fallback runbook 강화 필요
  - transition-log 기반 자동 재계획 트리거의 오탐률 보정 필요

## Recommended Immediate Next Runs
1. #7, #8을 먼저 완료해 입력 계약과 하네스 경계를 확정
2. #9, #10으로 로컬 루프 MVP를 실제 1회 실행
3. #12를 먼저 완료해 PR 게이트를 고정한 뒤 #11 연결
