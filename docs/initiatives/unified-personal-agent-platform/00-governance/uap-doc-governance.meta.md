---
doc_id: uap-doc-governance
title: UAP Documentation Governance
doc_type: meta
domain: governance
status: active
date: 2026-02-27
updated: 2026-02-28
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-doc-governance
tags:
  - uap
  - docs
  - governance
  - naming
summary: Defines prefix and postfix rules, domain ownership, reference contract, and document change policy.
related_docs:
  - ../README.md
  - ./uap-monday-identity.meta.md
  - ../30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md
  - ../90-navigation/uap-document-map.navigation.md
  - ../2026-02-27-uap-frontmatter-catalog.navigation.md
  - ../../../workbench/unified-personal-agent-platform/README.md
---

# UAP Documentation Governance

## Purpose
문서 산개를 방지하고, 브레인스토밍에서 실행계획으로 이어지는 흐름을 도메인 단위로 고정한다.

## Topology Ownership
- canonical: `docs/initiatives/unified-personal-agent-platform/*`
- workbench: `docs/workbench/unified-personal-agent-platform/*`
- canonical은 운영 기준(source of truth), workbench는 실행 중 산출물 저장소로 운영한다.

## Prefix Rules (Directory)
- `00-governance`: 거버넌스/규칙/공통 정책
- `10-brainstorm`: 공통 브레인스토밍/문제탐색
- `20-architecture`: 공통 아키텍처/경계/계약
- `20-repos`: 레포 단위 문서 버킷
- `30-domains`: 레포 독립 도메인 버킷
- `30-execution-plan`: 공통 실행계획/로드맵
- `40-quality`: 공통 품질/리뷰/게이트 추적
- `90-navigation`: 네비게이션/인덱스/맵

## Postfix Rules (File)
- `.brainstorm.md`: 의도, 방향, 의사결정
- `.simulation.md`: 사고 실험, 실패 시나리오
- `.strategy.md`: 옵션 비교, 권장 경로
- `.architecture.md`: 경계, 도메인, 계약
- `.execution-plan.md`: 단계/게이트/검증 계획
- `.quality.md`: 이슈 및 품질 매트릭스
- `.navigation.md`: 문서 연결 지도
- `.meta.md`: 문서 규칙/운영 정책

예외 엔트리포인트:
- `README.md`: 루트 허브 문서
- `AGENT-START.md`: 신규 에이전트 1페이지 온보딩
- `AGENT.md`: 공통 행동 원칙

Core 7 canonical filename 예외(무날짜 고정):
- `00-governance/uap-monday-identity.meta.md`
- `90-navigation/uap-document-map.navigation.md`
- `30-execution-plan/uap-github-planningops-sync.execution-plan.md`
- `00-governance/uap-doc-governance.meta.md`
- `40-quality/uap-planningops-tradeoff-decision-framework.quality.md`

## Domain Ownership
- `10-brainstorm`: 제품/문제정의 도메인
- `20-architecture`: 계약/경계 도메인
- `30-execution-plan`: 구현/검증 도메인
- `40-quality`: 리스크/게이트 도메인
- `20-repos/*/10-discovery`: discovery 도메인
- `20-repos/*/20-architecture`: architecture 도메인
- `20-repos/*/30-execution-plan`: planning 도메인
- `20-repos/*/40-quality`: quality 도메인
- `30-domains/planningops`: planning 도메인
- `30-domains/contract-evolution`: architecture 도메인
- `30-domains/observability`: quality 도메인
- `**/README.md`: navigation 도메인
- 루트 `AGENT.md`: governance 도메인
- 루트 `AGENT-START.md`: navigation 도메인
- `*.navigation.md`: navigation 도메인

## Frontmatter Contract
- 필수 키: `doc_id`, `title`, `doc_type`, `domain`, `status`, `date`, `updated`, `initiative`, `summary`
- 권장 키: `tags`, `related_docs`, `topic`
- `doc_id`는 initiative 내 유일해야 한다.
- `doc_type`은 postfix와 일치해야 한다. (`.brainstorm.md` -> `doc_type: brainstorm`)
- 예외: 루트 `README.md`는 `doc_type: hub`를 허용한다.
- `status` 의미:
  - `active`: 현재 기준 문서
  - `reference`: 배경/맥락 참조 문서(직접 실행 기준 아님)
  - `deprecated`: 대체 문서가 존재하며 직접 참조를 중단한 문서
- `related_docs`는 상대경로를 사용한다.
- `domain↔directory` 매핑이 없는 경로에 문서를 추가하면 검증 실패로 처리한다(허용 디렉토리만 운영).

### Workbench Frontmatter (Minimal)
- 필수 키: `title`, `type`, `date`, `initiative`, `lifecycle`, `status`, `summary`
- `lifecycle`는 `workbench`로 고정한다.
- `status` 허용값: `active`, `reference`, `deprecated`
- workbench 문서는 `doc_id/domain/doc_type`를 강제하지 않는다.

## Lifecycle Contract
- canonical 문서는 `lifecycle: canonical`을 권장한다.
- workbench 문서는 `lifecycle: workbench`를 필수로 사용한다.
- canonical 문서는 workbench 문서를 규범(SoT)으로 직접 인용하지 않는다.
- workbench -> canonical 승격 시 canonical 문서를 갱신하고 workbench 문서는 `reference`로 전환한다.

## Path Root Contract
- 문서 본문 링크/`related_docs`는 문서 파일 기준 상대경로(`./`, `../`)를 사용한다.
- CLI/CI 명령에서 파일 인수는 repo 루트 기준 상대경로(`docs/initiatives/unified-personal-agent-platform/...`)를 사용한다.
- workbench CLI 인수는 repo 루트 기준 상대경로(`docs/workbench/unified-personal-agent-platform/...`)를 사용한다.

## GitHub Project Field Contract
- 필수 필드:
  - `initiative`: `unified-personal-agent-platform`
  - `repo`: `platform-planningops`
  - `component`: `docs-topology` | `docs-governance` | `docs-tooling`
- 권장 필드:
  - `lifecycle`: `canonical` | `workbench`
  - `state`: `Backlog` | `Ready` | `Doing` | `Review` | `Done`
- 목적: planningops 카드 분류를 고정해 에이전트 실행 시 판단 분기를 줄인다.

## Automation
- 스크립트: `docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh`
- 초안 문서 생성: `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh <target-dir> <subject-slug> <postfix> <domain> "<title>" "<summary>" [status]`
- `check --profile canonical`: canonical frontmatter/링크 규칙 검증
- `check --profile workbench`: workbench 최소 frontmatter/링크 규칙 검증
- `check --profile all`: canonical + workbench 검증
- `catalog`: frontmatter 기반 카탈로그 문서 생성
- `sync`: `catalog -> check --profile canonical` 순서로 동기화

## Reference Contract
- 참조는 상대 경로 링크를 우선한다.
- `execution-plan`에서 아키텍처를 인용할 때는 `20-architecture` 파일 링크를 명시한다.
- `quality` 문서는 상세 내용을 복제하지 않고 링크 허브 역할만 수행한다.
- 동일 주제를 중복 문서화하지 않는다.

## Change Policy
- 경계/상태/계약 변경: ADR 또는 동등한 결정 기록 필수
- 파일명 변경: 루트 `README.md`와 `90-navigation` 맵 동시 갱신
- 신규 문서 추가: postfix 규칙을 따르지 않으면 병합 금지
- org/repo/agent naming 변경: `uap-monday-identity.meta.md`를 canonical source로 먼저 갱신
- 구조 마이그레이션은 `2026-02-27-uap-doc-structure-migration.execution-plan.md`의 phase 순서를 따른다
