---
status: complete
priority: p3
issue_id: "003"
tags: [code-review, docs, navigation]
dependencies: []
---

# Entry Core Self-reference Adds Onboarding Noise

## Problem Statement
Entry Core 목록에 현재 문서 자신을 포함해 온보딩 단계가 no-op으로 보인다. 치명적 오류는 아니지만, 신규 에이전트가 "실행 가능한 다음 단계"를 빠르게 파악해야 하는 문서에서 집중도를 떨어뜨린다.

## Findings
- AGENT-START의 Entry Core 1번이 자기 자신이다.
  - `docs/initiatives/unified-personal-agent-platform/AGENT-START.md:38`
- Document Map의 Entry Core에도 현재 문서(self)가 포함된다.
  - `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md:44`

## Proposed Solutions

### Option 1: self-reference를 목록에서 제거

**Approach:** 현재 문서는 목록 외 설명으로만 남기고, 실행 순서에는 다른 핵심 문서만 둔다.

**Pros:**
- 온보딩 절차가 더 직관적
- 실제 행동 가능한 다음 문서 중심으로 정리

**Cons:**
- Core 5 정의 표현을 일부 조정해야 함

**Effort:** 15-30분

**Risk:** Low

---

### Option 2: self-reference 유지 + 목적을 명확히 주석화

**Approach:** self-entry가 "현재 위치 확인" 목적임을 명시한다.

**Pros:**
- 기존 Core 매핑 유지

**Cons:**
- 여전히 행동 순서 관점에서는 노이즈

**Effort:** 10-20분

**Risk:** Low

## Recommended Action
완료. Entry Core 목록에서 self-reference를 제거하고 현재 문서가 anchor임을 설명 노트로 분리했다.

## Technical Details
**Affected files:**
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`

## Resources
- Review context: current working tree (uncommitted)

## Acceptance Criteria
- [x] Entry Core 목록이 self-reference 없이도 Core 7 의도를 명확히 전달한다.
- [x] 온보딩 Read Order가 "다음 행동" 중심으로 해석된다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- Entry Core 섹션을 문서별로 대조해 self-reference 항목을 확인했다.
- 영향도와 개선 옵션을 정리했다.

**Learnings:**
- 온보딩 문서는 중복/자가참조를 줄일수록 에이전트 초기 판단 비용이 낮아진다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `AGENT-START` Entry Core 목록에서 self-reference를 제거하고 next-reads 구조로 재구성했다.
- `uap-document-map` Entry Core 목록에서도 self-reference를 제거하고 노트로 처리했다.

**Learnings:**
- self-reference를 본문 행동 목록에서 분리하면 온보딩 단계 해석이 더 직관적이다.
