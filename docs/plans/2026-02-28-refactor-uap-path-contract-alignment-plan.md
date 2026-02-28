---
title: refactor: Align UAP Path Contract and Command Context
type: refactor
date: 2026-02-28
source_brainstorm: docs/brainstorms/2026-02-28-uap-doc-topology-canonicalization-brainstorm.md
source_review_todos:
  - todos/001-complete-p2-path-rule-semantics-mismatch.md
  - todos/002-complete-p2-command-path-contract-mismatch.md
  - todos/003-complete-p3-entry-core-self-reference-noise.md
---

# refactor: Align UAP Path Contract and Command Context

## Overview
Core 7 canonicalization 이후 남은 문서 운영 리스크(경로 규칙 의미 불일치, 명령 실행 컨텍스트 혼용, Entry Core self-reference 노이즈)를 제거한다.

목표는 문서/스크립트/온보딩 예시가 동일한 실행 계약을 따르도록 고정해, 에이전트 실행 시 불필요한 판단과 실패 분기를 줄이는 것이다.

## Problem Statement / Motivation
현재 상태는 검증 통과는 가능하지만 운영 계약 관점에서 3가지 불일치가 남아 있다.

1. Path Rule 의미 불일치
- 정책 문서는 `initiative 루트 기준 상대경로`를 요구하지만, 검증 스크립트는 `문서 파일 기준 상대경로`만 해석한다.

2. 명령 경로 컨텍스트 혼용
- 규칙 문구는 repo 루트 경로를 말하지만, 실제 예시는 initiative 디렉토리 기준 명령을 보여준다.

3. Entry Core self-reference
- 온보딩 목록에 현재 문서 자신이 포함되어 초기 읽기 흐름의 명확성이 떨어진다.

## Brainstorm Context
Found brainstorm from `2026-02-28`: `uap-doc-topology-canonicalization`. Using as context for planning.

브레인스토밍 확정 사항 중 본 계획과 직접 연결되는 항목:
- Core 7 canonical 파일명 유지
- 용어/경로 기준의 일관성 유지
- 문서는 구현 전 시뮬레이션 문맥을 제공해야 함

본 계획은 위 결정의 후속 정합성 패치로, 구조 변경이 아니라 규칙-예시-검증의 semantic alignment에 집중한다.

## Research Findings (Local)
### Repo patterns
- 문서 검증기는 `base_dir + relative_path` 모델로 링크/`related_docs`를 검사한다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:223`
- Path Root 문구는 다수 문서에서 반복 사용된다.
  - `docs/initiatives/unified-personal-agent-platform/AGENT-START.md:32`
  - `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md:35`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md:92`
- 실행 예시 명령은 현재 initiative 루트 기준과 repo 루트 기준이 혼용되어 있다.

### Learnings corpus
- `docs/solutions/` 경로에는 본 주제와 연결할 institutional learning 문서가 현재 없다.

## Research Decision
- External research는 생략한다.
- 본 작업은 외부 API/보안/규제 주제가 아닌 내부 문서 계약 정합성 리팩터링이며, 로컬 근거가 충분하다.

## Scope
### In scope
- Path Rule 문구를 검증기 동작과 일치시키는 규칙 정리
- 명령 예시를 단일 실행 컨텍스트로 통일
- Entry Core 목록에서 self-reference 처리 방식 통일
- 관련 스크립트 usage/next 출력 정합성 갱신
- 문서 검증 자동화(`check`, `sync`) 재검증

### Out of scope
- Core 7/Non-core 분류 재설계
- 새로운 카탈로그 포맷 도입
- 문서 구조 대규모 이동/리네임

## Proposed Solution
### Contract decisions
1. 링크 계약
- 문서 본문 링크와 `related_docs`는 `문서 파일 기준 상대경로`를 canonical로 고정한다.

2. 명령 계약
- 문서에 표기하는 CLI/CI 명령은 `repo 루트 기준 상대경로`를 canonical로 고정한다.
- 필요 시 보조 예시로 initiative 루트 버전을 별도 표기하되, 기본 표준은 repo 루트로 유지한다.

3. 온보딩 계약
- Entry Core 목록은 "다음 행동 가능한 문서" 중심으로 구성한다.
- self-reference는 목록에서 제거하고, 필요한 경우 섹션 주석으로만 남긴다.

## SpecFlow Analysis
### Primary flow
1. 신규 에이전트가 `AGENT-START`를 읽는다.
2. Core 문서를 순서대로 탐색한다.
3. 검증 명령을 실행한다.
4. 문서 작성/수정 후 `check -> sync`를 수행한다.

### Failure permutations
- 규칙 문구를 literal로 따른 작성자가 `uap-docs.sh check`에서 링크 오류를 만난다.
- 다른 작업 디렉토리에서 명령을 복사 실행해 경로 오류가 발생한다.
- self-reference로 온보딩 단계가 no-op처럼 보여 잘못된 읽기 우선순위를 선택한다.

### Gap to close
- 규칙 문구, 실행 예시, 스크립트 출력의 기준 좌표계를 1개로 정렬해야 한다.

## Implementation Plan
### Phase 1: Contract freeze (문구 기준 확정)
Tasks:
- Path/Command 계약 문구를 `uap-doc-governance`에 단일 정의로 고정
- 용어 사전(파일 상대 링크 vs repo 상대 명령)을 문서에 명시

Deliverables:
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`

### Phase 2: Surface alignment (온보딩/네비게이션 동기화)
Tasks:
- `AGENT-START` Path Rule/Quick Checks를 계약과 일치시킴
- `uap-document-map` Path Rule/Entry Core 구성 정리
- self-reference 제거 또는 주석 처리 방식 통일

Deliverables:
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`

### Phase 3: Command UX alignment (스크립트/허브 문서 동기화)
Tasks:
- `README` Quick Start/Docs Automation 명령을 repo-root 표준으로 통일
- `uap-new-doc.sh` usage 예시와 완료 메시지(next) 경로를 동일 기준으로 수정

Deliverables:
- `docs/initiatives/unified-personal-agent-platform/README.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh`

### Phase 4: Verification and rollout
Tasks:
- 링크/경로 규칙 검증 실행
- 카탈로그 재생성 및 diff 확인
- 경로 혼용 잔여 문자열 점검(정적 검색)

Deliverables:
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check` green
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh sync` green
- `docs/plans/assets/uap-path-contract-alignment-audit.txt`

## Acceptance Criteria
### Functional
- [x] Path 규칙 문구가 검증기 동작(파일 상대 링크)과 정확히 일치한다.
- [x] 명령 예시가 repo 루트 기준 경로로 일관된다.
- [x] Entry Core 목록에서 self-reference로 인한 no-op 혼선이 제거된다.

### Non-functional
- [x] `uap-docs.sh check`가 통과한다.
- [x] `uap-docs.sh sync`가 통과하고 카탈로그 링크가 유효하다.
- [x] 핵심 문서(AGENT-START, Document Map, Governance, README) 간 경로 규칙 표현이 동일하다.

## Success Metrics
- 동일 명령 복사 실행 실패율: 0건
- Path 규칙 문의/수정 재발: 0건(다음 리뷰 사이클)
- 온보딩 경로 해석 ambiguity: 리뷰 기준 0건

## Dependencies & Risks
### Dependencies
- 기존 Core 7 canonical 파일명 유지
- `uap-docs.sh` 검증 규칙과 문구 동기화

### Risks
- 문구만 수정하고 예시를 누락하면 불일치가 재발
- repo-root 표준 전환 시 일부 개인 워크플로 충돌 가능

### Mitigations
- 계약 정의 문서를 single source(`uap-doc-governance`)로 고정
- 예시 명령 변경 시 `AGENT-START`, `README`, `uap-new-doc.sh`를 묶어서 함께 수정
- PR 체크리스트에 "path contract consistency" 항목 추가

## References & Research
### Internal references
- `docs/brainstorms/2026-02-28-uap-doc-topology-canonicalization-brainstorm.md`
- `todos/001-complete-p2-path-rule-semantics-mismatch.md`
- `todos/002-complete-p2-command-path-contract-mismatch.md`
- `todos/003-complete-p3-entry-core-self-reference-noise.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:223`

## MVP Pseudo Worklist
### docs/plans/assets/uap-path-contract-alignment-audit.txt
```text
# path-contract alignment audit
# files checked
# mismatch lines (if any)
```

### docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md
```markdown
## Path Contract
- links/related_docs: file-relative
- cli/ci commands: repo-relative
```

### docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh
```bash
# usage and next message should output repo-root command examples
```
