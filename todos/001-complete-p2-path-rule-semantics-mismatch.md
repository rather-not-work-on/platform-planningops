---
status: complete
priority: p2
issue_id: "001"
tags: [code-review, docs, governance, quality]
dependencies: []
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# Path Rule Semantics Mismatch (Initiative-root vs File-relative)

## Problem Statement
문서 정책에서 "initiative 루트 기준 상대경로"를 요구하지만, 실제 검증 스크립트는 문서 파일 위치 기준 상대경로만 허용한다. 작성자가 정책대로 문서를 작성하면 `uap-docs.sh check`가 실패할 수 있어 문서 정합성 운영에 혼선을 만든다.

## Findings
- 정책 문서가 본문 링크/`related_docs`를 initiative 루트 기준 상대경로라고 명시한다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md:93`
- AGENT START와 Document Map도 동일 표현을 반복한다.
  - `docs/initiatives/unified-personal-agent-platform/AGENT-START.md:33`
  - `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md:36`
- 검증 스크립트는 현재 문서 디렉토리(`base_dir`)에 링크를 결합해 검사한다(파일 상대경로 모델).
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:223`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:225`

## Proposed Solutions

### Option 1: 정책 문구를 파일 상대경로 기준으로 수정

**Approach:** Path 규칙 문구를 "문서 파일 기준 상대경로"로 명확화하고 예시를 함께 갱신한다.

**Pros:**
- 현재 검증기/문서와 즉시 일치
- 구현 변경 없이 혼선 제거

**Cons:**
- 기존 "initiative 루트" 표현을 신뢰한 독자에게 변경 안내 필요

**Effort:** 30-60분

**Risk:** Low

---

### Option 2: 검증기를 initiative-root 상대경로도 허용하도록 확장

**Approach:** `uap-docs.sh`에서 루트 기준 경로 해석을 추가해 양쪽 문법을 허용한다.

**Pros:**
- 기존 문구를 유지 가능
- 작성자 관점 유연성 증가

**Cons:**
- 규칙이 이중화되어 장기적으로 일관성 저하
- 경로 해석 복잡도 증가

**Effort:** 2-4시간

**Risk:** Medium

---

### Option 3: 루트-상대 표기를 canonical로 전환 + 자동 변환 도구 추가

**Approach:** 문서를 루트-상대 표기로 통일하고, 변환/검증 유틸리티를 추가한다.

**Pros:**
- 장기 표준화 가능
- 명령 경로와 문서 경로 철학 일치

**Cons:**
- 대규모 일괄 수정 필요
- 기존 링크 구조와 충돌 가능

**Effort:** 1-2일

**Risk:** Medium

## Recommended Action
완료. Path 규칙 문구를 검증기 동작 기준(문서 파일 상대경로)으로 정렬했고, 핵심 문서와 명령 예시를 동기화했다.

## Technical Details
**Affected files:**
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`

## Resources
- Review context: current working tree (uncommitted)

## Acceptance Criteria
- [x] Path 규칙 문구가 검증기 동작(파일 상대경로)과 정확히 일치한다.
- [x] AGENT-START / Document Map / Governance 3개 문서에서 동일 표현을 사용한다.
- [x] 예시 링크 2개 이상이 새 규칙에 맞게 검증(`uap-docs.sh check`) 통과한다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- Path 규칙 문구와 검증 스크립트의 경로 해석 방식을 대조했다.
- 정책 문서 3곳과 스크립트 핵심 라인 근거를 수집했다.
- 해결 옵션 3개를 정리했다.

**Learnings:**
- 현재 시스템의 실제 canonical 경로 해석은 "문서 파일 상대"다.
- 문구 불일치가 반복되면 에이전트/작성자 실수가 구조적으로 재발할 수 있다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `uap-doc-governance`, `AGENT-START`, `uap-document-map`의 Path Rule 문구를 파일 상대경로 기준으로 통일했다.
- `uap-docs.sh check` 및 `sync`를 실행해 링크/카탈로그 유효성을 재검증했다.

**Learnings:**
- 문서 계약은 검증기의 실제 해석 기준과 1:1로 맞춰야 재발 방지가 가능하다.

## Notes
- Protected artifacts(`docs/plans/*`, `docs/solutions/*`) 삭제/무시 제안은 본 finding 범위에 포함하지 않음.
