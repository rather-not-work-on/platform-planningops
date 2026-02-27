---
doc_id: uap-doc-structure-migration-plan
title: UAP Documentation Structure Migration Plan
doc_type: execution-plan
domain: planning
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
tags:
  - uap
  - docs
  - structure
  - migration
summary: Defines a phased, reference-safe migration from current layer-first docs layout to repo-first plus domain-second layout.
related_docs:
  - ../README.md
  - ../00-governance/2026-02-27-uap-doc-governance.meta.md
  - ../00-governance/2026-02-27-uap-monday-identity.meta.md
  - ../90-navigation/2026-02-27-uap-document-map.navigation.md
---

# UAP Documentation Structure Migration Plan

## Purpose
현재 문서 구조를 한 번에 뒤집지 않고, 참조 무결성을 유지하며 `repo-first + domain-second` 구조로 단계 전환한다.

## Review Summary (Document-Review Outcome)
평가(최신화):
- Clarity: 5/5 (목표 구조와 단계가 명시됨)
- Completeness: 5/5 (매핑표/검증/롤백 계약 포함)
- Specificity: 5/5 (batch 단위 절차와 종료 기준이 구체적임)
- YAGNI: 5/5 (현재 scope 내 필수 요소만 유지)

Critical improvement (closed):
- `링크/related_docs`를 안전하게 갱신하는 migration contract를 문서 기준으로 고정했고, pilot batch를 `verified` 상태로 기록했다.

## Target Layout (After Migration)
상위 축은 `repo`, 하위 축은 `domain`으로 고정한다.

```text
unified-personal-agent-platform/
  00-governance/
  10-brainstorm/
  20-architecture/
  20-repos/
    monday/
      10-discovery/
      20-architecture/
      30-execution-plan/
      40-quality/
    platform-contracts/
      10-discovery/
      20-architecture/
      30-execution-plan/
    platform-provider-gateway/
      10-discovery/
      20-architecture/
      30-execution-plan/
    platform-observability-gateway/
      10-discovery/
      20-architecture/
      30-execution-plan/
  30-domains/
    planningops/
    contract-evolution/
    observability/
  30-execution-plan/
  40-quality/
  90-navigation/
```

경로 기준:
- 매핑표의 `old_path`, `new_path`는 모두 `docs/` 루트 기준 상대경로로 기록한다.

## Migration Principles
1. Big-bang 이동 금지
2. 한 번에 한 단위(repo 또는 domain)만 이동
3. 이동 batch마다 `uap-docs.sh check` 통과 전 다음 단계 금지
4. 구조 변경과 내용 변경을 같은 커밋에 섞지 않음

## Phased Plan
### Phase 0: Baseline freeze
- 현재 구조에서 `uap-docs.sh sync` 통과 상태를 baseline으로 고정
- 이동 대상/신규 경로 매핑표 작성

Exit criteria:
- baseline commit과 매핑표가 존재

### Phase 0 Deliverable: Path Mapping Table
`구경로 -> 신경로`를 아래 포맷으로 작성한다.

저장 위치(권장):
- `00-governance/migration/path-map.csv`
- `00-governance/migration/batch-log/<batch-id>.md`

| id | batch | repo_scope | old_path | new_path | related_docs_updated | markdown_links_updated | status | notes |
|---|---|---|---|---|---|---|---|---|
| M-001 | monday-pilot | monday | `10-brainstorm/2026-02-27-uap-core.brainstorm.md` | `20-repos/monday/10-discovery/2026-02-27-uap-core.brainstorm.md` | yes | yes | verified | moved in phase 2 |
| M-002 | monday-pilot | monday | `10-brainstorm/2026-02-27-uap-failure-simulation.simulation.md` | `20-repos/monday/10-discovery/2026-02-27-uap-failure-simulation.simulation.md` | yes | yes | verified | moved in phase 2 |
| M-003 | monday-pilot | monday | `10-brainstorm/2026-02-27-uap-approach-options.strategy.md` | `20-repos/monday/10-discovery/2026-02-27-uap-approach-options.strategy.md` | yes | yes | verified | moved in phase 2 |
| M-004 | monday-pilot | monday | `20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md` | `20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md` | yes | yes | verified | moved in phase 2 |
| M-005 | monday-pilot | monday | `30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md` | `20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md` | yes | yes | verified | moved in phase 2 |
| M-006 | monday-pilot | monday | `40-quality/2026-02-27-uap-issue-closure-matrix.quality.md` | `20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md` | yes | yes | verified | moved in phase 2 |
| M-007 | monday-pilot | cross-cut | `20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` | `20-architecture/2026-02-27-uap-contract-boundaries.architecture.md` | n/a | n/a | verified | retained at root by policy |

상태 규칙:
- `planned`: 이동 전
- `moved`: 파일 이동 완료
- `linked`: related_docs/링크 갱신 완료
- `verified`: check 통과
- `rolled_back`: 배치 롤백 완료

Batch ID 규칙:
- `<repo-scope>-<phase>-<seq>` 형태 사용
- 예: `monday-p2-01`, `platform-contracts-p3-02`

배치 완료 기준:
- 해당 batch 모든 row가 `verified`

### Phase 1: Scaffold only (Completed)
- `20-repos/*`, `30-domains/*` 디렉토리와 각 `README.md`만 생성
- 기존 문서 이동은 하지 않음

Exit criteria:
- 신규 scaffold가 탐색 가능
- 기존 링크 100% 유지

### Phase 2: Pilot migration (`monday`) (Completed)
- `monday` 관련 문서를 신규 경로로 이동
- 이동된 문서의 `related_docs`/Markdown 링크를 매핑표 기준으로 갱신
- cross-cut 문서는 Phase 4 전까지 이동하지 않는다

Exit criteria:
- pilot batch에서 `uap-docs.sh check` 통과
- broken link 0

### Phase 3: Shared repos migration
- `platform-contracts`, `platform-provider-gateway`, `platform-observability-gateway` 순서로 반복

Exit criteria:
- 각 repo batch별 check green

### Phase 4: Domain cross-cut finalize
- `30-domains/*`에 cross-cut 문서 정리
- 중복 문서를 링크 허브로 축소

Exit criteria:
- document map과 README가 최종 구조 반영

## Reference Update Contract
이동 시 아래 4개를 항상 같이 갱신한다.
1. 문서 frontmatter의 `related_docs`
2. 본문 Markdown 상대 링크
3. `README.md` 읽기 순서/바로가기 링크
4. `90-navigation` 문서 맵 링크

분류 규칙(이동 전 판정):
- `repo-specific`: `20-repos/<repo>/...`로 이동
- `cross-cut`: `30-domains/...`로 이동
- `governance/navigation`: 기존 루트 레이어 유지

검증 명령:
```bash
bash ./00-governance/scripts/uap-docs.sh check
```

링크 영향 탐색(권장):
```bash
OLD="30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md"
rg -n "$OLD" . -g "*.md"
```

## Batch Run Checklist (Template)
각 batch마다 아래를 복사해 실행 로그로 남긴다.

```text
Batch ID:
Scope:

[ ] mapping table 대상 row 확정
[ ] 파일 이동 수행
[ ] moved status 반영
[ ] related_docs 갱신
[ ] 본문 Markdown 링크 갱신
[ ] README / 90-navigation 갱신 필요 여부 확인
[ ] uap-docs.sh check 통과
[ ] 구경로 잔존 검색 결과 0건 확인
[ ] linked / verified status 반영
[ ] batch commit 생성
```

구경로 잔존 검색(보조):
```bash
rg -n "구경로-패턴" . -g "*.md"
```

## Safety and Rollback
- batch 단위 커밋: 실패 시 해당 batch만 되돌림
- check fail 시 즉시 이동 중단 후 링크 복구
- 미검증 상태에서 추가 이동 금지

## Done Criteria
- 목표 구조가 반영된 최종 document map 존재
- `uap-docs.sh sync` 통과
- 신규 에이전트가 `README -> AGENT-START -> document-map`만으로 문서 위치를 찾을 수 있음
