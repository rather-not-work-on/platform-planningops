---
doc_id: uap-topology-priority-expansion-plan
title: feat: UAP Topology-Priority Expansion Plan
doc_type: execution-plan
domain: planning
status: active
date: 2026-02-28
updated: 2026-03-01
initiative: unified-personal-agent-platform
tags:
  - uap
  - topology
  - priority
  - contracts
  - infrastructure
  - kanban
summary: Topology-first priority plan with Wave A completion snapshot, Wave B issue-map registration, and refined local-first multi-repo execution queue.
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
  - PlanningOps MVP 이슈 `#2~#13` 전부 `Done`.
  - Topology expansion queue `#14~#23` 전부 `Done`.
  - Wave B queue `#24~#32` 생성 및 Project 필드 스키마 정렬 완료(`Todo`).
  - `planningops/`에 C1~C8 참조 맵, multi-repo fan-out 리포트, end-to-end simulation evidence bundle 구축 완료.
- GitHub Project:
  - org project `rather-not-work-on/projects/2` 사용 중.
  - 필드 스키마(`Status`, `workflow_state`, `execution_order`, `plan_lane`, `component`, `initiative`, `target_repo`) 검증 스크립트 기준 통과.
- 레포 토폴로지:
  - 존재: `platform-planningops`, `monday`, `platform-contracts`, `platform-provider-gateway`, `platform-observability-gateway`.
  - 신규 3개 레포는 `public` 정책으로 생성 완료.

## Wave A Completion Snapshot (`#14~#23`)
| Execution Order | Issue | Result |
|---|---|---|
| 110 | #14 | topology bootstrap ADR/checklist 완료 |
| 120 | #15 | project field schema guard v2 완료 |
| 130 | #16 | `platform-contracts` C1~C8 seed 완료 |
| 140 | #17 | semver policy + compatibility CI 완료 |
| 150 | #18 | provider-gateway C4 fallback smoke 완료 |
| 160 | #19 | observability-gateway C5 replay/dedupe smoke 완료 |
| 170 | #20 | monday Executor/Worker handoff mapping 완료 |
| 180 | #21 | monday scheduler queue/idempotent dequeue 완료 |
| 190 | #22 | planningops multi-repo fan-out 리포트 완료 |
| 200 | #23 | dry-run -> apply -> reconcile simulation bundle 완료 |

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
- agent는 `Status=Todo` AND `workflow_state in {ready-contract, ready-implementation}` 카드만 pull.
- prerequisite 불충족 카드는 `blocked`로 강등 후 원인 코드(`contract|permission|context|runtime`) 기록.

### WIP limits
- Contracts lane: 2
- Infra lane(provider+o11y): 2
- Runtime lane: 2
- PlanningOps lane: 2
- Ops lane: 1

## Dependency-Ordered Work Queue (Wave A Completed)
| Execution Order | Priority | Component | Target Repo | Work Item | Depends On |
|---|---|---|---|---|---|
| 110 | P0 | planningops | rather-not-work-on/platform-planningops | Multi-repo topology bootstrap ADR + repo creation checklist | done |
| 120 | P0 | planningops | rather-not-work-on/platform-planningops | GitHub Project field schema v2 (`component/repo/initiative` guard) | done |
| 130 | P1 | contracts | rather-not-work-on/platform-contracts | `platform-contracts` bootstrap and C1~C8 seed schema migration | done |
| 140 | P1 | contracts | rather-not-work-on/platform-contracts | compatibility CI and semver policy (`major/minor/patch`) | done |
| 150 | P2 | provider-gateway | rather-not-work-on/platform-provider-gateway | LiteLLM gateway skeleton + C4 adapter contract | done |
| 160 | P3 | observability-gateway | rather-not-work-on/platform-observability-gateway | LangFuse trace sink + C5 ingest contract | done |
| 170 | P4 | runtime | rather-not-work-on/monday | Executor/worker naming ADR + harness integration contract | done |
| 180 | P5 | orchestrator | rather-not-work-on/monday | task scheduler(queue) baseline + idempotent dequeue | done |
| 190 | P6 | planningops | rather-not-work-on/platform-planningops | multi-repo parser/sync expansion (`target_repo` fan-out) | done |
| 200 | P6 | planningops | rather-not-work-on/platform-planningops | end-to-end simulation (2+ repos) + gate evidence bundle | done |

## Refined Queue (Wave B, Local-First Hardening)
| Execution Order | Priority | Component | Target Repo | Work Item | Depends On |
|---|---|---|---|---|---|
| 210 | P7 | planningops | rather-not-work-on/platform-planningops | cross-repo issue intake runner (remove single-repo filter) | 200 |
| 220 | P7 | planningops | rather-not-work-on/platform-planningops | repo-specific execution adapter hooks (contracts/provider/o11y/runtime) | 210 |
| 230 | P8 | provider-gateway | rather-not-work-on/platform-provider-gateway | local LiteLLM stack launcher + profile override drill | 210 |
| 240 | P8 | observability-gateway | rather-not-work-on/platform-observability-gateway | local LangFuse stack launcher + replay/backfill drill | 210 |
| 250 | P8 | contracts | rather-not-work-on/platform-contracts | C1~C8 consumer conformance checks across repos | 220, 230, 240 |
| 260 | P9 | runtime | rather-not-work-on/monday | scheduler-runner integration with planningops loop handoff | 220 |
| 265 | P9 | planningops | rather-not-work-on/platform-planningops | bounded Sisyphus guardrails (`attempt budget`, `checkpoint/resume`, `lease lock`, `watchdog`, `escalation gate`) | 260 |
| 270 | P9 | planningops | rather-not-work-on/platform-planningops | federated CI check matrix across 4 repos | 250, 260, 265 |
| 280 | P10 | planningops | rather-not-work-on/platform-planningops | 7-day local pilot + Oracle profile partial migration rehearsal | 270 |

## Wave B Issue Map (Registered, `2026-03-01`)
| Execution Order | Issue | Component | Target Repo | Status |
|---|---|---|---|---|
| 210 | #24 | planningops | rather-not-work-on/platform-planningops | Todo |
| 220 | #25 | planningops | rather-not-work-on/platform-planningops | Todo |
| 230 | #26 | provider-gateway | rather-not-work-on/platform-provider-gateway | Todo |
| 240 | #27 | observability-gateway | rather-not-work-on/platform-observability-gateway | Todo |
| 250 | #28 | contracts | rather-not-work-on/platform-contracts | Todo |
| 260 | #29 | runtime | rather-not-work-on/monday | Todo |
| 265 | #32 | planningops | rather-not-work-on/platform-planningops | Todo |
| 270 | #30 | planningops | rather-not-work-on/platform-planningops | Todo |
| 280 | #31 | planningops | rather-not-work-on/platform-planningops | Todo |

## Checkpoints (Absolute Dates, Refined)
- Checkpoint T0 (`2026-02-28`): Wave A(`110~200`) 완료
- Checkpoint T1 (`2026-03-05`): `210~220` planningops cross-repo execution path 통과
- Checkpoint T2 (`2026-03-12`): `230~240` local LiteLLM/LangFuse launch/replay drill 통과
- Checkpoint T3 (`2026-03-19`): `250~265` conformance + runtime integration + bounded guardrails 통과
- Checkpoint T4 (`2026-03-26`): `270` federated CI 통과
- Checkpoint T5 (`2026-04-02`): `280` 7-day local pilot + Oracle partial rehearsal 통과

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
  - GitHub Project 필드(`component`, `initiative`, `target_repo`, `execution_order`, `workflow_state`) 누락 0건
- 검증:
  - `uap-docs.sh check --profile all` 통과
  - 관련 CI 체인 통과(계약 검증 + dry-run + replay)

## Immediate Next Actions (Start Today)
1. `#25` 우선 착수: repo-specific adapter hook 인터페이스/실패 reason taxonomy 고정
2. `#32` 착수: bounded Sisyphus guardrails(`attempt budget`, `checkpoint/resume`, `lease lock`, `watchdog`, `escalation gate`) 구현
3. `#26/#27` 병행: local LiteLLM/LangFuse launcher 표준 스크립트와 artifact 경로 규약 확정
