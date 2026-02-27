---
doc_id: uap-document-map
title: UAP Document Relationship Map
doc_type: navigation
domain: navigation
status: active
date: 2026-02-27
updated: 2026-02-27
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
  - ../00-governance/2026-02-27-uap-doc-governance.meta.md
  - ../00-governance/2026-02-27-uap-monday-identity.meta.md
  - ../20-repos/README.md
  - ../30-domains/README.md
  - ../20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ../30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md
  - ../30-execution-plan/2026-02-27-uap-github-planningops-sync.execution-plan.md
  - ../30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md
  - ../40-quality/2026-02-27-uap-planningops-tradeoff-decision-framework.quality.md
  - ../2026-02-27-uap-frontmatter-catalog.navigation.md
---

# Document Relationship Map

## Root
- [README](../README.md)
- 역할: 루트 인덱스, 네이밍 규칙, 참조 그래프 진입점

- [AGENT-START](../AGENT-START.md)
- 역할: 문맥 없는 신규 에이전트용 1페이지 온보딩 엔트리포인트

- [AGENT Principles](../AGENT.md)
- 역할: 에이전트 공통 행동 원칙/게이트 네임스페이스/변경 규칙 기준 문서

- [M.O.N.D.A.Y. Identity](../00-governance/2026-02-27-uap-monday-identity.meta.md)
- 역할: agent/org/repo 식별자의 canonical source

- [Frontmatter Catalog](../2026-02-27-uap-frontmatter-catalog.navigation.md)
- 역할: 전체 문서를 frontmatter 기준으로 빠르게 찾는 자동 생성 카탈로그

## Governance Layer (`00-governance`)
- [Doc Governance](../00-governance/2026-02-27-uap-doc-governance.meta.md)
- 역할: prefix/postfix 규칙, 도메인 소유권, 변경 정책

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

- [GitHub PlanningOps Sync Plan](../30-execution-plan/2026-02-27-uap-github-planningops-sync.execution-plan.md)
- 역할: plan-repo source of truth 기반 Issues/Milestones/Projects 동기화 실행 계획

- [Lifecycle Scenario Playbook](../30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md)
- 역할: 계획 이후 수정/삭제/완료/재개/분할/병합 처리 표준 시나리오와 운영 절차

- [Doc Structure Migration Plan](../30-execution-plan/2026-02-27-uap-doc-structure-migration.execution-plan.md)
- 역할: repo-first + domain-second 구조로의 단계 전환 절차와 참조 갱신 계약

## Quality Layer (`40-quality`)
- [Issue Closure Matrix](../20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md)
- 역할: 리뷰 이슈와 gate/문서 타깃 연결

- [Trade-off Decision Framework](../40-quality/2026-02-27-uap-planningops-tradeoff-decision-framework.quality.md)
- 역할: 판단 유예 항목의 점수화 기준, 분기 영향, 재평가 트리거 제공

## Domain Cross-Cut Layer (`30-domains`)
- [Domains Hub](../30-domains/README.md)
- 역할: 레포 독립 도메인 문서 인덱스

- [PlanningOps Domain Hub](../30-domains/planningops/README.md)
- 역할: 계획-트래킹 동기화 cross-cut 정책 축적

- [Contract Evolution Domain Hub](../30-domains/contract-evolution/README.md)
- 역할: 계약 버전/호환성 정책 축적

- [Observability Domain Hub](../30-domains/observability/README.md)
- 역할: trace/log/timeline cross-cut 정책 축적

## Reading Order
1. governance
2. repo buckets hub
3. monday repo hub
4. core brainstorm
5. planningops sync brainstorm
6. failure simulation
7. requirements
8. contract boundaries
9. strategy options
10. foundation execution plan
11. planningops sync execution plan
12. lifecycle scenario playbook
13. doc structure migration plan
14. trade-off decision framework
15. quality matrix
16. domain hubs
17. frontmatter catalog

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
