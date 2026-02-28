---
status: complete
priority: p1
issue_id: "006"
tags: [code-review, docs, governance, ci]
dependencies: []
---

# Legacy Path Regression Guard Missing

`docs/brainstorms`/`docs/plans` 레거시 경로가 재유입되어도 현재 자동 검증에서 걸러지지 않는다.

## Problem Statement

문서 토폴로지를 `canonical + workbench`로 분리했지만, 레거시 루트 경로(`docs/brainstorms`, `docs/plans`) 재생성을 막는 자동 가드가 없다.

이 상태에서는 에이전트/사용자가 기존 습관대로 레거시 경로에 문서를 생성해도 CI가 통과할 수 있어, 이번 마이그레이션의 핵심 계약이 쉽게 깨진다.

## Findings

- 검증 스크립트는 canonical/workbench 경로만 스캔한다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:66`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:73`
- CI workflow path filter도 canonical/workbench만 포함한다.
  - `.github/workflows/uap-docs-check.yml:6`
  - `.github/workflows/uap-docs-check.yml:7`
- 재현:
  - 임시로 `docs/plans/test-legacy.md` 생성 후 `uap-docs.sh check --profile all` 실행 시 통과 확인
  - 출력: `canonical check passed / workbench check passed`

## Proposed Solutions

### Option 1: `uap-docs.sh`에 stale-path guard 추가

**Approach:** `check` 단계에서 `docs/brainstorms/**`, `docs/plans/**` 존재 시 실패 처리한다.

**Pros:**
- CI/로컬 모두 동일하게 강제 가능
- 레거시 경로 재유입 즉시 차단

**Cons:**
- 예외적 실험 파일도 실패 처리됨

**Effort:** 1-2 hours

**Risk:** Low

---

### Option 2: CI workflow path + explicit scan step 확장

**Approach:** workflow trigger에 `docs/**` 또는 legacy 경로를 포함하고, 별도 step으로 stale path scan을 추가한다.

**Pros:**
- PR 단계에서 회귀를 명확히 탐지
- 스크립트 변경 최소화 가능

**Cons:**
- 로컬 `check`만 실행할 때는 동일 보장이 약함

**Effort:** 30-60 minutes

**Risk:** Low

---

### Option 3: Option 1 + Option 2 병행

**Approach:** 로컬/CI 양쪽에서 stale path 재유입을 동시에 차단한다.

**Pros:**
- 회귀 방지 강도가 가장 높음
- 문서 계약 위반을 earliest point에서 탐지

**Cons:**
- 구현 포인트가 2곳으로 늘어남

**Effort:** 2-3 hours

**Risk:** Low

## Recommended Action

완료. `uap-docs.sh`에 stale legacy path guard를 추가하고, CI docs-check trigger/검증 경로를 보강해 재유입 회귀를 fail-fast로 차단했다.

## Technical Details

**Affected files:**
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`
- `.github/workflows/uap-docs-check.yml`

**Related components:**
- 문서 경로 계약(`canonical/workbench`)
- CI 문서 검증 파이프라인

## Resources

- Review target: current working tree (2026-02-28)
- Reproduction command:
  - `mkdir -p docs/plans && echo '# legacy test' > docs/plans/test-legacy.md`
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`

## Acceptance Criteria

- [x] `docs/brainstorms/**`, `docs/plans/**` 경로 재유입 시 `check`가 실패한다.
- [x] CI에서도 동일 회귀가 fail-fast로 탐지된다.
- [x] 실패 메시지에 위반 경로가 명시된다.
- [x] 정상 canonical/workbench 변경은 기존처럼 통과한다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- 마이그레이션 후 검증 스크립트 스캔 범위와 workflow trigger 범위를 점검했다.
- 레거시 경로 재생성 시나리오를 수동 재현해 회귀 탐지 누락을 확인했다.
- 회귀 방지 방안을 로컬+CI 관점으로 분리 정리했다.

**Learnings:**
- 현 구조는 "새 경로 검증"은 강하지만 "구 경로 재유입 차단"은 비어 있다.
- 문서 토폴로지 리팩터링의 안정성은 stale-path guard 유무에 크게 의존한다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `uap-docs.sh`에 preflight guard(`check_stale_legacy_paths`)를 추가해 `docs/brainstorms`, `docs/plans` 존재 시 즉시 실패하도록 구현했다.
- `check/sync` 경로에서 preflight를 선행 실행하도록 연결했다.
- CI workflow에 `README.md` 트리거를 추가하고 `check --profile all` 검증 체인을 유지했다.
- legacy 경로 재현 테스트(`docs/plans/test-legacy.md`)로 실패 동작을 검증하고 cleanup 후 정상 경로 green을 확인했다.

**Learnings:**
- stale-path guard는 스캔 범위 기반 검증보다 먼저 실행해야 catalog/update 비용을 줄이고 원인을 명확히 전달할 수 있다.
- 로컬/CI 공통 스크립트 가드가 있어야 문서 토폴로지 계약 회귀를 안정적으로 차단할 수 있다.

## Notes

- 본 이슈는 이번 분리 작업의 핵심 계약(legacy 경로 금지) 보호를 위한 merge-blocker 성격이다.
