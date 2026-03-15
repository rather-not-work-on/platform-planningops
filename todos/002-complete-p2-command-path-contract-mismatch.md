---
status: complete
priority: p2
issue_id: "002"
tags: [code-review, docs, automation, onboarding]
dependencies: []
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# Command Path Contract Mismatch in Runbook Examples

## Problem Statement
문서 규칙은 CLI/CI 명령에 repo 루트 기준 경로 사용을 요구하지만, 실제 온보딩/README 예시는 initiative 디렉토리 기준 상대경로(`./00-governance/...`)를 사용한다. 실행 위치에 따라 명령 성공/실패가 갈려 에이전트 실행 재현성이 떨어진다.

## Findings
- Path 규칙은 repo-root 경로 사용을 명시한다.
  - `docs/initiatives/unified-personal-agent-platform/AGENT-START.md:34`
  - `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md:37`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md:94`
- 그러나 Quick Check/Automation 예시는 initiative-root 실행을 전제로 한다.
  - `docs/initiatives/unified-personal-agent-platform/AGENT-START.md:57`
  - `docs/initiatives/unified-personal-agent-platform/README.md:95`
  - `docs/initiatives/unified-personal-agent-platform/README.md:97`
  - `docs/initiatives/unified-personal-agent-platform/README.md:101`
- 생성 스크립트의 usage/next 메시지도 동일 패턴을 출력한다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh:74`
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh:186`

## Proposed Solutions

### Option 1: 모든 예시 명령을 repo-root 기준으로 통일

**Approach:** 예시를 `bash docs/initiatives/unified-personal-agent-platform/...` 형식으로 교체한다.

**Pros:**
- 규칙과 예시 완전 일치
- CI/로컬/에이전트 실행 재현성 향상

**Cons:**
- 명령 문자열이 길어짐

**Effort:** 30-60분

**Risk:** Low

---

### Option 2: initiative-root 실행 전제를 공식화

**Approach:** 규칙을 수정해 "initiative 루트에서 실행"을 기본 전제로 명시한다.

**Pros:**
- 현재 예시 유지 가능
- 문서 수정 범위 축소

**Cons:**
- repo-root 표준과 충돌
- 외부 자동화/CI 문맥에서 혼란 가능

**Effort:** 30분

**Risk:** Medium

---

### Option 3: 두 방식 모두 허용하되 명시적으로 병기

**Approach:** 각 명령에 repo-root/initiative-root 두 버전을 함께 제공한다.

**Pros:**
- 사용자 유연성 확보

**Cons:**
- 문서 장황화
- 표준 경로를 흐릴 가능성

**Effort:** 1-2시간

**Risk:** Medium

## Recommended Action
완료. 명령 예시를 repo-root 기준으로 통일하고 생성 스크립트의 usage/next 출력도 같은 기준으로 맞췄다.

## Technical Details
**Affected files:**
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/README.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh`

## Resources
- Review context: current working tree (uncommitted)

## Acceptance Criteria
- [x] 명령 예시가 하나의 기준 경로 체계로 통일된다.
- [x] `uap-new-doc.sh` usage/next 출력이 동일 기준을 따른다.
- [x] AGENT-START/README/Governance/Document Map 간 문구 불일치가 0건이다.

## Work Log

### 2026-02-28 - Initial Discovery

**By:** Codex

**Actions:**
- 규칙 섹션과 실제 실행 예시를 교차 검토했다.
- 스크립트 출력 메시지까지 포함해 경로 기준 불일치 지점을 수집했다.
- 통일 전략 옵션(1~3)을 정리했다.

**Learnings:**
- repo-root vs initiative-root 혼용은 에이전트 실행 실패를 유발하기 쉬운 유형이다.
- 한 가지 canonical 실행 컨텍스트를 강제하는 편이 운영 비용이 낮다.

### 2026-02-28 - Resolution

**By:** Codex

**Actions:**
- `AGENT-START`, initiative `README`, `uap-doc-governance` 명령 예시를 repo-root 경로로 통일했다.
- `uap-new-doc.sh`의 usage 예시와 완료 메시지(`next`)를 repo-root 기준으로 수정했다.
- `uap-docs.sh check/sync`로 문서 무결성을 재검증했다.

**Learnings:**
- 명령 예시가 규칙 문구와 다르면 복사 실행 실패가 빠르게 재발한다.

## Notes
- 문서 자동화 CI는 현재 repo-root 경로를 사용하고 있어, 예시와의 괴리가 실제 운영 혼선을 확대할 수 있다.
