---
status: complete
priority: p1
issue_id: "016"
tags: [code-review, reliability, ci, gate, planningops]
dependencies: []
---

# Track1 Strict Gate Is Not Enforced by CI/Automation

`run_track1_gate_dryrun.py`에 `--strict`가 도입되었지만, 현재 CI/로컬 자동화 경로 어디에서도 strict 모드 호출이 연결되지 않아 non-pass gate가 파이프라인 실패로 승격되지 않는다.

## Problem Statement

게이트 판정의 최종 목적은 `pass`가 아닌 상태를 자동으로 차단하는 것이다. 현재 구현은 strict 계약을 코드에만 추가했고, 실행 경로에 wiring이 누락되어 운영 상의 차단 효과가 발생하지 않는다.

## Findings

- `federated-ci-matrix`의 guardrail 단계는 기존 테스트만 실행하며 gate dry-run strict 호출이 없다.
  - `.github/workflows/federated-ci-matrix.yml:98-104`
- 로컬 대응 스크립트도 동일하게 strict gate 실행을 포함하지 않는다.
  - `planningops/scripts/federated_ci_matrix_local.sh:57-58`
- 결과적으로 `track1-gate-dryrun-report.json.final_verdict`가 `inconclusive`/`fail`이어도 CI status check는 성공할 수 있다.

## Proposed Solutions

### Option 1: Existing loop-guardrails 단계에 strict gate 체크 직접 추가

**Approach:** `bash planningops/scripts/run_track1_gate_dryrun.py --strict`를 워크플로 및 로컬 federated 스크립트에 포함한다.

**Pros:**
- 구현 단순
- 즉시 merge gate 반영

**Cons:**
- guardrail 단계 책임이 더 무거워짐

**Effort:** Small

**Risk:** Low

---

### Option 2: 전용 Track1 Gate workflow 생성 + Required Check 등록

**Approach:** strict gate를 별도 GitHub Actions workflow로 분리하고 branch protection required check로 고정한다.

**Pros:**
- 책임 분리 명확
- 정책 추적성 우수

**Cons:**
- 워크플로 수 증가

**Effort:** Medium

**Risk:** Low

---

### Option 3: `run_track1_gate_dryrun.py`의 CI 환경 strict 자동 전환

**Approach:** `CI=true`일 때 strict를 기본 활성화한다.

**Pros:**
- 호출 누락 리스크 감소

**Cons:**
- 실행 컨텍스트 기반 암묵 동작으로 가시성 저하

**Effort:** Small

**Risk:** Medium

## Recommended Action

완료. `federated-ci` 및 로컬 federated 실행 체인에 strict gate 실행을 직접 연결하고, CI용 KPI fixture를 분리해 strict enforcement를 재현 가능하게 고정했다.

## Technical Details

**Affected files:**
- `.github/workflows/federated-ci-matrix.yml`
- `planningops/scripts/federated_ci_matrix_local.sh`
- (optional) `planningops/scripts/run_track1_gate_dryrun.py`

## Resources

- `planningops/scripts/run_track1_gate_dryrun.py`
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-03-fix-gate-bootstrap-review-findings-plan.md`

## Acceptance Criteria

- [x] CI 경로에서 strict gate가 항상 실행된다.
- [x] `final_verdict != pass`일 때 PR check가 실패한다.
- [x] 로컬 federated 체크와 CI 체크가 동일 계약을 사용한다.
- [x] 운영 문서에 strict gate 실행 위치와 required check 이름이 명시된다.

## Work Log

### 2026-03-03 - Review Finding Created

**By:** Codex

**Actions:**
- strict gate 구현 반영 여부를 CI/로컬 실행 경로에서 역추적했다.
- workflow와 local script에서 strict 호출 누락을 확인했다.
- 차단 계약을 실제 파이프라인에 연결하는 remediation 옵션을 정리했다.

**Learnings:**
- 게이트 정책은 코드 구현만으로 완료되지 않으며, 필수 실행 경로 wiring까지 포함해야 실제 차단이 보장된다.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/run_track1_gate_dryrun.py`에 `--kpi-path`를 추가해 strict 실행의 KPI 입력을 명시적으로 분리했다.
- `planningops/fixtures/track1-kpi-baseline-ci.json` fixture를 추가해 CI에서 deterministic strict gate를 실행하도록 구성했다.
- `.github/workflows/federated-ci-matrix.yml` `loop-guardrails` job에 strict gate 실행(`--strict --kpi-path ...`)을 추가했다.
- 동일 strict 명령을 `planningops/scripts/federated_ci_matrix_local.sh`의 `loop-guardrails` 체인에 반영했다.

**Learnings:**
- strict enforcement는 live artifact 의존성과 분리된 deterministic 입력(fixture)까지 갖춰야 CI에서 안정적으로 운영 가능하다.

## Notes

- 해결 완료: strict contract가 CI/로컬 guardrail 경로에서 강제된다.
