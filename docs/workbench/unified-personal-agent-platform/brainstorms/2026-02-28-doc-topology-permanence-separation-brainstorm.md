---
title: Docs Topology Permanence Separation Brainstorm
type: brainstorm
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Evaluates topology options and selects canonical-vs-workbench separation as the operating model.
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
topic: doc-topology-permanence-separation
---

# Docs Topology Permanence Separation Brainstorm

## What We're Building
`docs` 구조를 "문서 성격(영속성)" 기준으로 재정렬한다.

핵심 목표는 다음 두 가지다.
- `initiative` 본체(운영 기준 문서)를 명확히 고정한다.
- 일회성 산출물(브레인스토밍/계획/리뷰 로그)이 본체와 섞여 보이지 않게 분리한다.

즉, "실행 중 생성되는 작업 산출물"과 "지속적으로 참조되는 canonical 문서"를 구조적으로 분리해, 에이전트/사람 모두가 시작 문맥을 빠르게 잡을 수 있게 만든다.

## Why This Approach
검토한 접근은 3가지다.

### Approach A (Recommended): `Canonical vs Workbench` 2-축 분리
- Canonical: `docs/initiatives/<initiative>/...`
- Workbench: `docs/workbench/<initiative>/{brainstorms,plans,reviews,audits}/...`

**Pros**
- 영속성 기준이 디렉토리에서 즉시 드러남
- initiative가 본체라는 전제가 가장 잘 유지됨
- 자동화(검증/카탈로그) 적용 범위를 명확히 분기 가능

**Cons**
- 기존 `docs/plans`, `docs/brainstorms` 마이그레이션 필요

### Approach B: 전역 분리 유지 (`docs/brainstorms`, `docs/plans`) + naming만 강화
**Pros**
- 변경 비용 작음

**Cons**
- initiative 본체와 작업 산출물이 계속 병치되어 혼동 유지

### Approach C: initiative 내부에 `99-workbench` 추가
**Pros**
- initiative 맥락에 가깝게 산출물 관리

**Cons**
- 본체와 산출물의 물리적 분리가 약함
- `99-*`가 장기적으로 잡동사니 레이어가 될 위험

추천은 A다. 이유는 "본체와 일회성 산출물의 구조적 분리"라는 문제 정의를 가장 직접적으로 해결하기 때문이다.

## Key Decisions
- 문서 토폴로지는 "도메인" 이전에 "영속성"을 1차 축으로 둔다.
- `docs/initiatives/`는 canonical only로 운영한다.
- 일회성 산출물은 `docs/workbench/<initiative>/...`로 이동한다.
- workbench 하위 분류는 최소 집합으로 시작한다:
  - `brainstorms/`
  - `plans/`
  - `reviews/`
  - `audits/`
- 각 산출물 frontmatter에 `lifecycle: workbench | canonical` 필드를 추가해 자동 검증 가능성을 연다.

## Resolved Questions
- initiative가 본체인가? → 예. `docs/initiatives/<initiative>`를 canonical source로 고정.
- 일회성 산출물과 기준 문서를 물리적으로 분리할 것인가? → 예.
- 분리 기준은 무엇인가? → 문서의 영속성(운영 기준 여부).

## Open Questions
- 없음 (다음 단계는 실행 계획 수립으로 충분)

## Next Steps
1. `docs/plans`, `docs/brainstorms`의 파일을 `docs/workbench/unified-personal-agent-platform/...`로 이동하는 migration plan 작성
2. `README`/`AGENT-START`/`uap-document-map`에서 canonical entry와 workbench entry를 분리 표기
3. `uap-docs.sh` 검증 범위를 canonical/workbench로 분기하거나 profile 옵션 추가
4. 기존 링크에 대한 rewrite map과 audit 로그 생성
