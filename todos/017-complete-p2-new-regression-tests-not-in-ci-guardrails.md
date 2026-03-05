---
status: complete
priority: p2
issue_id: "017"
tags: [code-review, quality, testing, ci, planningops]
dependencies: []
---

# New Gate/Bootstrap Regression Tests Are Not Included in CI Guardrails

이번 변경에서 추가된 회귀 테스트 스크립트 2개가 CI 및 로컬 federated guardrail 실행 목록에 포함되지 않아, 동일 결함 재유입 시 자동 탐지가 되지 않는다.

## Problem Statement

회귀 테스트는 코드가 아닌 실행 경로에 연결되어야 보호 효과가 생긴다. 현재는 테스트 파일만 추가되어 있고 정기 실행 체인에 wiring되지 않아, P1/P2 성격 결함의 재발을 CI가 놓칠 수 있다.

## Findings

- 신규 테스트 파일:
  - `planningops/scripts/test_track1_gate_dryrun_contract.sh`
  - `planningops/scripts/test_bootstrap_two_track_backlog_contract.sh`
- 그러나 guardrail 실행 목록에는 두 테스트가 없다.
  - `.github/workflows/federated-ci-matrix.yml:98-104`
  - `planningops/scripts/federated_ci_matrix_local.sh:57-58`

## Proposed Solutions

### Option 1: Existing loop-guardrails 단계에 테스트 2개 추가

**Approach:** 현재 guardrail 명령 체인 끝에 두 테스트를 추가한다.

**Pros:**
- 변경 범위 최소
- 즉시 회귀 보호 가능

**Cons:**
- 단계 실행 시간 증가

**Effort:** Small

**Risk:** Low

---

### Option 2: Gate/Bootstrap contract test 묶음 스크립트 생성 후 단일 호출

**Approach:** `test_track1_contracts.sh` 같은 집계 스크립트로 통합하고 CI는 단일 엔트리만 호출한다.

**Pros:**
- 유지보수성 향상
- 테스트 목록 관리 일원화

**Cons:**
- 스크립트 1개 추가 필요

**Effort:** Small

**Risk:** Low

---

### Option 3: 빠른 PR 경로와 nightly 경로로 테스트 분리

**Approach:** PR에는 최소 smoke, nightly에 full contract 스위트 실행.

**Pros:**
- PR 대기시간 최적화
- 장기 안정성 확보

**Cons:**
- 스케줄/워크플로 관리 복잡도 증가

**Effort:** Medium

**Risk:** Medium

## Recommended Action

완료. 신규 회귀 테스트 2개를 CI/로컬 guardrail 실행 체인에 동일하게 배선해 재유입 회귀를 자동 차단하도록 정렬했다.

## Technical Details

**Affected files:**
- `.github/workflows/federated-ci-matrix.yml`
- `planningops/scripts/federated_ci_matrix_local.sh`
- (optional) 신규 집계 테스트 스크립트

## Resources

- `planningops/scripts/test_track1_gate_dryrun_contract.sh`
- `planningops/scripts/test_bootstrap_two_track_backlog_contract.sh`

## Acceptance Criteria

- [x] 신규 회귀 테스트 2개가 CI guardrail 체인에서 실행된다.
- [x] 로컬 federated 스크립트와 CI 테스트 목록이 일치한다.
- [x] 실패 시 해당 테스트 로그가 artifact 또는 stdout으로 확인 가능하다.

## Work Log

### 2026-03-03 - Review Finding Created

**By:** Codex

**Actions:**
- 신규 테스트 파일과 workflow/local 실행 체인을 교차 검토했다.
- 실행 경로 미연결 상태를 확인하고 보완 옵션을 정리했다.

**Learnings:**
- 회귀 테스트는 작성보다 배선(wiring)이 중요하며, CI/로컬 경로 동기화가 재발 방지의 핵심이다.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `.github/workflows/federated-ci-matrix.yml` `loop-guardrails`에 아래 테스트를 추가했다.
  - `bash planningops/scripts/test_track1_gate_dryrun_contract.sh`
  - `bash planningops/scripts/test_bootstrap_two_track_backlog_contract.sh`
- `planningops/scripts/federated_ci_matrix_local.sh` `loop-guardrails` 체인에도 동일 테스트를 추가해 CI/로컬 목록을 정렬했다.
- strict gate 실행 경로 보강과 함께 회귀 테스트를 같은 guardrail 도메인에서 병행하도록 구성했다.

**Learnings:**
- guardrail 항목은 CI와 로컬 실행 스크립트가 1:1로 맞아야 triage/재현 비용이 줄어든다.

## Notes

- 중요도 P2: merge blocker는 아니지만 조기 보완이 권장된다.
