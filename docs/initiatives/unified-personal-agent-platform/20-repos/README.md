---
doc_id: uap-repos-hub
title: UAP Repo-Scoped Docs Hub
doc_type: hub
domain: navigation
status: active
date: 2026-02-27
updated: 2026-03-05
initiative: unified-personal-agent-platform
tags:
  - uap
  - repos
  - navigation
summary: Index for repo-scoped documentation buckets and their ownership boundaries.
related_docs:
  - ../README.md
  - ./monday/README.md
  - ./platform-contracts/README.md
  - ./platform-provider-gateway/README.md
  - ./platform-observability-gateway/README.md
---

# Repo-Scoped Docs

이 디렉토리는 레포 단위로 문서를 분리해 관리한다.

## Repo Buckets
- [monday](./monday/README.md): 메인 에이전트 관련 문서
- [platform-contracts](./platform-contracts/README.md): 공용 계약 저장소 관련 문서
- [platform-provider-gateway](./platform-provider-gateway/README.md): LLM/provider gateway 관련 문서
- [platform-observability-gateway](./platform-observability-gateway/README.md): o11y gateway 관련 문서

## Ownership Matrix
| Repo | Primary Responsibility | Upstream Input (from planningops) | Downstream Evidence (to planningops) |
|---|---|---|---|
| `platform-planningops` | control tower, plan/contract/queue orchestration | canonical docs + policy decisions | issue/project updates, gate verdict, audit artifacts |
| `monday` | execution runtime, scheduler, worker lifecycle | execution contracts, issue metadata, loop profile | runtime artifacts, verification reports, transition logs |
| `platform-contracts` | shared interface/schema versioning | contract change requests, compatibility requirements | schema version/tag, compatibility report, consumer test evidence |
| `platform-provider-gateway` | provider invocation runtime | provider policy contract, budget/security constraints | provider usage/cost/latency evidence, failover verdict |
| `platform-observability-gateway` | telemetry ingestion and replay boundary | observability contract, retention/redaction policy | trace/log delivery evidence, replay/backfill verification |

## Collaboration Rules
- planningops는 실행 구현을 직접 포함하지 않고, 계약/게이트/우선순위만 소유한다.
- 실행 레포는 계약을 구현하고 증빙 아티팩트를 planningops 이슈/프로젝트로 되돌린다.
- 레포 간 조정 기준은 `target_repo`, `component`, `workflow_state`, `loop_profile` 필드 계약으로 고정한다.
