---
title: fix: Eliminate UAP Command Path Drift in Generated and Legacy Docs
type: fix
date: 2026-02-28
source_brainstorm: docs/brainstorms/2026-02-28-uap-doc-topology-canonicalization-brainstorm.md
source_review_todos:
  - todos/004-complete-p2-catalog-generator-command-path-drift.md
  - todos/005-complete-p3-legacy-plan-command-style-drift.md
---

# fix: Eliminate UAP Command Path Drift in Generated and Legacy Docs

## Overview
경로 계약을 repo-root 명령 기준으로 정렬했음에도, 자동 생성 카탈로그와 일부 legacy 계획 문서에 구 명령 스타일(`bash ./00-governance/...`)이 남아 드리프트가 재발하고 있다.

이 계획은 드리프트의 "재생산 원인"(생성기 템플릿)을 먼저 제거하고, legacy 문서 표기까지 정렬해 문서 전반의 실행 컨텍스트 일관성을 회복한다.

## Problem Statement / Motivation
현재 식별된 문제는 2가지다.

1. 생성기 기반 재유입(P2)
- `uap-docs.sh`가 카탈로그를 만들 때 구 명령 스타일을 본문에 하드코딩해, `sync` 실행 시마다 드리프트를 다시 만든다.
- 근거:
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:310`
  - `docs/initiatives/unified-personal-agent-platform/2026-02-27-uap-frontmatter-catalog.navigation.md:27`

2. legacy 문서 잔여 표기(P3)
- 일부 legacy 실행계획 문서가 아직 구 명령 스타일을 유지한다.
- 근거:
  - `docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md:165`

추가 관찰(동일 패턴):
- 루트 README quick-start도 initiative-local 스타일을 유지하고 있어 표준과 괴리가 있다.
  - `README.md:45`
  - `README.md:46`

## Brainstorm Context
Found brainstorm from `2026-02-28`: `uap-doc-topology-canonicalization`. Using as context for planning.

브레인스토밍의 핵심 결정(용어/경로 기준 정합성 강화)과 이번 수정은 동일 방향이다. 이 작업은 Core 7 리네임의 후속 "운영 정합성 마감" 단계다.

## Local Research
### Repository patterns
- 문서 검증/카탈로그 생성의 single automation entry는 `uap-docs.sh`다.
- 카탈로그 문서는 자동 생성 산출물이라, 생성기 템플릿을 수정하지 않으면 수동 수정이 유지되지 않는다.
- 문서 정책상 명령 경로는 repo-root 기준을 표준으로 두는 흐름이 이미 코어 문서에 반영되어 있다.

### Learnings corpus
- `docs/solutions/`에는 본 이슈와 직접 연결되는 학습 문서가 없다.

## Research Decision
- External research는 생략한다.
- 이 이슈는 내부 문서 자동화 출력과 레거시 문서 정합성 문제이며, 로컬 근거로 충분히 해결 가능하다.

## Scope
### In scope
- 카탈로그 생성 템플릿의 명령 표기를 repo-root 기준으로 수정
- `uap-docs.sh sync` 재실행 후 카탈로그 산출물 정합성 확인
- legacy 실행계획 문서의 구 명령 표기를 현재 표준에 맞게 정리
- 루트 README quick-start 표기의 정렬 여부를 함께 결정하고 반영

### Out of scope
- 문서 구조 재편/추가 리네임
- status 체계 변경
- GitHub Actions 워크플로 구조 변경

## SpecFlow Analysis
### Primary flow
1. 작성자/에이전트가 문서 검증 명령을 복사 실행한다.
2. `uap-docs.sh sync`가 카탈로그를 재생성한다.
3. 생성 산출물이 정책 문구와 같은 경로 기준을 유지한다.

### Failure scenarios
- 생성기 템플릿 미수정: 다음 sync에서 구 스타일 재유입
- legacy 문서 미정리: 참조 문서마다 명령 기준이 달라 혼선 발생
- 루트 README 미정리: 신규 진입자가 첫 단계에서 구 스타일을 학습

### Gap to close
- "문서 정책", "자동 생성 템플릿", "진입 문서 예시"가 동일한 명령 경로 기준을 사용해야 한다.

## Proposed Solution
### Decision A (required)
- 카탈로그 생성 템플릿(`uap-docs.sh`)의 생성 명령 안내를 repo-root 표기로 변경한다.

### Decision B (required)
- legacy migration plan의 명령 예시를 repo-root 표기로 갱신한다.

### Decision C (recommended)
- 루트 README quick-start 명령도 repo-root 표준과 일치하도록 정리한다.
- 단, 루트 README를 initiative-local onboarding 문서로 유지하려면 그 의도를 명시적으로 주석 처리한다.

## Implementation Plan
### Phase 1: Drift Source Fix
Tasks:
- `uap-docs.sh` 카탈로그 템플릿의 생성 명령 문자열 교체
- `sync` 실행 후 카탈로그 산출물 갱신

Deliverables:
- updated `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`
- updated `docs/initiatives/unified-personal-agent-platform/2026-02-27-uap-frontmatter-catalog.navigation.md`

### Phase 2: Legacy Surface Alignment
Tasks:
- `2026-02-27-uap-doc-structure-migration.execution-plan.md` 명령 예시 갱신
- 루트 `README.md` quick-start 정렬(혹은 예외 정책 주석 추가)

Deliverables:
- updated `docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md`
- updated `README.md` (if Decision C accepted)

### Phase 3: Verification
Tasks:
- `uap-docs.sh check`
- `uap-docs.sh sync`
- 정적 검색으로 구 명령 스타일 잔여 확인

Deliverables:
- `docs/plans/assets/uap-command-path-drift-audit.txt`

## Acceptance Criteria
### Functional
- [x] 카탈로그 생성 템플릿이 repo-root 기준 명령을 출력한다.
- [x] 카탈로그 산출물에 `bash ./00-governance/scripts/uap-docs.sh catalog` 패턴이 0건이다.
- [x] legacy migration plan의 검증 명령이 현재 표준과 충돌하지 않는다.
- [x] (선택) 루트 README quick-start가 표준과 일치하거나 예외 의도가 명시된다.

### Non-functional
- [x] `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check` 통과
- [x] `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh sync` 통과
- [x] 경로 표기 관련 재유입 패턴 검색 결과가 audit 파일에 기록된다.

## Success Metrics
- 카탈로그 재생성 후 구 명령 패턴 재유입: 0건
- 경로 표기 관련 문서 리뷰 재오픈 건수: 0건(다음 리뷰 사이클)
- 신규 에이전트 명령 실행 실패 보고: 0건

## Dependencies & Risks
### Dependencies
- `uap-docs.sh`가 카탈로그 생성의 유일 생성기라는 전제
- 기존 path contract 문서(`AGENT-START`, `uap-doc-governance`, `uap-document-map`) 유지

### Risks
- legacy 문서를 광범위하게 건드리면 historical context 훼손 우려
- 루트 README 처리 기준이 합의되지 않으면 또 다른 스타일 혼용 발생

### Mitigations
- 수정 범위를 "명령 예시 라인"으로 최소화
- 루트 README는 Decision C를 명시적 결정 항목으로 분리
- 변경 후 audit 텍스트를 남겨 재발 탐지 기준으로 사용

## References & Research
### Internal references
- `todos/004-complete-p2-catalog-generator-command-path-drift.md`
- `todos/005-complete-p3-legacy-plan-command-style-drift.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:310`
- `docs/initiatives/unified-personal-agent-platform/2026-02-27-uap-frontmatter-catalog.navigation.md:27`
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md:165`
- `README.md:45`

## MVP Pseudo Worklist
### docs/plans/assets/uap-command-path-drift-audit.txt
```text
# command-path drift audit
# search patterns
# matched files (before/after)
# verification command results
```

### docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh
```bash
# generated catalog header must print repo-root command example
```

### docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md
```markdown
# update command snippet to repo-root style
```
