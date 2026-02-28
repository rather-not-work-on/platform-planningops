---
date: 2026-02-28
topic: uap-doc-topology-canonicalization
---

# UAP Documentation Topology Consolidation Brainstorm

## What We're Building
레거시/중복/노이즈가 섞인 현재 문서 지형을, 에이전트 실행 친화적인 "명확한 토폴로지"로 재정렬한다.
핵심은 문서 수를 줄이는 것이 아니라, "무엇이 기준 문서인지"를 즉시 알 수 있게 만드는 것이다.

대상은 구현 코드가 아니라 planning 문서 체계이며, 목표는 다음 4가지다.
- 읽기 경로 단일화
- 우선순위 해석 충돌 제거
- 정책 문서의 강제력 확보
- LLM 컨텍스트 노이즈 최소화

## Why This Approach
선택한 접근은 `Canonical Core + Legacy 분리`다.
이 방식은 기존 문서 자산을 버리지 않으면서도, 에이전트가 항상 동일한 기준 문맥에서 시작하도록 만든다.

문서 운영 모델은 `5+2 이중 코어`로 고정한다.
- Entry Core 5개: 빠른 진입과 실행 기준
- Policy Core 2개: 판단 흔들림 방지

또한 코어 문서는 날짜 기반 파일명이 아니라 고정 canonical 파일명(`uap-*`)으로 전환해 참조 안정성을 높인다.

## Key Decisions
- 접근 방식: `A. Canonical Core + Legacy 분리`
- 코어 구조: `5+2 이중 코어`
- 파일명 정책: 코어 7개는 `uap-*` 무날짜 canonical 이름으로 전환
- 전환 범위: 1차는 코어 7개만 전환(리스크 최소화)
- 상태 체계: `active / reference / deprecated`
- 용어 기준:
  - `Entry Core`: 에이전트가 항상 먼저 읽는 5개 기준 문서
  - `Policy Core`: 판단/정합성 기준을 강제하는 2개 정책 문서
  - `Core 7`: `Entry Core + Policy Core`
  - `Non-core`: Core 7을 제외한 모든 문서
- 경로 표기 기준:
  - 문서 본문 경로는 `initiative 루트 상대경로`로 통일한다(예: `00-governance/uap-doc-governance.meta.md`).
  - 명령/스크립트 문맥에서만 `repo 루트 상대경로`를 사용한다(예: `docs/initiatives/unified-personal-agent-platform/...`).
  - 동일 목록/표 안에서 두 기준을 혼용하지 않는다.
- 코어 7개(무날짜 canonical 전환 대상):
  - `AGENT-START.md`
  - `AGENT.md`
  - `00-governance/uap-monday-identity.meta.md`
  - `90-navigation/uap-document-map.navigation.md`
  - `30-execution-plan/uap-github-planningops-sync.execution-plan.md`
  - `00-governance/uap-doc-governance.meta.md`
  - `40-quality/uap-planningops-tradeoff-decision-framework.quality.md`
- Policy Core 확정 문서:
  - `00-governance/uap-doc-governance.meta.md`
  - `40-quality/uap-planningops-tradeoff-decision-framework.quality.md`

## Resolved Questions
- 코어 파일명에서 날짜를 유지할지: 유지하지 않음(무날짜 canonical)
- 문서 정책을 코어에 포함할지: 포함(5+2 이중 코어)
- 코어 외 문서 상태 체계: 3단계(`active/reference/deprecated`)

## Open Questions
- 없음

## Next Steps
1. 코어 7개 무날짜 파일명으로 rename하고 내부 참조 일괄 갱신
   - rename 시 경로 표기 기준을 `initiative 루트 상대경로`로 통일
2. Document Map/AGENT-START에 `Entry Core`와 `Policy Core`를 분리 명시
3. 코어 외 문서에 `status`를 `active/reference/deprecated`로 정리
   - 분류 기준: 현재 운영 의사결정에 직접 사용되면 `active`, 배경/맥락 참고용이면 `reference`, 대체 문서가 있어 직접 참조를 중단하면 `deprecated`
4. 변경 후 문서 검증(`uap-docs.sh check`, `uap-docs.sh sync`) 실행
