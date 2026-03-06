---
doc_id: uap-domains-hub
title: UAP Domain Cross-Cut Docs Hub
doc_type: hub
domain: navigation
status: active
date: 2026-02-27
updated: 2026-03-05
initiative: unified-personal-agent-platform
tags:
  - uap
  - domains
  - navigation
summary: Index for cross-cutting domain documentation independent of specific repositories.
related_docs:
  - ../README.md
  - ./planningops/README.md
  - ./contract-evolution/README.md
  - ./observability/README.md
---

# Domain Cross-Cut Docs

레포 독립적으로 유지할 도메인 문서를 관리한다.

## Domain Buckets
- [planningops](./planningops/README.md)
- [contract-evolution](./contract-evolution/README.md)
- [observability](./observability/README.md)

## Domain-to-Repo Projection
- `planningops`: 실행 순서/게이트/프로젝트 필드/운영 정책을 정의하고 control-plane 규칙으로 투영
- `contract-evolution`: C1~C* 버전/호환성 정책을 정리하고 `platform-contracts` 구현 기준으로 투영
- `observability`: trace/log/timeline 품질 규칙을 정리하고 `platform-observability-gateway` 및 monday 검증 기준으로 투영

## Usage Rule
- 레포 특화 구현 절차는 각 repo bucket 문서에서 관리한다.
- 여러 레포에 공통으로 적용되는 규칙만 domain bucket에 유지한다.
- 같은 내용을 repo bucket과 domain bucket에 중복 작성하지 않고 링크로 연결한다.
