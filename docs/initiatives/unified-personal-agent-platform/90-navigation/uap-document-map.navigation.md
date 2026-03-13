---
doc_id: uap-document-map
title: UAP Document Relationship Map
doc_type: navigation
domain: navigation
status: active
date: 2026-02-27
updated: 2026-03-13
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-document-map
tags:
  - uap
  - navigation
  - map
  - references
summary: Provides layer-by-layer document map, reading order, and pruning rules for the initiative.
related_docs:
  - ../README.md
  - ../AGENT-START.md
  - ../AGENT.md
  - ../00-governance/uap-doc-governance.meta.md
  - ../00-governance/uap-monday-identity.meta.md
  - ../20-repos/README.md
  - ../30-domains/README.md
  - ../20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ../30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md
  - ../30-execution-plan/2026-02-28-uap-topology-priority-expansion.execution-plan.md
  - ../30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md
  - ../30-execution-plan/uap-github-planningops-sync.execution-plan.md
  - ../30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md
  - ../40-quality/uap-planningops-tradeoff-decision-framework.quality.md
  - ../40-quality/uap-automation-operations-summary.quality.md
  - ../2026-02-27-uap-frontmatter-catalog.navigation.md
  - ../../../workbench/unified-personal-agent-platform/README.md
---

# Document Relationship Map

## Path Root Rule
- 문서 본문 링크는 문서 파일 기준 상대경로(`./`, `../`)를 사용한다.
- 셸/CI 명령은 repo 루트 기준 상대경로(`docs/initiatives/unified-personal-agent-platform/...`)를 사용한다.

## Lifecycle Boundary
- canonical: `docs/initiatives/unified-personal-agent-platform/*`
- workbench: `docs/workbench/unified-personal-agent-platform/*`
- canonical 문서는 workbench 문서를 규범(SoT)으로 참조하지 않는다.

## Core 7 Topology
### Entry Core
- [AGENT-START](../AGENT-START.md)
- [AGENT Principles](../AGENT.md)
- [M.O.N.D.A.Y. Identity](../00-governance/uap-monday-identity.meta.md)
- [GitHub PlanningOps Sync Plan](../30-execution-plan/uap-github-planningops-sync.execution-plan.md)

Note: 이 문서(`uap-document-map.navigation.md`) 자체가 Entry Core 구성요소이며, 목록에서는 self-reference를 생략한다.

### Policy Core
- [Doc Governance](../00-governance/uap-doc-governance.meta.md)
- [Trade-off Decision Framework](../40-quality/uap-planningops-tradeoff-decision-framework.quality.md)

## Root
- [README](../README.md)
- 역할: 루트 인덱스, 네이밍 규칙, 참조 그래프 진입점

- [AGENT-START](../AGENT-START.md)
- 역할: 문맥 없는 신규 에이전트용 1페이지 온보딩 엔트리포인트

- [AGENT Principles](../AGENT.md)
- 역할: 에이전트 공통 불변 원칙(invariant) 기준 문서

- [M.O.N.D.A.Y. Identity](../00-governance/uap-monday-identity.meta.md)
- 역할: agent/org/repo 식별자의 canonical source

- [Frontmatter Catalog](../2026-02-27-uap-frontmatter-catalog.navigation.md)
- 역할: 전체 문서를 frontmatter 기준으로 빠르게 찾는 자동 생성 카탈로그

## Governance Layer (`00-governance`)
- [Doc Governance](../00-governance/uap-doc-governance.meta.md)
- 역할: prefix/postfix 규칙, 도메인 소유권, 변경 정책

## Control Plane Runtime Layer (`planningops/`)
- [`planningops/README.md`](../../../../planningops/README.md)
- [`planningops/contracts/README.md`](../../../../planningops/contracts/README.md)
- [`planningops/config/README.md`](../../../../planningops/config/README.md)
- [`planningops/scripts/README.md`](../../../../planningops/scripts/README.md)
- 역할: 실행 계약, active goal pointer, 프로젝트 필드 카탈로그, 자동화 엔트리포인트를 코드/계약 단위로 유지

## Repo-Scoped Layer (`20-repos`)
- [Repo Buckets Hub](../20-repos/README.md)
- 역할: 레포 단위 문서 버킷의 상위 인덱스

- [Monday Repo Hub](../20-repos/monday/README.md)
- 역할: 메인 에이전트 레포 전용 문서 진입점

## Discovery Layer (`10-brainstorm`)
- [Core Brainstorm](../20-repos/monday/10-discovery/2026-02-27-uap-core.brainstorm.md)
- 역할: 방향성, 핵심 결정, 아키텍처 원칙

- [Failure Simulation](../20-repos/monday/10-discovery/2026-02-27-uap-failure-simulation.simulation.md)
- 역할: 실패 시나리오, 반박 루프, gate 사고 실험

- [Approach Options](../20-repos/monday/10-discovery/2026-02-27-uap-approach-options.strategy.md)
- 역할: 구현 경로 옵션(Alpha/Beta/Gamma) 비교

- [GitHub PlanningOps Sync Brainstorm](../10-brainstorm/2026-02-27-uap-github-planningops-sync.brainstorm.md)
- 역할: 계획 전용 레포 + GitHub tracker 자동 동기화 방향 정의

## Architecture Layer (`20-architecture`)
- [Contract-First Requirements](../20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md)
- 역할: DDD-lite 경계, 요구사항 우선순위, 토폴로지

- [Contract Boundaries](../20-architecture/2026-02-27-uap-contract-boundaries.architecture.md)
- 역할: C1~C5 계약, 상태/결과 매핑, 불변성

## Delivery Layer (`30-execution-plan`)
- [Foundation Execution Plan](../20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md)
- 역할: 단계별 구현/검증 계획, gate evidence, working defaults

- [GitHub PlanningOps Sync Plan](../30-execution-plan/uap-github-planningops-sync.execution-plan.md)
- 역할: plan-repo source of truth 기반 Issues/Milestones/Projects 동기화 실행 계획

- [Topology Priority Expansion Plan](../30-execution-plan/2026-02-28-uap-topology-priority-expansion.execution-plan.md)
- 역할: 현재 상태 스냅샷과 토폴로지 기반 우선순위, cross-repo 확장 큐를 정렬하는 실행 계획

- [Module Refactor Hygiene Loop Plan](../30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md)
- 역할: 모듈 단위 리팩토링을 외부 의존성 -> 내부 의존성 순서로 수행하고, 중간 checkpoint로 문맥 정리를 강제하는 운영 계획

- [Runtime Interface Wave 4 Plan](../30-execution-plan/uap-runtime-interface-wave4.execution-plan.md)
- 역할: scaffold/build baseline 다음 단계로 typed runtime port와 interface ownership을 고정하는 크로스레포 실행 계획

- [monday Runtime Interface Wiring Pack](../20-repos/monday/30-execution-plan/runtime-interface-wiring-pack.md)
- 역할: orchestrator, executor, kernel, adapter 간 typed port와 import direction을 고정

- [Provider Gateway Runtime Interface Wiring Pack](../20-repos/platform-provider-gateway/30-execution-plan/runtime-interface-wiring-pack.md)
- 역할: provider runtime, routing, driver 경계를 public port와 private driver로 분리

- [Observability Gateway Runtime Interface Wiring Pack](../20-repos/platform-observability-gateway/30-execution-plan/runtime-interface-wiring-pack.md)
- 역할: ingest, replay, buffer, sink 경계를 typed envelope와 port로 고정

- [Runtime Interface Contract Gap Matrix](../20-repos/platform-contracts/30-execution-plan/runtime-interface-contract-gap-matrix.md)
- 역할: wave 4가 새 shared schema를 정말 요구하는지 여부를 증거 기반으로 판정

- [Lifecycle Scenario Playbook](../30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md)
- 역할: 계획 이후 수정/삭제/완료/재개/분할/병합 처리 표준 시나리오와 운영 절차

- [Doc Structure Migration Plan](../30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md)
- 역할: repo-first + domain-second 구조로의 단계 전환 절차와 참조 갱신 계약

## Quality Layer (`40-quality`)
- [Issue Closure Matrix](../20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md)
- 역할: 리뷰 이슈와 gate/문서 타깃 연결

- [Trade-off Decision Framework](../40-quality/uap-planningops-tradeoff-decision-framework.quality.md)
- 역할: 판단 유예 항목의 점수화 기준, 분기 영향, 재평가 트리거 제공

- [Automation Operations Summary](../40-quality/uap-automation-operations-summary.quality.md)
- 역할: 실행 자동화와 관찰 자동화의 역할 경계, 로컬 전용 실패 원인, 현재 운영 규칙을 고정

## Domain Cross-Cut Layer (`30-domains`)
- [Domains Hub](../30-domains/README.md)
- 역할: 레포 독립 도메인 문서 인덱스

- [PlanningOps Domain Hub](../30-domains/planningops/README.md)
- 역할: 계획-트래킹 동기화 cross-cut 정책 축적

- [Contract Evolution Domain Hub](../30-domains/contract-evolution/README.md)
- 역할: 계약 버전/호환성 정책 축적

- [Observability Domain Hub](../30-domains/observability/README.md)
- 역할: trace/log/timeline cross-cut 정책 축적

## Workbench Layer (`docs/workbench/...`)
- [Workbench Hub](../../../workbench/unified-personal-agent-platform/README.md)
- [Latest Workbench Plan: Control Tower Ontology/Memory/Federation Migration](../../../workbench/unified-personal-agent-platform/plans/2026-03-05-plan-control-tower-ontology-memory-and-federation-migration-plan.md)
- [Latest Workbench Plan: Meta Backlog Atomic Decomposition](../../../workbench/unified-personal-agent-platform/plans/2026-03-05-plan-meta-backlog-atomic-decomposition-and-federated-delivery-plan.md)
- [Topology Brainstorm](../../../workbench/unified-personal-agent-platform/brainstorms/2026-02-28-doc-topology-permanence-separation-brainstorm.md)
- 역할: 비정기 실행 산출물(초안, 리뷰, 감사 로그) 운영

## Reading Order
1. entry core
2. policy core
3. governance
4. control plane runtime layer
5. repo buckets hub
6. monday repo hub
7. core brainstorm
8. planningops sync brainstorm
9. failure simulation
10. requirements
11. contract boundaries
12. strategy options
13. foundation execution plan
14. planningops sync execution plan
15. topology priority expansion plan
16. lifecycle scenario playbook
17. module refactor hygiene loop plan
18. doc structure migration plan
19. trade-off decision framework
20. quality matrix
21. domain hubs
22. frontmatter catalog
23. workbench hub (when needed)

## Handoff Into Planning
- 계획 문서는 discovery + architecture + quality 문서를 입력으로 사용한다.
- 계획 문서에서는 아래를 확정해야 한다:
  - 각 계약의 필수/선택 필드 최종본
  - 단계별 구현 순서와 게이트 통과 조건
  - 테스트 전략(TDD 범위, contract/integration/e2e 비율)

## Pruning Rules (Avoid Bloat)
- 동일 결정을 중복 설명하는 문서는 제거하거나 링크로 대체
- 구현 세부가 섞인 브레인스토밍 문장은 계획 문서로 이동
- 계약 변경이 없는데 문서만 늘어나는 경우 신규 문서 생성 금지
- 분기된 대안이 기각되면 `rejected`로 표시하고 본문에서 축소
