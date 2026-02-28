---
doc_id: uap-github-planningops-sync-brainstorm
title: UAP GitHub PlanningOps Sync Brainstorm
doc_type: brainstorm
domain: discovery
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
topic: unified-personal-agent-platform-github-planningops-sync
tags:
  - uap
  - github
  - planningops
  - projects
  - automation
summary: Explores a plan-repo-centric model that syncs plans with GitHub Projects, issues, milestones, and multi-repo tracking.
related_docs:
  - ../20-repos/monday/10-discovery/2026-02-27-uap-core.brainstorm.md
  - ../20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ../20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md
---

# UAP GitHub PlanningOps Sync

## What We're Building
계획 전용 레포(예: `uap-plans`)를 별도로 두고, 계획 문서 변경(commit/push)을 기준으로 GitHub 이슈/마일스톤/프로젝트 아이템을 자동 생성·갱신·추적하는 PlanningOps 계층을 만든다.

핵심 목표:
- 계획 문서와 실행 추적의 단절 제거
- 다중 레포 작업을 단일 initiative 관점으로 추적
- 상태 변경을 수작업이 아니라 계약 기반 동기화로 처리

## Why This Approach
현재 문서 체계는 구조화가 잘 되어 있지만, GitHub 실행 단위(issues/projects)와의 연결은 수동이다. 계획이 살아있는 운영 시스템이 되려면 문서 변경이 트래킹 엔티티로 자동 반영되어야 한다.

## Approaches Considered

### Approach A (Recommended): Plan-Repo Source of Truth + One-Way Sync
계획 레포 문서(frontmatter + checklists + gate evidence)를 기준으로 GitHub Issues/Milestones/Project field를 단방향 동기화한다.

Pros:
- 캡슐화/결정권이 문서에 고정됨
- 충돌 해석이 단순함(one-way reconciliation)
- multi-repo 작업에도 initiative 중심 추적 가능

Cons:
- GitHub UI에서 직접 수정 시 드리프트 가능(동기화 정책 필요)

Best when:
- 문서 기반 의사결정과 계약 일관성이 최우선일 때

### Approach B: GitHub Project Source of Truth + Docs Mirror
GitHub Project를 1차 소스로 두고 문서를 파생물로 생성한다.

Pros:
- 협업자에게 익숙한 운영 방식
- Project UI 중심 운영이 쉬움

Cons:
- 계약/게이트 중심 문서 모델이 약해질 수 있음
- 문서 품질 자동화(frontmatter/gates)와 긴장 가능

### Approach C: Dual-Write Bi-Directional Sync
문서와 GitHub 양쪽을 모두 1차 입력으로 허용한다.

Pros:
- 유연성 최대

Cons:
- 충돌/우선순위/병합 규칙이 복잡해짐
- 초기 단계에 과도한 운영 복잡도 유발

## Recommended Direction
Approach A로 시작한다.  
핵심 원칙: `plan 문서 -> 동기화 엔진 -> GitHub artifacts` 단방향 흐름, 역방향은 읽기 전용 검증/경고만 수행.

## PlanningOps Contract Draft
- Entity mapping:
  - `plan_item_id` -> `issue_number`
  - `initiative_id` -> `milestone`
  - `run/gate status` -> `project fields`
- Status mapping (초안):
  - `draft|active|blocked|done` <-> GitHub issue/project status
  - Gate verdict(`pass|fail|inconclusive`) -> custom field
- Idempotency:
  - `sync_key = <doc_id>:<plan_item_id>:<version>`
  - 중복 생성 방지와 재실행 안전성 필수

## Phase 1 Scope
- 계획 레포 1개 + 대상 실행 레포 N개 연결
- GitHub Issues/Milestones/Projects v2 자동 생성/갱신
- status 동기화(문서 -> GitHub) + 드리프트 리포트 생성
- manual override는 Phase 1에서 최소화(승인된 레이블 기반 예외만)

## Out of Scope (Phase 1)
- 완전 양방향 동기화
- 고급 예측(ETA/velocity forecasting)
- 조직 전체 포트폴리오 대시보드

## Open Questions
아래 항목은 브레인스토밍 시점 질문이다. 구현 착수 전 최종 판단/기본값은
`../30-execution-plan/uap-github-planningops-sync.execution-plan.md`
의 `Deferred Decisions`와 `Working Defaults`를 canonical source로 사용한다.

- milestone 단위를 initiative 단위로 통일할지, 레포 단위로 분할할지
- 완료 기준의 진실원천을 `issue closed`로 볼지, `gate pass evidence`로 볼지
- 동기화 트리거를 push 이벤트 중심으로 할지, 스케줄 재조정(cron)까지 포함할지

## Resolved Questions
- 계획 레포는 별도로 두고 지속적으로 commit/push하며 운영한다.
- GitHub Projects와 상태 동기화 자동화는 Phase 1 목표에 포함한다.
- 초기 방향은 단순성과 캡슐화를 위해 one-way sync를 우선한다.
- GitHub Project 토폴로지는 단일 org-level Project 1개로 통합 운영한다.

## Next Steps
- `/prompts:workflows-plan`에서 PlanningOps 아키텍처, 경계, 계약, 자동화 단계(스크립트/Action/권한)를 구체화한다.
- Open Questions를 우선 확정한 뒤 구현 단계로 진입한다.
