---
status: complete
priority: p2
issue_id: "007"
tags: [code-review, docs, quality, ci]
dependencies: []
---

# Root README Validation Gap

루트 `README.md`가 운영 계약 문서를 담지만, 현재 CI 검증 트리거 및 스크립트 검증 범위에서 제외되어 드리프트를 자동 탐지하지 못한다.

## Problem Statement

이번 변경으로 루트 README는 canonical/workbench 구조와 실행 명령을 안내하는 핵심 문서가 되었지만, 문서 검증 파이프라인은 이 파일의 변경을 기본적으로 보장하지 않는다.

결과적으로 README의 경로/명령/링크가 깨져도 PR에서 문서 검증이 실행되지 않거나, 실행되어도 해당 파일 자체는 스키마/링크 점검 대상이 아니다.

## Findings

- root README는 핵심 운영 계약(구조/Quick Start/Working Rules)을 포함한다.
  - `README.md:26`
  - `README.md:49`
  - `README.md:57`
- workflow trigger에는 루트 README 경로가 없다.
  - `.github/workflows/uap-docs-check.yml:6`
  - `.github/workflows/uap-docs-check.yml:7`
- `uap-docs.sh` 스캔 범위는 initiative canonical + workbench로 한정된다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:66`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:73`

## Proposed Solutions

### Option 1: CI trigger에 `README.md` 추가

**Approach:** workflow `pull_request.paths`에 `README.md`를 포함해 루트 허브 변경 시 검증 잡이 항상 실행되게 한다.

**Pros:**
- 최소 변경으로 감지 범위 확대
- 운영 계약 변경 누락 방지

**Cons:**
- README 수정 빈도가 높다면 CI 실행 횟수 증가

**Effort:** 15-30 minutes

**Risk:** Low

---

### Option 2: Root README 링크 검증 step 추가

**Approach:** workflow에서 `README.md` 대상 링크 검사(`rg`/스크립트)를 별도 수행한다.

**Pros:**
- 실제 회귀(깨진 링크/경로)를 직접 탐지
- canonical/workbench 검증과 역할 분리 명확

**Cons:**
- 검증 규칙 설계가 추가로 필요

**Effort:** 1-2 hours

**Risk:** Low

---

### Option 3: Root README를 canonical docs hub의 최소 포인터로 축소

**Approach:** 루트 README를 짧은 엔트리 문서로 최소화하고, 검증 가능한 canonical 문서에 계약을 집중한다.

**Pros:**
- 드리프트 표면 자체 축소
- 검증 체계 단순화

**Cons:**
- 기존 사용자 진입 UX 변경 필요

**Effort:** 2-4 hours

**Risk:** Medium

## Recommended Action

완료. CI trigger에 `README.md`를 포함시키고, `uap-docs.sh` preflight에서 root README 명령/경로 계약을 검증하도록 반영했다.

## Technical Details

**Affected files:**
- `.github/workflows/uap-docs-check.yml`
- `README.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh` (선택)

## Resources

- Review target: current working tree (2026-02-28)

## Acceptance Criteria

- [x] 루트 README 변경 시 문서 검증 잡이 항상 실행된다.
- [x] README의 핵심 링크/명령 드리프트를 자동 탐지할 수 있다.
- [x] canonical/workbench 검증 정책과 중복 없이 운영된다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- 루트 README 역할 변화와 CI path filter 범위를 교차 확인했다.
- `uap-docs.sh` 스캔 범위가 README를 포함하지 않음을 확인했다.
- 감지 범위 확장/축소 전략 3가지를 정리했다.

**Learnings:**
- 문서 허브의 책임이 커질수록 검증 트리거 누락은 실제 운영 리스크로 이어진다.
- "어떤 파일을 검증할지"와 "언제 검증할지"를 분리해서 관리해야 재발을 줄일 수 있다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `.github/workflows/uap-docs-check.yml`의 `pull_request.paths`에 `README.md`를 추가했다.
- `uap-docs.sh`에 root README contract check를 추가해 workbench 경로/검증 명령 표준(`--profile canonical`, `--profile all`) 유무를 검사하도록 구현했다.
- profile-all check/sync 재검증으로 guard 동작과 정상 시나리오 통과를 확인했다.

**Learnings:**
- README를 운영 계약 허브로 사용할 경우, 스크립트 preflight와 workflow trigger를 같이 묶어야 검증 공백이 사라진다.
- README 검증은 최소 문자열 계약부터 시작해 필요 시 링크 파싱 검증으로 점진 강화하는 방식이 안전하다.

## Notes

- P1 이슈(legacy 경로 회귀 차단) 해결 후 함께 묶어 처리하면 변경 충돌을 줄일 수 있다.
