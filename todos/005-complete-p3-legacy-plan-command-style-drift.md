---
status: complete
priority: p3
issue_id: "005"
tags: [code-review, docs, planning]
dependencies: []
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# Legacy Execution Plan Still Shows Old Local Command Style

## Problem Statement
문서 계약을 repo-root 명령 기준으로 통일했지만, 일부 legacy 실행계획 문서가 기존 `bash ./00-governance/scripts/uap-docs.sh check` 예시를 유지하고 있다. 핵심 운영 문서는 아니지만 참조 시 실행 컨텍스트 해석 혼선을 줄 수 있다.

## Findings
- legacy migration 계획 문서에 구 경로 명령이 남아 있다.
  - `docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md:165`
- 현재 코어 문서는 정렬되었지만, legacy plan까지 확장하면 문서 전역 일관성은 아직 미완료다.

## Proposed Solutions

### Option 1: legacy plan의 명령 예시도 repo-root 기준으로 갱신

**Approach:** 해당 코드블록의 명령을 repo-root 경로로 교체한다.

**Pros:**
- 문서 전체 컨텍스트 일관성 향상
- 복사 실행 시 혼선 감소

**Cons:**
- historical 문서를 현재 기준으로 수정하는 정책 합의 필요

**Effort:** Small

**Risk:** Low

---

### Option 2: legacy 문서는 유지하고 주석으로 "historical command style" 명시

**Approach:** 기존 명령은 유지하되 현재 표준은 repo-root라고 주석 추가.

**Pros:**
- 역사적 맥락 유지

**Cons:**
- 문서가 장황해질 수 있음
- 사용자 혼선이 완전히 사라지지 않음

**Effort:** Small

**Risk:** Low

## Recommended Action
완료. legacy migration plan과 루트 README의 구 명령 스타일을 repo-root 기준으로 정렬했다.

## Technical Details
**Affected files:**
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md`

## Resources
- Review context: `/prompts:workflows-review` after path-contract alignment work

## Acceptance Criteria
- [x] 해당 legacy 계획 문서의 명령 표기가 현재 경로 계약과 충돌하지 않는다.
- [x] 사용자/에이전트가 명령 복사 실행 시 실행 컨텍스트를 오해하지 않는다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- core 문서 외 잔여 패턴 검색에서 legacy 계획 문서의 구 명령 표기를 확인했다.
- 영향도를 P3(운영 차단 아님, 혼선 리스크)로 분류했다.

**Learnings:**
- core 정렬 이후에도 legacy 문서의 예시 명령은 장기적으로 드리프트 소스가 된다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `2026-02-27-uap-doc-structure-migration.execution-plan.md`의 검증 명령을 repo-root 기준으로 교체했다.
- 루트 `README.md` quick-start 명령도 동일 기준으로 정렬했다.

**Learnings:**
- legacy 문서와 루트 진입 문서를 같이 맞춰야 실제 사용 경로에서 혼선이 줄어든다.
