---
doc_id: uap-doc-hub
title: Unified Personal Agent Platform Docs Hub
doc_type: hub
domain: navigation
status: active
date: 2026-02-27
updated: 2026-03-11
initiative: unified-personal-agent-platform
tags:
  - uap
  - docs
  - index
summary: Root entry point for UAP documentation structure, naming rules, and reading order.
related_docs:
  - ./AGENT-START.md
  - ./AGENT.md
  - ./00-governance/uap-doc-governance.meta.md
  - ./00-governance/uap-monday-identity.meta.md
  - ./20-repos/README.md
  - ./30-domains/README.md
  - ./30-execution-plan/2026-02-28-uap-topology-priority-expansion.execution-plan.md
  - ./30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md
  - ./30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md
  - ./40-quality/uap-automation-operations-summary.quality.md
  - ./90-navigation/uap-document-map.navigation.md
  - ./2026-02-27-uap-frontmatter-catalog.navigation.md
  - ../../workbench/unified-personal-agent-platform/README.md
---

# Unified Personal Agent Platform Docs Hub

이 디렉토리는 개인 에이전트 플랫폼의 canonical 문서를 관리한다.
실행 중 생성되는 비영속 산출물은 `docs/workbench/unified-personal-agent-platform`에서 관리한다.

## Directory Layout
- `00-governance`: 문서 운영 규칙, 네이밍 규칙, 변경 정책
- `10-brainstorm`: 공통/크로스컷 브레인스토밍 문서
- `20-architecture`: 공통/크로스컷 아키텍처 문서
- `20-repos`: 레포 단위 문서 버킷
- `30-domains`: 레포 독립 크로스컷 도메인 버킷
- `30-execution-plan`: 공통/크로스컷 실행 계획
- `40-quality`: 공통/크로스컷 품질 추적 문서
- `90-navigation`: 문서 맵, 읽기 순서, 참조 그래프

## Workbench
- [Workbench Hub](../../workbench/unified-personal-agent-platform/README.md)
- 용도: 브레인스토밍, 실행 계획 초안, 리뷰 로그, 감사 산출물
- 규칙: workbench 문서는 canonical SoT로 승격되기 전까지 운영 산출물로 취급한다.

## Naming Convention
- 파일 패턴: `YYYY-MM-DD-uap-<subject>.<postfix>.md`
- Core 7 canonical 문서는 날짜 없이 고정 파일명을 사용한다.
- `<postfix>`: `brainstorm`, `simulation`, `strategy`, `architecture`, `execution-plan`, `quality`, `navigation`, `meta`
- 디렉토리 prefix(`00`, `10`, `20`...)는 읽기 우선순위와 안정성 순서를 의미한다.

## Recommended Reading Flow
0. [Agent Start Guide](AGENT-START.md)
1. [Core Brainstorm](20-repos/monday/10-discovery/2026-02-27-uap-core.brainstorm.md)
2. [PlanningOps Sync Brainstorm](10-brainstorm/2026-02-27-uap-github-planningops-sync.brainstorm.md)
3. [Failure Simulation](20-repos/monday/10-discovery/2026-02-27-uap-failure-simulation.simulation.md)
4. [Contract-First Requirements](20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md)
5. [Contract Boundaries](20-architecture/2026-02-27-uap-contract-boundaries.architecture.md)
6. [Foundation Execution Plan](20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md)
7. [GitHub PlanningOps Sync Plan](30-execution-plan/uap-github-planningops-sync.execution-plan.md)
8. [Topology Priority Expansion Plan](30-execution-plan/2026-02-28-uap-topology-priority-expansion.execution-plan.md)
9. [Module Refactor Hygiene Loop Plan](30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md)
10. [Lifecycle Scenario Playbook](30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md)
11. [Doc Structure Migration Plan](30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md)
12. [Trade-off Decision Framework](40-quality/uap-planningops-tradeoff-decision-framework.quality.md)
13. [Automation Operations Summary](40-quality/uap-automation-operations-summary.quality.md)
14. [Issue Closure Matrix](20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md)
15. [Document Map](90-navigation/uap-document-map.navigation.md)
16. [Frontmatter Catalog](2026-02-27-uap-frontmatter-catalog.navigation.md)

## New Agent Fast Path
- 1페이지 시작점: [AGENT-START](AGENT-START.md)
- 근본 원칙/행동 규약: [AGENT Principles](AGENT.md)

## Project Identity
- Canonical identity source: [M.O.N.D.A.Y. Identity](00-governance/uap-monday-identity.meta.md)
- GitHub coordinate: `rather-not-work-on/monday`
- Agent-specific naming: `monday*`
- Shared platform naming: `platform-*`

## Gate Namespace Guide
- `Gate A~G`: Foundation 게이트 (`20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md` 기준)
- `Sync Gate A~F`: PlanningOps Sync 게이트 (`30-execution-plan/uap-github-planningops-sync.execution-plan.md` 기준)
- 품질 매트릭스의 기본 게이트 참조는 Foundation(`Gate A~G`)를 기준으로 해석한다.

## Cross-Directory Reference Policy
- `10-brainstorm` -> `20-architecture`, `30-execution-plan` 참조 허용
- `20-architecture` -> `10-brainstorm`, `40-quality` 참조 허용
- `30-execution-plan` -> `20-architecture`, `40-quality` 참조 허용
- `40-quality` -> 전체 참조 허용(추적 허브)
- `90-navigation` -> 전체 참조 허용(색인 허브)

## Frontmatter Quick Lookup
- 전체 문서 메타 확인:
  - `rg -n "^(doc_id|title|doc_type|domain|status|summary):" . -g "*.md"`
- 특정 도메인 문서 찾기(예: architecture):
  - `rg -n "^domain: architecture$|^doc_id:|^title:" . -g "*.md"`
- 상태별 문서 찾기(예: active):
  - `rg -n "^status: active$|^doc_id:|^title:" . -g "*.md"`

## Docs Automation
명령 예시는 repo 루트(`platform-planningops/`)에서 실행한다.

- 새 문서 생성(초안):
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh <target-dir> <subject-slug> <postfix> <domain> "<title>" "<summary>" [status]`
- 검증:
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile canonical`
- 검증(all):
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
- 카탈로그 생성:
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh catalog`
- 전체 동기화(카탈로그 갱신 + 검증):
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh sync`
- PR 검증:
  - `.github/workflows/uap-docs-check.yml`에서 문서 체크 + 카탈로그 동기화 검증 실행

## Reference Graph
```mermaid
graph TD
  G["00-governance"] --> B["10-brainstorm"]
  B --> A["20-architecture"]
  A --> P["30-execution-plan"]
  P --> Q["40-quality"]
  B --> N["90-navigation"]
  A --> N
  P --> N
  Q --> N
```

## Migration Note
- 기존 루트 브레인스토밍/계획 디렉토리 문서는 `docs/workbench/unified-personal-agent-platform/*`로 이동되었다.
- canonical 문서는 반드시 이 루트(`docs/initiatives/unified-personal-agent-platform`) 하위에서 생성한다.
