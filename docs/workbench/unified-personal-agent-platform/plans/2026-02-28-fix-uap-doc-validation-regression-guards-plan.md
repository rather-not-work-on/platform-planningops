---
title: fix: Add Regression Guards for Legacy Docs Paths and Root README Validation
type: plan
plan_kind: fix
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Adds fail-fast guards in local/CI validation to block legacy path reintroduction and cover root README drift.
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
source_brainstorm: docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-doc-topology-permanence-separation-brainstorm.md
source_review_todos:
  - todos/006-complete-p1-legacy-path-regression-guard-missing.md
  - todos/007-complete-p2-root-readme-validation-gap.md
---

# fix: Add Regression Guards for Legacy Docs Paths and Root README Validation

## Overview
`canonical + workbench` 토폴로지 전환 이후 남은 검증 공백을 닫는다.

핵심 목표:
- P1: `docs/brainstorms`, `docs/plans` 레거시 경로 재유입을 로컬/CI에서 즉시 실패 처리
- P2: 루트 `README.md` 변경 시 검증 파이프라인이 누락 없이 실행되고, 최소 링크/명령 정합성을 점검

## Problem Statement / Motivation
현재 문서 구조는 분리되었지만 회귀 방어가 충분하지 않다.

1. Legacy path regression (P1)
- `uap-docs.sh check --profile all`은 canonical/workbench 범위만 검사한다.
- 임시 `docs/plans/test-legacy.md` 생성 후에도 검증이 통과할 수 있다.

2. Root README validation gap (P2)
- 루트 `README.md`가 구조/명령/운영 규칙을 담는 허브가 되었지만,
- 현재 CI path filter와 검증 스코프에서 보장이 약하다.

이 두 공백은 문서 운영 계약의 핵심인 "경로 불변성"을 장기적으로 훼손할 수 있다.

## Brainstorm Context
Found brainstorm from `2026-02-28`: `doc-topology-permanence-separation`. Using as context for planning.

관련 확정 결정:
- canonical과 workbench를 구조적으로 분리
- workbench 산출물은 initiative-scoped 경로로만 운영
- 자동화는 canonical/workbench 경계를 명확히 강제해야 함

## Research Findings (Local)
### Repository patterns
- canonical/workbench 스캔 범위:
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:66`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:73`
- CI workflow path filter:
  - `.github/workflows/uap-docs-check.yml:6`
  - `.github/workflows/uap-docs-check.yml:7`
- root README가 운영 계약을 담는 허브:
  - `README.md:26`
  - `README.md:49`
  - `README.md:57`

### Learnings corpus
- `docs/solutions/` 경로에는 본 이슈와 직접 연결되는 institutional learning 문서가 없다.

## Research Decision
- External research는 생략한다.
- 이 작업은 내부 문서 검증 계약/CI 파이프라인 정합성 이슈이며, 로컬 근거와 재현 절차가 명확하다.

## Scope
### In scope
- `uap-docs.sh`에 legacy path stale guard 추가 (`docs/brainstorms/**`, `docs/plans/**` 감지 시 fail)
- CI workflow에 root README 변경 트리거 포함
- CI step에서 stale path guard + root README 최소 검증(링크/명령 정합성) 추가
- 실패 메시지와 운영 문서(README/Governance)의 실행 지침 업데이트

### Out of scope
- canonical/workbench 토폴로지 재설계
- Core 7 문서 구조 변경
- GitHub Project 필드 스키마 변경

## Proposed Solution
### Recommended approach
P1/P2를 하나의 회귀 방지 체인으로 묶는다.

1. `uap-docs.sh`에 `check_stale_legacy_paths` 함수를 추가한다.
- 금지 경로가 존재하면 경로 목록을 출력하고 non-zero exit.
- `check`/`sync` 실행 초기에 수행해 fail-fast 보장.

2. CI workflow를 강화한다.
- `pull_request.paths`에 `README.md`, `docs/brainstorms/**`, `docs/plans/**` 추가.
- 검증 step에서 `uap-docs.sh check --profile all` 실행 전 stale guard 결과를 확인.

3. root README 최소 검증을 도입한다.
- README 링크/명령 패턴이 최신 표준(`docs/workbench/...`, `uap-docs.sh --profile ...`)과 일치하는지 검사.
- 단순 문자열 가드(`rg`)부터 시작하고 필요 시 스크립트 함수로 승격.

## SpecFlow Analysis
### User flow overview
1. 작성자가 문서를 수정하거나 새 파일을 생성한다.
2. 로컬에서 `uap-docs.sh check --profile all`을 실행한다.
3. PR 생성 시 CI가 동일 검증을 재실행한다.
4. 레거시 경로나 README 드리프트가 있으면 즉시 실패하고 수정 후 재검증한다.

### Flow permutations matrix
| Flow | Happy path | Failure path | Guard |
|---|---|---|---|
| 문서 작성 | canonical/workbench 경로 사용 | legacy 경로 재생성 | stale legacy path check |
| README 수정 | 구조/명령 계약 유지 | 구 경로/구 명령 재유입 | README validation step |
| CI 검증 | all profile 통과 | legacy 경로 전용 변경에서 docs-check 미실행 | `README.md` + legacy path trigger 포함 |

### Missing elements to close
- 스크립트 수준의 explicit stale-path 금지 규칙
- root README 변경 시 검증 실행 보장
- 실패 원인을 빠르게 이해할 수 있는 에러 메시지

## Implementation Plan
### Phase 1: Guard contract definition
Tasks:
- 금지 경로 목록(`docs/brainstorms`, `docs/plans`)과 실패 메시지 형식 확정
- README 최소 검증 규칙(경로/명령 문자열 기준) 정의

Deliverables:
- guard rules note in governance/README

### Phase 2: Local validator hardening (P1)
Tasks:
- `uap-docs.sh`에 stale legacy path scan 함수 추가
- `check`, `sync` 공통 진입에서 guard 실행
- 실패 시 위반 파일 목록 출력

Deliverables:
- updated `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`

### Phase 3: CI coverage hardening (P1+P2)
Tasks:
- workflow path filter에 `README.md` 포함
- workflow path filter에 legacy 경로(`docs/brainstorms/**`, `docs/plans/**`) 포함
- docs-check job에서 stale guard + all profile 검증 실행
- 필요 시 README 전용 smoke validation step 추가

Deliverables:
- updated `.github/workflows/uap-docs-check.yml`

### Phase 4: Documentation alignment (P2)
Tasks:
- 루트 README와 governance 문서에 guard 존재와 실패 대응 절차 명시
- 검증 명령 예시를 `--profile` 포함 표준으로 재확인

Deliverables:
- updated `README.md`
- updated `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`

### Phase 5: Verification and evidence
Tasks:
- 회귀 재현 케이스(legacy 파일 임시 생성)로 fail 확인
- 정상 경로 케이스에서 `check/sync` green 확인
- audit 로그에 명령/결과 기록

Deliverables:
- `docs/workbench/unified-personal-agent-platform/audits/uap-legacy-guard-validation-audit.txt`

## Acceptance Criteria
### Functional
- [x] `docs/brainstorms/**`, `docs/plans/**` 재유입 시 `uap-docs.sh check`가 실패한다.
- [x] 실패 로그에 위반 경로가 명시된다.
- [x] `README.md` 변경만 포함된 PR에서도 docs-check job이 실행된다.
- [x] root README 최소 검증 규칙이 CI에서 수행된다.

### Non-functional
- [x] 기존 canonical/workbench 정상 변경은 false positive 없이 통과한다.
- [x] `check --profile all` 및 `sync --profile all`이 안정적으로 동작한다.
- [x] 회귀 검증 결과가 audit 로그로 남는다.

## Success Metrics
- legacy 경로 재유입 회귀: 0건
- README 검증 누락으로 인한 경로/명령 드리프트: 0건
- docs-check false positive rate: 0건 (초기 2주 관찰)

## Dependencies & Risks
### Dependencies
- 기존 `uap-docs.sh` profile 체계 유지
- CI workflow 문서 검증 job 접근 권한 유지

### Risks
- guard 규칙이 과도하면 실험/임시 파일까지 차단
- README 문자열 검증이 너무 약하면 실제 드리프트 누락

### Mitigations
- guard 범위를 명시적 금지 경로로만 제한
- README 검증은 단계적으로 강화(문자열 -> 링크 파싱)
- 실패 메시지에 복구 가이드를 함께 출력

## References & Research
### Internal references
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-doc-topology-permanence-separation-brainstorm.md`
- `todos/006-complete-p1-legacy-path-regression-guard-missing.md`
- `todos/007-complete-p2-root-readme-validation-gap.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:66`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:73`
- `.github/workflows/uap-docs-check.yml:6`
- `.github/workflows/uap-docs-check.yml:7`
- `README.md:26`
- `README.md:49`
- `README.md:57`

### External references
- 없음 (내부 운영 계약 문제)

## MVP Pseudo Worklist
### docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh
```bash
# add stale legacy path guard
check_stale_legacy_paths() {
  # fail when docs/brainstorms or docs/plans exists
}
```

### .github/workflows/uap-docs-check.yml
```yaml
pull_request:
  paths:
    - README.md
    - docs/initiatives/unified-personal-agent-platform/**
    - docs/workbench/unified-personal-agent-platform/**
```

### docs/workbench/unified-personal-agent-platform/audits/uap-legacy-guard-validation-audit.txt
```text
- reproduce legacy path injection
- expected failure output
- normal path green checks
```
