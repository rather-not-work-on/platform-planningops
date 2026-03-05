---
title: plan: Meta Plan Orchestration and Governance
type: plan
date: 2026-03-03
updated: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines a meta plan that governs plan-of-plans lifecycle, dependency graph execution, and hard-gate decisions for autonomous Kanban operation.
---

# plan: Meta Plan Orchestration and Governance

## Overview
이 문서는 단일 기능 계획이 아니라, 여러 실행 계획을 통합 관리하는 `meta plan`이다.

목표:
1. 계획 간 의존관계를 그래프 형태로 고정한다.
2. 어떤 계획을 언제 pull/hold/replan할지 자동 판정 규칙을 둔다.
3. 계획-이슈-프로젝트-검증 산출물의 정합성을 하나의 운영면에서 관리한다.

## Problem Statement / Motivation
현재는 개별 계획은 잘 작성되지만, 전체 우선순위와 의존성 전이를 문서 간 수동 판단에 의존하는 구간이 남아 있다.

리스크:
- plan 간 선후관계 모호성
- 동일 경계(계약/필드/검증) 변경의 중복 작업
- blocked/replan 판단의 일관성 저하

## Proposed Solution
`Meta Plan Graph (MPG v1)`를 도입한다.

핵심 구성:
1. plan node: 각 실행 계획 문서
2. edge: depends_on / blocks / supersedes 관계
3. gate: node 전이 조건(`ready -> in-progress -> review-gate -> done`)
4. policy: Kanban WIP, escalation, rollback

## Terminology and Field Canonicalization
### Terminology (fixed)
- `Meta Plan`: plan-of-plans orchestration unit
- `Node`: single executable plan unit
- `Edge`: plan dependency relation (`depends_on`, `blocks`, `supersedes`)
- `Ready Set`: 현재 WIP/의존성 조건에서 pull 가능한 node 집합
- `Replan-Required`: escalation으로 재계획이 필요한 node 상태

### Field and Key Policy
Meta orchestration이 issue/project를 생성·갱신할 때 아래 canonical key를 그대로 사용한다:
- `initiative`
- `target_repo`
- `component`
- `execution_order`
- `workflow_state`
- `loop_profile`
- `last_verdict`
- `last_reason`

State key policy:
- plan 문서/스크립트 내부 key는 `snake_case`
- project single-select display value는 기존 옵션 표기를 사용

## Research Consolidation
### Local Findings
- 이미 운영 중인 핵심 구조:
  - plan-to-issue bootstrap
  - loop profile selector
  - schema validator
  - transition-log 기반 replan trigger
- 부족한 점:
  - “plan-of-plans” 상태를 관리하는 단일 메타 계약 부재

### External Research Decision
- skipped (local architecture alignment task)

## SpecFlow Analysis
### User Flow Overview
1. Planner가 신규 plan node를 등록한다.
2. Meta orchestrator가 graph validation을 수행한다.
3. Eligible node만 backlog compile 대상으로 승격한다.
4. 실행 결과(verdict/evidence)에 따라 node 상태를 전이한다.
5. fail/inconclusive streak는 replan subtree를 생성한다.

### Flow Permutations Matrix
| Scenario | Node state | Trigger | Transition | Evidence |
|---|---|---|---|---|
| 신규 node | `draft` | graph validation pass | `ready` | meta-graph-report |
| 실행 성공 | `in-progress` | verdict `pass` | `done` | loop + projection reports |
| 실행 실패 | `in-progress` | verdict `fail` | `blocked` | failure taxonomy evidence |
| 반복 불확실 | `review-gate` | `inconclusive_x2` | `replan-required` | transition log + replan report |
| 상위 계획 변경 | `ready|in-progress` | `supersedes` edge | `needs-rebase` | diff + impact report |

### Critical Questions and Defaults
1. 메타 플랜의 SoT를 어디에 둘 것인가?
- Default: workbench plan 문서 + generated meta manifest artifact
2. 노드 granularity는 plan당 1개인가 section별인가?
- Default: plan당 1 node, section-level task는 child items로 관리
3. blocked node 자동 재개 조건은?
- Default: dependency edge의 upstream `done` + drift=0일 때만 재개

## Technical Approach
### A. Meta Plan Graph Contract
Planned file:
- `planningops/contracts/meta-plan-graph-contract.md`

Planned artifact:
- `planningops/artifacts/meta-plan/meta-graph.json`

Graph schema (concept):
```json
{
  "meta_plan_id": "uap-meta-20260303",
  "nodes": [
    {
      "node_id": "plan-auto-exec-contract",
      "plan_path": "docs/workbench/unified-personal-agent-platform/plans/2026-03-03-plan-auto-executable-plans-contract-and-runner-plan.md",
      "status": "ready",
      "gate_profile": "L1"
    }
  ],
  "edges": [
    {
      "from": "plan-auto-exec-contract",
      "to": "plan-meta-governance-rollout",
      "type": "depends_on"
    }
  ]
}
```

### B. Meta Orchestrator
Planned files:
- `planningops/scripts/meta_plan_orchestrator.py`
- `planningops/scripts/test_meta_plan_orchestrator_contract.sh`

Responsibilities:
1. load meta graph
2. validate DAG + policy rules
3. compute ready set under WIP limits
4. invoke compile/execution pipeline
5. emit meta execution report

### C. Gate and Policy Mapping
Policy source:
- `planningops/contracts/requirements-contract.md`
- `planningops/contracts/failure-taxonomy-and-retry-policy.md`
- `planningops/contracts/escalation-gate-contract.md`

Mapping:
- node verdict derives from child issue verdict aggregate
- node failure reason derives from dominant reason_code family
- node replan state derives from trigger rules (`same_reason_x3`, `inconclusive_x2`)

## Implementation Phases
### Phase 1: Meta Contract Freeze
Deliverables:
- `planningops/contracts/meta-plan-graph-contract.md`
- `planningops/schemas/meta-plan-graph.schema.json`

### Phase 2: Graph Builder
Deliverables:
- `planningops/scripts/build_meta_plan_graph.py`
- artifact: `planningops/artifacts/meta-plan/meta-graph.json`

### Phase 3: Orchestrator MVP
Deliverables:
- `planningops/scripts/meta_plan_orchestrator.py`
- artifact: `planningops/artifacts/meta-plan/meta-execution-report.json`

### Phase 4: Governance Integration
Deliverables:
- project view alignment (`initiative`, `component`, `workflow_state`, `loop_profile`)
- CI job for graph validity + gate coherency

### Phase 5: Operationalization
Deliverables:
- runbook for local-first operation
- replan escalation SOP

## Issue-Ready Backlog (MPG v1)
| execution_order | plan_item_id | title | component | target_repo | workflow_state | loop_profile | depends_on | primary_output |
|---|---|---|---|---|---|---|---|---|
| 400 | `mpg-400` | Define meta-plan graph contract | `contracts` | `rather-not-work-on/platform-planningops` | `ready_contract` | `l1_contract_clarification` | 360 | `planningops/contracts/meta-plan-graph-contract.md` |
| 410 | `mpg-410` | Add meta-plan graph schema | `contracts` | `rather-not-work-on/platform-planningops` | `ready_contract` | `l1_contract_clarification` | 400 | `planningops/schemas/meta-plan-graph.schema.json` |
| 420 | `mpg-420` | Implement build_meta_plan_graph | `planningops` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l3_implementation_tdd` | 410 | `planningops/scripts/build_meta_plan_graph.py` |
| 430 | `mpg-430` | Implement meta_plan_orchestrator | `orchestrator` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l4_integration_reconcile` | 420 | `planningops/scripts/meta_plan_orchestrator.py` |
| 440 | `mpg-440` | Add orchestrator contract tests | `orchestrator` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l3_implementation_tdd` | 430 | `planningops/scripts/test_meta_plan_orchestrator_contract.sh` |
| 450 | `mpg-450` | Integrate graph validity gate in CI | `planningops` | `rather-not-work-on/platform-planningops` | `review_gate` | `l4_integration_reconcile` | 440 | `.github/workflows/federated-ci-matrix.yml` |
| 460 | `mpg-460` | Publish meta orchestration runbook | `planningops` | `rather-not-work-on/platform-planningops` | `review_gate` | `l2_simulation` | 450 | `planningops/contracts/meta-plan-orchestration-runbook.md` |

## Detailed Task Backlog (Pseudo)
- [ ] `planningops/contracts/meta-plan-graph-contract.md` 작성
- [ ] `planningops/schemas/meta-plan-graph.schema.json` 작성
- [ ] `planningops/scripts/build_meta_plan_graph.py` 구현
- [ ] `planningops/scripts/meta_plan_orchestrator.py` 구현
- [ ] `planningops/scripts/test_meta_plan_orchestrator_contract.sh` 추가
- [ ] `planningops/artifacts/meta-plan/meta-execution-report.json` 출력 검증

## Acceptance Criteria
### Functional Requirements
- [ ] Meta graph가 cycle 없이 검증된다.
- [ ] Meta orchestrator가 ready set을 deterministic하게 계산한다.
- [ ] Node state 전이가 issue/project verdict와 일치한다.
- [ ] Replan trigger 발생 시 meta node가 `replan-required`로 전환된다.

### Non-Functional Requirements
- [ ] 동일 graph 입력에서 동일 ready set 출력
- [ ] node 100개 기준 orchestration <= 5분
- [ ] partial failure에서도 report completeness 100%

### Quality Gates
- [ ] graph schema validation pass
- [ ] orchestrator contract tests pass
- [ ] `uap-docs.sh check --profile all` pass

## Success Metrics
- `meta_graph_validation_failures`: 감소 추세
- `dependency_misorder_incidents`: 0 목표
- `blocked_to_replan_decision_latency`: 단축
- `manual_priority_override_count`: 감소

## Risk Analysis & Mitigation
Risk:
- meta layer가 과도 복잡도를 추가할 수 있음
Mitigation:
- node granularity를 plan-level로 고정
- phase rollout으로 strict mode 점진 전환

Risk:
- graph와 실제 project 상태 간 drift
Mitigation:
- periodic reconcile + fail-fast validator

## Documentation Plan
Promotion candidates:
- `docs/initiatives/unified-personal-agent-platform/30-execution-plan/*`
- `docs/initiatives/unified-personal-agent-platform/40-quality/*`

Workbench-only interim outputs:
- graph/report artifacts
- rollout experiment notes

## References & Related Plans
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-03-plan-auto-executable-plans-contract-and-runner-plan.md`
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-03-plan-simple-core-validation-and-core-instruction-hardening.md`
- `planningops/scripts/bootstrap_two_track_backlog.py`
- `planningops/scripts/issue_loop_runner.py`

## Next Actions
1. meta graph contract를 먼저 확정한다.
2. auto-executable plan contract(PEC)와 연결해 compile/orchestration 경계를 맞춘다.
3. strict governance 전환 전 hybrid 운영으로 1회 이상 드라이런한다.
