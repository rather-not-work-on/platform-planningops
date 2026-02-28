---
title: refactor: Canonicalize UAP Core Documentation Topology
type: refactor
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Plan to stabilize Core 7 canonical filenames, status taxonomy, and documentation entry paths.
source_brainstorm: docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-uap-doc-topology-canonicalization-brainstorm.md
---

# refactor: Canonicalize UAP Core Documentation Topology

## Overview
UAP planning 문서 체계에서 기준 문서(Core)와 참고 문서(Non-core)를 명확히 분리하고, Core 문서의 파일명을 날짜 없는 canonical 이름으로 정규화한다.

핵심 목표는 문서 수를 줄이는 것이 아니라, 에이전트/개발자가 항상 동일한 기준 문맥에서 시작하도록 토폴로지를 고정하는 것이다.

## Problem Statement / Motivation
현재 문서 구조는 규칙은 잘 정의되어 있지만, 다음 운영 리스크가 남아 있다.
- 날짜 기반 파일명과 무날짜 파일명이 혼재되어 참조 경로가 길고 흔들린다.
- Entry 문서와 Policy 문서의 우선순위가 분리 표기되지 않아 실행 순서 해석이 갈릴 수 있다.
- 문서 status 체계를 `active/reference/deprecated`로 전환하려는 결정과 현재 검증 스크립트의 허용값(`active/draft/archived`)이 불일치한다.
- AppleDouble(`._*`) 파일이 작업 트리에 반복 유입되어 노이즈를 만든다.

## Brainstorm Context
Found brainstorm from `2026-02-28`: `uap-doc-topology-canonicalization`. Using as context for planning.

핵심 결정(브레인스토밍 확정):
- 접근: `Canonical Core + Legacy 분리`
- 코어 운영: `5+2 이중 코어` (Entry Core 5 + Policy Core 2)
- 전환 범위: 1차는 Core 7만 rename
- 상태 체계: `active / reference / deprecated`
- 경로 기준: 문서 본문은 initiative 루트 상대경로, 명령 문맥은 repo 루트 상대경로

## Research Findings (Local)
### Repository patterns
- 문서 거버넌스 canonical: `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`
- 문서 검증/카탈로그 자동화 스크립트: `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`
- 현재 `uap-docs.sh` 허용 status: `active`, `draft`, `archived`
- 문서 맵(읽기 순서 기준): `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`
- 에이전트 온보딩 엔트리: `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`

### Learnings corpus
- `docs/solutions/` 경로 내 학습 문서 없음 (적용 가능한 과거 해결 패턴 미존재)

### External research decision
- 이 작업은 내부 문서 토폴로지/참조 정합성 리팩터링이며 고위험 외부 API/보안/결제 주제가 아니다.
- 코드베이스 내 규칙/패턴이 명확하므로 외부 리서치는 생략한다.

## Scope
### In scope
- Core 7 파일명 canonical rename (무날짜 `uap-*`)
- Core/Policy 우선순위를 `AGENT-START` + `Document Map`에 명시
- Non-core 상태 체계를 `active/reference/deprecated`로 정리
- `uap-docs.sh`와 템플릿을 새 status 체계와 일치시킴
- rename 후 내부 참조/related_docs/카탈로그 정합성 보장

### Out of scope
- 문서 내용 대규모 재작성
- 실행 레포(`monday` 등)의 런타임 코드 변경
- GitHub Projects 자동화 정책 재설계

## Canonical Core 7 Mapping
경로 표기는 initiative 루트 상대경로 기준으로 고정한다.

| Core class | Current path | Target path | Action |
|---|---|---|---|
| Entry Core | `AGENT-START.md` | `AGENT-START.md` | keep |
| Entry Core | `AGENT.md` | `AGENT.md` | keep |
| Entry Core | `00-governance/2026-02-27-uap-monday-identity.meta.md` | `00-governance/uap-monday-identity.meta.md` | rename |
| Entry Core | `90-navigation/2026-02-27-uap-document-map.navigation.md` | `90-navigation/uap-document-map.navigation.md` | rename |
| Entry Core | `30-execution-plan/2026-02-27-uap-github-planningops-sync.execution-plan.md` | `30-execution-plan/uap-github-planningops-sync.execution-plan.md` | rename |
| Policy Core | `00-governance/2026-02-27-uap-doc-governance.meta.md` | `00-governance/uap-doc-governance.meta.md` | rename |
| Policy Core | `40-quality/2026-02-27-uap-planningops-tradeoff-decision-framework.quality.md` | `40-quality/uap-planningops-tradeoff-decision-framework.quality.md` | rename |

## SpecFlow Analysis
### User flow overview
1. 신규 에이전트가 `AGENT-START.md`를 읽고 Core 문서로 진입한다.
2. 문서 작성자가 정책(`doc-governance`)을 확인하고 문서를 추가/수정한다.
3. 계획 수립자가 `Document Map`과 `Execution Plan`을 따라 구현 준비를 한다.
4. 리뷰어가 `uap-docs.sh check/sync`로 정합성을 검증한다.

### Flow permutations matrix
| Flow | First-time | Returning | Failure path |
|---|---|---|---|
| Agent onboarding | Core 7 기준 문서 탐색 | 기존 북마크 경로 사용 | rename 후 broken link 발생 |
| Doc editing | status/경로 규칙 학습 | 기존 템플릿 재사용 | status 허용값 mismatch로 check fail |
| Plan handoff | map 기반 읽기 순서 수행 | 특정 plan 직접 접근 | 구/신 파일명 혼용으로 참조 오류 |
| Validation | `check -> sync` 수동 실행 | CI 자동 실행 확인 | AppleDouble 재유입/중복 경로 노이즈 |

### Missing elements & gaps
- 상태 체계 전환 결정과 lint 허용값이 아직 불일치
- Core rename 후 referer 목록(어떤 파일이 영향을 받는지) 사전 목록 부재
- `initiative 상대경로`와 `repo 상대경로`가 혼용될 가능성

### Critical questions requiring clarification
- Critical: status 전환을 1회 PR에서 완료할지, 2단계(호환 모드)로 나눌지?
- Important: Core 7 외 dated filename은 즉시 유지할지/후속 배치 전환할지?
- Important: rename 후 외부 링크(노션/위키/이슈 본문) 갱신 책임 범위를 어디까지 둘지?

가정(기본값):
- status 전환은 1회 PR에서 `script + docs + template` 동시 반영
- Core 7 외 dated filename은 1차에서 유지
- 외부 링크 갱신은 이 PR 범위 밖(추적 TODO만 생성)

## Proposed Solution
`Canonical Core + Legacy 분리`를 문서 구조/검증 규칙에 동시에 반영한다.

핵심 원칙:
- Core 7은 고정 파일명으로 운영해 참조 안정성을 확보
- Non-core는 status 기반으로 생명주기를 관리
- 스크립트/템플릿/맵을 동시에 업데이트해 “결정-도구-문서” 불일치를 제거

## Implementation Plan
### Phase 1: Core rename and reference stabilization
Tasks:
- Core 7 대상 `git mv` rename 수행
- Core 문서들의 `related_docs`, 본문 링크를 새 경로로 교체
- 영향 파일 목록 정리: `docs/workbench/unified-personal-agent-platform/audits/uap-core7-reference-audit.txt`

Deliverables:
- renamed core files (7개 중 5개 rename)
- `docs/workbench/unified-personal-agent-platform/audits/uap-core7-rename-map.tsv`

### Phase 2: Policy and status model alignment
Tasks:
- `uap-doc-governance.meta.md` status 의미를 `active/reference/deprecated`로 갱신
- `uap-docs.sh`의 `ALLOWED_STATUS`를 새 체계로 전환
- 문서 템플릿(`00-governance/templates/...`) 기본 status 규칙 반영

Deliverables:
- updated governance policy
- updated validator script
- updated document template

### Phase 3: Topology surfacing and non-core classification
Tasks:
- `AGENT-START`에 Entry Core/Policy Core를 분리 표기
- `Document Map` 읽기 순서에서 Core 우선 경로를 상단 고정
- Non-core 문서를 `active/reference/deprecated`로 분류 반영

Deliverables:
- updated `AGENT-START.md`
- updated `uap-document-map.navigation.md`
- non-core status normalization commit

### Phase 4: Verification and rollout
Tasks:
- `uap-docs.sh check`
- `uap-docs.sh sync`
- catalog diff 확인
- 잔여 `._*` 파일 cleanup 및 재유입 방지 안내

Deliverables:
- green validation output
- updated frontmatter catalog
- rollout note (`docs/workbench/unified-personal-agent-platform/audits/uap-core7-rollout-note.md`)

## Acceptance Criteria
### Functional
- [x] Core 7 경로가 canonical 무날짜 이름으로 고정된다.
- [x] `AGENT-START`와 `Document Map`이 Entry Core/Policy Core를 명시한다.
- [x] Non-core status가 `active/reference/deprecated` 기준으로 관리된다.

### Non-functional
- [x] `uap-docs.sh check`가 통과한다.
- [x] `uap-docs.sh sync` 후 catalog와 링크 검증이 통과한다.
- [x] Core 문서에서 dated filename 링크가 0건이다.

## Success Metrics
- Core 진입 경로 결정 시간: 신규 에이전트 기준 5분 이내
- Core 문서 링크 오류: 0건
- status 불일치로 인한 검증 실패: 0건
- dated filename 참조(코어 문서 내): 0건

## Dependencies & Risks
### Dependencies
- `uap-docs.sh` status 허용값 전환
- 기존 문서 링크 일괄 갱신
- CI 문서 검증 워크플로와 새 status 체계 정합성

### Risks
- rename 누락으로 broken link 발생
- status 전환 중 일부 문서가 old/new 체계를 혼용
- AppleDouble 재유입으로 리뷰 노이즈 증가

### Mitigations
- rename map(`uap-core7-rename-map.tsv`)을 source of truth로 사용
- 단계별로 `check` 실행 (Phase 1 완료 시 1회, 최종 1회)
- `find . -name '._*'` 점검을 검증 루틴에 포함

## References & Research
### Internal references
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-uap-doc-topology-canonicalization-brainstorm.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`

### Notes
- `docs/solutions/`에는 본 주제와 연계할 institutional learning 문서가 현재 없다.

## MVP Pseudo Worklist
### docs/workbench/unified-personal-agent-platform/audits/uap-core7-rename-map.tsv
```text
current_path\ttarget_path\tclass
```

### docs/workbench/unified-personal-agent-platform/audits/uap-core7-reference-audit.txt
```text
<file_path>:<line_number> -> <old_reference>
```

### docs/workbench/unified-personal-agent-platform/audits/uap-core7-rollout-note.md
```markdown
# rollout note
- changed paths
- compatibility notes
- follow-up TODOs
```
