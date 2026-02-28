---
status: complete
priority: p2
issue_id: "004"
tags: [code-review, docs, automation, quality]
dependencies: []
---

# Catalog Generator Reintroduces Old Command Path Style

## Problem Statement
경로 계약을 repo-root 명령 기준으로 정렬했지만, 카탈로그 생성기(`uap-docs.sh`) 템플릿이 아직 구 경로(`bash ./00-governance/...`)를 출력한다. `sync`를 실행할 때마다 생성 문서에 구 패턴이 재유입되어 문서 계약이 지속적으로 드리프트한다.

## Findings
- 생성기 템플릿이 구 명령 예시를 하드코딩한다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:310`
- 실제 생성 산출물도 동일한 구 명령을 포함한다.
  - `docs/initiatives/unified-personal-agent-platform/2026-02-27-uap-frontmatter-catalog.navigation.md:27`
- 현재 `sync`는 항상 카탈로그를 재생성하므로, 수동 수정 없이 드리프트가 자동 반복된다.

## Proposed Solutions

### Option 1: 생성기 템플릿을 repo-root 명령으로 교체 (권장)

**Approach:** `uap-docs.sh` 내 카탈로그 헤더 텍스트를 repo-root 예시로 변경하고 `sync` 재실행으로 산출물 갱신.

**Pros:**
- 원인 제거로 재발 방지
- 문서 계약과 자동화 출력 정합성 확보

**Cons:**
- 카탈로그 파일 diff 재생성 필요

**Effort:** Small (15-30분)

**Risk:** Low

---

### Option 2: 카탈로그 본문에서 생성 명령 항목 삭제

**Approach:** 생성 명령 안내 자체를 제거해 경로 스타일 충돌면을 줄인다.

**Pros:**
- 경로 드리프트 위험 제거

**Cons:**
- 사용자 안내 정보 감소

**Effort:** Small

**Risk:** Low

## Recommended Action
완료. 생성기 템플릿의 명령 예시를 repo-root 기준으로 수정하고 `sync` 재생성 결과까지 검증했다.

## Technical Details
**Affected files:**
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`
- `docs/initiatives/unified-personal-agent-platform/2026-02-27-uap-frontmatter-catalog.navigation.md`

## Resources
- Review context: `/prompts:workflows-review` after path-contract alignment work

## Acceptance Criteria
- [x] `uap-docs.sh` 카탈로그 템플릿이 repo-root 명령 예시를 출력한다.
- [x] `uap-docs.sh sync` 이후 카탈로그에 `bash ./00-governance/...` 패턴이 0건이다.
- [x] 경로 계약 문구와 자동 생성 문서 간 불일치가 재발하지 않는다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- 경로 정합성 재검색 중 카탈로그 생성기 템플릿과 산출물의 구 명령 패턴을 확인했다.
- `sync` 재생성 경로를 점검해 자동 재유입 리스크를 식별했다.

**Learnings:**
- 자동 생성 문서의 템플릿이 바뀌지 않으면 수동 정리는 의미가 없다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `uap-docs.sh` 카탈로그 생성 템플릿의 생성 스크립트/생성 명령 경로를 repo-root 기준으로 정렬했다.
- `uap-docs.sh sync`를 실행해 카탈로그를 재생성하고 구 패턴 잔여 여부를 검색 검증했다.

**Learnings:**
- 생성기 템플릿을 먼저 고정해야 이후 문서 정합성이 안정적으로 유지된다.
