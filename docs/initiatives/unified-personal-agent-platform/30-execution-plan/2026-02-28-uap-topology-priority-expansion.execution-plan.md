---
doc_id: uap-topology-priority-expansion-plan
title: feat: UAP Topology-Priority Expansion Plan
doc_type: execution-plan
domain: planning
status: active
date: 2026-02-28
updated: 2026-02-28
initiative: unified-personal-agent-platform
tags:
  - uap
  - topology
  - priority
  - contracts
  - infrastructure
  - kanban
summary: Topology-first priority plan that extends the current planningops MVP toward contracts/provider/o11y/runtime repositories with Kanban execution order.
related_docs:
  - ./uap-github-planningops-sync.execution-plan.md
  - ../20-repos/README.md
  - ../20-repos/platform-contracts/README.md
  - ../20-repos/platform-provider-gateway/README.md
  - ../20-repos/platform-observability-gateway/README.md
  - ../30-domains/planningops/README.md
  - ../30-domains/contract-evolution/README.md
  - ../30-domains/observability/README.md
  - ../40-quality/uap-planningops-tradeoff-decision-framework.quality.md
---

# feat: UAP Topology-Priority Expansion Plan

## Objective
`platform-planningops`에서 검증한 Ralph Loop + PlanningOps MVP를 기반으로, 다음 구현 단계(계약/인프라/관측/실행)를 토폴로지 중심으로 정렬해 불확실성과 재작업을 줄인다.

## Current State Snapshot (`2026-02-28`)
- `platform-planningops`:
  - PlanningOps MVP 이슈 `#2~#13` 전부 `Done` 상태.
  - `planningops/`에 C1~C5 schema, dry-run parser, local harness, verifier, issue loop runner, CI chain(`validate-contracts -> dry-run`) 구축 완료.
- GitHub Project:
  - org project `rather-not-work-on/projects/2` 사용 중.
  - 필드 스키마(`Status`, `execution_order`, `plan_lane`, `component`, `initiative`, `target_repo`) 및 데모 검증 완료.
- 레포 토폴로지:
  - 존재: `platform-planningops`, `monday`, `platform-contracts`, `platform-provider-gateway`, `platform-observability-gateway`.
  - 신규 3개 레포는 `public` 정책으로 생성 완료.

## Decision Snapshot (Locked, `2026-02-28`)
1. 레포 생성 정책:
   - `platform-contracts`, `platform-provider-gateway`, `platform-observability-gateway` 생성 + public 운영.
2. 네이밍 고정:
   - 외부 계약 용어 `Executor`, 내부 구현 용어 `Worker`.
3. LiteLLM/provider 정책:
   - 작업별(task key별) provider/runtime override 허용.
4. 운영 환경:
   - LiteLLM/LangFuse/NanoClaw는 local-first.
   - 일부 워크로드는 Oracle Cloud profile로 점진 이행 가능해야 하며, 이행은 profile 전환으로 처리.

## Topology Contract (Execution Surfaces)
### Control plane (already active)
- `platform-planningops`: canonical 문서, 계획 검증, 프로젝트 동기화 제어면.

### Data/contract plane (next)
- `platform-contracts`: C1~C8 schema/compatibility/contract evolution의 단일 기준면.

### Infra plane (next)
- `platform-provider-gateway`: LiteLLM 라우팅, provider fallback/retry, invocation contract(C4) 집행.
- `platform-observability-gateway`: LangFuse + trace pipeline, observability contract(C5) 집행.

### Runtime plane (incremental)
- `monday`: executor/orchestrator/scheduler 실동작면.

## Priority Model (Topology-First)
우선순위는 "의존성 선행 + 불확실성 축소 + 계약 고정" 순서로 고정한다.

1. `P0 Topology Bootstrap`: 미생성 레포와 운영 경계를 먼저 고정
2. `P1 Contracts Hardening`: C1~C8 계약 저장소 분리와 버전 정책 확정
3. `P2 Provider Infra`: LiteLLM baseline과 C4 집행 경로 확보
4. `P3 Observability Infra`: LangFuse/trace 체인과 C5 집행 경로 확보
5. `P4 Runtime Integration`: `monday`에 executor/worker 명명 규칙 + harness 통합
6. `P5 Scheduler + Autonomy`: 비정기 loop queue/scheduler와 재계획 트리거 자동화
7. `P6 Multi-Repo Sync Expansion`: PlanningOps를 다중 레포 대상으로 확장

## Kanban Execution Policy
### States
`backlog -> ready-contract -> in-progress -> review-gate -> ready-implementation -> done`

### Pull rule
- agent는 `ready-*` 카드만 pull.
- prerequisite 불충족 카드는 `blocked`로 강등 후 원인 코드(`contract|permission|context|runtime`) 기록.

### WIP limits
- Contracts lane: 2
- Infra lane(provider+o11y): 2
- Runtime lane: 2
- PlanningOps lane: 2
- Ops lane: 1

## Dependency-Ordered Work Queue (Now)
| Execution Order | Priority | Component | Target Repo | Work Item | Depends On |
|---|---|---|---|---|---|
| 110 | P0 | planningops | rather-not-work-on/platform-planningops | Multi-repo topology bootstrap ADR + repo creation checklist | - |
| 120 | P0 | planningops | rather-not-work-on/platform-planningops | GitHub Project field schema v2 (`component/repo/initiative` guard) | 110 |
| 130 | P1 | contracts | rather-not-work-on/platform-contracts | `platform-contracts` bootstrap and C1~C8 seed schema migration | 110 |
| 140 | P1 | contracts | rather-not-work-on/platform-contracts | compatibility CI and semver policy (`major/minor/patch`) | 130 |
| 150 | P2 | provider-gateway | rather-not-work-on/platform-provider-gateway | LiteLLM gateway skeleton + C4 adapter contract | 130 |
| 160 | P3 | observability-gateway | rather-not-work-on/platform-observability-gateway | LangFuse trace sink + C5 ingest contract | 130 |
| 170 | P4 | runtime | rather-not-work-on/monday | Executor/worker naming ADR + harness integration contract | 150, 160 |
| 180 | P5 | orchestrator | rather-not-work-on/monday | task scheduler(queue) baseline + idempotent dequeue | 170 |
| 190 | P6 | planningops | rather-not-work-on/platform-planningops | multi-repo parser/sync expansion (`target_repo` fan-out) | 140, 150, 160 |
| 200 | P6 | planningops | rather-not-work-on/platform-planningops | end-to-end simulation (2+ repos) + gate evidence bundle | 190 |

## Checkpoints (Absolute Dates)
- Checkpoint T0 (`2026-03-03`): P0 완료, 레포 생성/소유권/브랜치 보호 기준 확정
- Checkpoint T1 (`2026-03-10`): P1 완료, `platform-contracts` C1~C8 + compatibility CI 통과
- Checkpoint T2 (`2026-03-17`): P2/P3 완료, LiteLLM/LangFuse baseline trace 확인
- Checkpoint T3 (`2026-03-24`): P4/P5 완료, `monday`에서 loop->scheduler 최소 동작
- Checkpoint T4 (`2026-03-31`): P6 완료, multi-repo sync dry-run/apply/reconcile 증빙 확보

## Replanning Triggers
- `blocked` 24시간 초과: 하위 작업 분해 + owner 재지정
- contract drift 감지: 관련 카드 전부 `ready-contract`로 롤백
- 동일 hard-stop 7일 내 2회: 정책(권한/retry/guardrail) ADR 강제 생성
- checkpoint miss 3일 초과: scope 축소 또는 milestone 분할 후 execution order 재정렬

## Done Contract (for This Expansion)
- 문서:
  - canonical plan/ADR/quality 문서가 해당 repo bucket 또는 domain bucket에 생성됨
  - `README`/`document-map` 링크 정합성 유지
- 실행:
  - 각 큐 항목별 최소 1개 gate evidence artifact 생성
  - GitHub Project 필드(`component`, `initiative`, `target_repo`, `execution_order`) 누락 0건
- 검증:
  - `uap-docs.sh check --profile all` 통과
  - 관련 CI 체인 통과(계약 검증 + dry-run + replay)

## Immediate Next Actions (Start Today)
1. `#14~#23` 실행 큐를 execution_order 기준으로 pull 실행(칸반 정책 유지)
2. `platform-contracts`를 C1~C8 canonical source로 전환하는 migration patch 설계
3. `planningops/config/runtime-profiles.json` 기반 task별 runtime/provider override 운영 시작
