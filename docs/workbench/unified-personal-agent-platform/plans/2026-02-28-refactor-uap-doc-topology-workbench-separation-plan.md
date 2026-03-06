---
title: refactor: Separate UAP Workbench Outputs from Canonical Docs
type: plan
plan_kind: refactor
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Execution plan for separating canonical initiative docs from initiative-scoped workbench artifacts.
source_brainstorm: docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-doc-topology-permanence-separation-brainstorm.md
---

# refactor: Separate UAP Workbench Outputs from Canonical Docs

## Overview
문서 구조를 `canonical`과 `workbench`로 분리해, initiative 본체 문서와 일회성 작업 산출물이 섞여 보이는 문제를 제거한다.

핵심 목표:
- `docs/initiatives/<initiative>/...`를 canonical source로 고정
- 브레인스토밍/플랜/리뷰/감사 로그를 `docs/workbench/<initiative>/...`로 분리
- 문서 검증/네비게이션/온보딩 계약을 새 토폴로지에 맞춰 일관화

## Problem Statement / Motivation
현재는 다음 불일치가 동시에 존재한다.

1. 토폴로지 의미 충돌
- 실제 산출물은 `docs/brainstorms`, `docs/plans`에 존재하지만,
- initiative README는 과거 마이그레이션 완료 상태를 암시한다.

2. canonical/workbench 경계 불명확
- 실행 중 생성되는 문서와 장기 기준 문서가 `/docs` 하위에서 혼재되어 탐색 비용이 높다.

3. 검증 범위 불일치
- `uap-docs.sh`는 initiative 루트 문서만 대상으로 검증/카탈로그를 수행하며,
- 루트 workbench성 문서들은 운영 계약 밖에 남는다.

목표는 "문서 수를 줄이는 것"이 아니라 "에이전트가 잘못된 문맥으로 들어갈 확률을 구조적으로 낮추는 것"이다.

## Brainstorm Context
Found brainstorm from `2026-02-28`: `doc-topology-permanence-separation`. Using as context for planning.

브레인스토밍 확정 결정:
- 추천안은 `Canonical vs Workbench` 2축 분리
- `docs/initiatives/`는 canonical only
- 일회성 산출물은 `docs/workbench/<initiative>/{brainstorms,plans,reviews,audits}`
- 산출물 frontmatter에 `lifecycle`를 추가해 자동 검증 가능성 확보

## Research Findings (Local)
### Repository patterns
- 브레인스토밍에서 분리안 A를 명시적으로 권장하고 있다.
  - `docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-doc-topology-permanence-separation-brainstorm.md:20`
- 현재 루트 README 토폴로지에는 `docs/brainstorms`, `docs/plans`가 반영되어 있지 않다.
  - `README.md:24`
- initiative README는 "기존 docs/brainstorms, docs/plans가 이 루트로 이동"되었다고 기술하지만 현재 상태와 불일치한다.
  - `docs/initiatives/unified-personal-agent-platform/README.md:120`
- `uap-docs.sh`는 initiative 루트를 `ROOT_DIR`로 잡아 그 하위만 검증한다.
  - `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh:6`
- 작업 디렉토리에 AppleDouble 메타파일(`._*`)이 유입되어 문서 노이즈가 발생한다.
  - `docs/workbench/unified-personal-agent-platform/brainstorms/._2026-02-28-doc-topology-permanence-separation-brainstorm.md`

### Learnings corpus
- `docs/solutions/` 경로에 본 주제와 연계할 institutional learning 문서는 현재 없다.

## Research Decision
- External research는 생략한다.
- 본 작업은 외부 API/보안/규제 이슈가 아닌 내부 문서 운영 계약 리팩터링이며, 로컬 근거가 충분하다.

## Scope
### In scope
- `docs/workbench/<initiative>/...` 디렉토리 신설
- 기존 `docs/brainstorms`, `docs/plans` 산출물 마이그레이션
- canonical/workbench 경계 규칙 문서화(`README`, `AGENT-START`, `uap-document-map`, `uap-doc-governance`)
- 검증 스크립트 profile 분리(`canonical`, `workbench`, `all`) 또는 동등한 범위 제어 도입
- 링크 rewrite map + audit 로그 생성

### Out of scope
- UAP 도메인 계약(C1~C8) 내용 변경
- 실행 레포(`monday`, `platform-*`)의 런타임 구현 변경
- GitHub tracker 자동 동기화 로직 자체의 기능 확장

## Kanban Delivery Model
비정기 에이전트 실행 특성을 반영해 스프린트 대신 칸반으로 운영한다.

### Board columns
1. `Backlog` (정의됨, 착수 전)
2. `Ready` (입력/의존성 충족)
3. `Doing` (WIP 제한 적용)
4. `Review` (문서/링크/스크립트 검증)
5. `Done` (검증 통과 + 증적 첨부)

### WIP limits
- `Doing`: 최대 2
- `Review`: 최대 2
- 긴급 패치 lane 1개만 예외 허용

### Pull policy
- 각 카드에 `entrypoint`, `affected_paths`, `validation_commands`를 필수 기입
- `Ready` 진입 전 의존성(선행 이동/링크맵/스크립트 옵션) 명시

### Done policy
- `uap-docs.sh` 검증 통과
- stale path (`docs/brainstorms`, `docs/plans`) 참조 0건
- audit artifact 첨부

## Proposed Topology & Contracts
### Target topology
```text
docs/
  initiatives/
    unified-personal-agent-platform/   # canonical only
  workbench/
    unified-personal-agent-platform/
      brainstorms/
      plans/
      reviews/
      audits/
```

### Lifecycle contract
- canonical 문서: `lifecycle: canonical`
- workbench 문서: `lifecycle: workbench`
- canonical 문서에서 workbench 문서를 규범(SoT)로 인용하지 않는다.
- workbench 문서는 canonical 문서를 상위 기준으로 참조한다.

### Path contract
- 문서 링크/`related_docs`: 문서 파일 기준 상대경로
- CLI/CI 명령: repo 루트 기준 상대경로
- initiative 내부 경로는 canonical root(`docs/initiatives/<initiative>`) 기준으로 표기

### Promotion contract (workbench -> canonical)
1. workbench 문서에서 `status: active`는 "workbench 내 활성" 의미로만 사용
2. canonical 승격 시 새 canonical 문서 생성 또는 기존 canonical 문서 갱신
3. 승격 완료 후 workbench 원문은 `status: reference` 또는 archived note로 전환
4. 승격 PR에는 rewrite map/audit 결과를 필수 첨부

### GitHub Project tracking fields (for this migration)
- `initiative`: `unified-personal-agent-platform`
- `repo`: `platform-planningops`
- `component`: `docs-topology` | `docs-governance` | `docs-tooling`
- `lifecycle`: `canonical` | `workbench`
- `state`: `Backlog` | `Ready` | `Doing` | `Review` | `Done`
- `blocked_by`: issue/PR link or empty

## SpecFlow Analysis
### User flow overview
1. 에이전트가 루트 진입 문서를 읽고 canonical 문서 집합을 파악한다.
2. 아이디어/리뷰 산출물을 workbench 경로에 생성한다.
3. 계획 문서가 안정화되면 canonical 문서 반영 여부를 판단한다.
4. 문서 검증기(profile)에 따라 canonical/workbench/all 범위를 검사한다.
5. 리뷰어가 링크/경로/audit 증적을 확인하고 완료 처리한다.

### Flow permutations matrix
| Flow | 정상 경로 | 실패 분기 | 기대 방어 |
|---|---|---|---|
| 신규 에이전트 온보딩 | canonical entry만 추적 | workbench 문서를 기준으로 오인 | AGENT-START에 경계 명시 |
| 계획 산출물 작성 | workbench/plans에 생성 | docs/plans(legacy)에 생성 | stale path check + 가이드 |
| 링크 참조 | 상대경로 해석 | 이동 후 broken link | rewrite map + link audit |
| 검증 실행 | profile별 점검 | canonical만 통과, workbench 누락 | `check --profile all` 기준화 |

### Missing elements & gaps
- workbench 문서에 적용할 최소 frontmatter 스키마가 정의되어 있지 않다.
- `uap-docs.sh`의 profile 계약이 부재해 범위 통제가 문서화되지 않았다.
- GitHub Project에서 migration 작업을 어떤 단위(`component`)로 분할할지 규칙이 없다.

### Critical questions requiring clarification
1. **Critical**: workbench frontmatter 최소 필드를 어디까지 강제할지? (`title/type/date/lifecycle/status` 권장)
2. **Important**: legacy 경로를 즉시 제거할지, 1회 릴리즈 동안 호환 alias를 둘지?
3. **Important**: audit artifact를 workbench/audits로 통일할지, 계획 문서와 같은 디렉토리에 둘지?

기본 가정:
- 본 계획은 "즉시 분리 + alias 없음"을 기본값으로 둔다.
- 호환이 필요하면 별도 카드로 제한적으로 추가한다.

## Implementation Plan
### Phase 1: Contract freeze (정의 고정)
Tasks:
- canonical/workbench 용어와 lifecycle 계약을 governance 문서에 고정
- workbench 최소 frontmatter 스키마 정의
- GitHub Project 필드(`initiative`, `repo`, `component`) 정의 문구 반영

Deliverables:
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`

### Phase 2: Physical migration (파일 이동)
Tasks:
- `docs/brainstorms/*` -> `docs/workbench/unified-personal-agent-platform/brainstorms/`
- `docs/plans/*` -> `docs/workbench/unified-personal-agent-platform/plans/`
- 감사/로그/맵 산출물은 `docs/workbench/unified-personal-agent-platform/audits/`로 정리
- `._*` 파일 제거 및 재유입 점검 절차 추가

Deliverables:
- workbench 디렉토리 구조 신설
- migration manifest (`from -> to`)

### Phase 3: Reference rewrite and navigation split
Tasks:
- 전 리포 markdown 링크에서 legacy 경로를 새 경로로 치환
- 루트 README에 `Canonical` vs `Workbench` 섹션 분리
- initiative README Migration Note를 현재 구조와 일치하도록 갱신

Deliverables:
- updated `README.md`
- updated initiative hub docs
- rewrite audit report

### Phase 4: Tooling alignment
Tasks:
- `uap-docs.sh`에 profile 옵션 추가 또는 equivalent script 분리
- canonical/workbench/all 검증 명령을 문서에 명시
- CI에서 최소 `canonical` + 주기적 `all` 검증 전략 정의

Deliverables:
- updated `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`
- updated docs automation instructions

### Phase 5: Verification and rollout
Tasks:
- `check`/`sync` 실행 및 결과 보관
- stale path 검색(`docs/brainstorms`, `docs/plans`)에서 canonical/automation scope 결과 0건 확인
- 작업 완료 후 canonical/workbench 토폴로지 스냅샷 기록

Deliverables:
- `docs/workbench/unified-personal-agent-platform/audits/uap-workbench-separation-audit.txt`
- `docs/workbench/unified-personal-agent-platform/audits/uap-workbench-migration-map.tsv`
- `docs/workbench/unified-personal-agent-platform/audits/uap-workbench-rollout-note.md`

## Acceptance Criteria
### Functional
- [x] workbench 산출물이 `docs/workbench/unified-personal-agent-platform/*`에만 위치한다.
- [x] canonical 문서는 `docs/initiatives/unified-personal-agent-platform/*`에서만 운영된다.
- [x] README/AGENT-START/Document Map에서 canonical/workbench 경계가 명시된다.
- [x] GitHub Project 카드에 `initiative/repo/component` 필드 기준이 반영된다.

### Non-functional
- [x] `uap-docs.sh` 검증이 profile 기준으로 동작한다.
- [x] legacy 경로 참조가 canonical 문서와 자동화 명령에서 0건이다.
- [x] migration map + audit log가 남아 재추적 가능하다.

## Success Metrics
- 신규 에이전트의 canonical 진입 경로 선택 오류: 0건
- 문서 위치 혼동 관련 리뷰 코멘트: 0건 (다음 2회 리뷰)
- stale path 재유입(`docs/brainstorms`, `docs/plans`): 0건
- workbench 문서 생성 시 경로 오류율: 0건

## Dependencies & Risks
### Dependencies
- governance 문서 선행 확정
- migration 시점의 링크 rewrite 일괄 적용
- 검증 스크립트 profile 설계 합의

### Risks
- 대량 이동 중 링크 누락으로 문서 탐색 실패
- canonical 문서가 workbench 문서를 잘못 SoT로 참조
- GitHub Project 필드가 실제 운영에서 과도하거나 부족할 가능성

### Mitigations
- migration map 기반으로 이동 후 링크 audit 자동 점검
- canonical -> workbench 링크를 lint 경고로 승격
- Project 필드는 1회 데모 운영 후 최소 집합으로 재조정

## References & Research
### Internal references
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-28-doc-topology-permanence-separation-brainstorm.md`
- `README.md`
- `docs/initiatives/unified-personal-agent-platform/README.md`
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
- `docs/initiatives/unified-personal-agent-platform/90-navigation/uap-document-map.navigation.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/uap-doc-governance.meta.md`
- `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`

### External references
- 없음 (내부 문서 구조 정합성 작업)

## MVP Pseudo Worklist
### docs/workbench/unified-personal-agent-platform/audits/uap-workbench-migration-map.tsv
```text
from_path\tto_path\tstatus
```

### docs/workbench/unified-personal-agent-platform/audits/uap-workbench-separation-audit.txt
```text
# stale path scan
# broken link scan
# profile check outputs
```

### docs/workbench/unified-personal-agent-platform/audits/uap-workbench-rollout-note.md
```markdown
# rollout note
- migration scope
- validation result
- follow-up backlog
```
