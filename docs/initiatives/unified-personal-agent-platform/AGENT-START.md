---
doc_id: uap-agent-start
title: UAP Agent Start Guide
doc_type: navigation
domain: navigation
status: active
date: 2026-02-27
updated: 2026-03-05
initiative: unified-personal-agent-platform
tags:
  - uap
  - onboarding
  - agent
  - start
summary: Fast entrypoint for agents with no prior context to identify Core 7, path rules, and immediate next actions.
related_docs:
  - ./README.md
  - ./AGENT.md
  - ./00-governance/uap-doc-governance.meta.md
  - ./00-governance/uap-monday-identity.meta.md
  - ./90-navigation/uap-document-map.navigation.md
  - ./40-quality/uap-planningops-tradeoff-decision-framework.quality.md
  - ./20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md
  - ./30-execution-plan/uap-github-planningops-sync.execution-plan.md
  - ./30-execution-plan/2026-02-28-uap-topology-priority-expansion.execution-plan.md
  - ./30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md
---

# UAP Agent Start Guide

## Goal
문맥이 없는 신규 에이전트가 5분 내에 문서 구조, 현재 기본값, 착수 순서를 파악하도록 돕는다.

## Canonical vs Workbench
- canonical source: `docs/initiatives/unified-personal-agent-platform`
- workbench outputs: `docs/workbench/unified-personal-agent-platform`
- 구현 판단의 기준(SoT)은 canonical 문서에서만 가져온다.

## Path Root Rule (Mandatory)
- 문서 본문 링크는 문서 파일 기준 상대경로(`./`, `../`)만 사용한다.
- 셸/CI 명령에서 파일 지정은 repo 루트 기준 상대경로(`docs/initiatives/unified-personal-agent-platform/...`)를 사용한다.

## Field Token Rule (Mandatory)
- 계약/이슈 본문 메타는 `snake_case`를 기준으로 기록한다. 예: `ready_contract`, `l1_contract_clarification`
- Project UI 표시는 `kebab-case` 또는 Title 형태일 수 있다. 예: `ready-contract`, `L1 Contract-Clarification`
- 의미 기준은 계약(`snake_case`)이며, 투영/검증 스크립트가 표시값을 매핑한다.

## Canonical Core 7
### Entry Core (next reads)
`AGENT-START`(현재 문서)는 Entry Core anchor다. 아래 6개 문서를 이어서 읽는다.

1. [AGENT Principles](./AGENT.md)
2. [Project Identity](./00-governance/uap-monday-identity.meta.md)
3. [Document Map](./90-navigation/uap-document-map.navigation.md)
4. [PlanningOps Sync Plan](./30-execution-plan/uap-github-planningops-sync.execution-plan.md)
5. [Topology Priority Expansion Plan](./30-execution-plan/2026-02-28-uap-topology-priority-expansion.execution-plan.md)
6. [Module Refactor Hygiene Loop Plan](./30-execution-plan/2026-03-01-uap-module-refactor-hygiene-loop.execution-plan.md)

### Policy Core (apply before implementation)
1. [Doc Governance](./00-governance/uap-doc-governance.meta.md)
2. [Trade-off Decision Framework](./40-quality/uap-planningops-tradeoff-decision-framework.quality.md)

## Mandatory Read Order (Minimal)
1. Entry Core anchor(현재 문서) + Entry Core next reads 6
2. Policy Core 2
3. [README](./README.md) for broad context
4. [Foundation Execution Plan](./20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md)

## Quick Checks Before Any Work
1. 문서 검증 실행:
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile canonical
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
bash planningops/scripts/test_module_readme_contract.sh
```
2. 게이트 네임스페이스 확인:
- `Gate A~G` = Foundation 게이트
- `Sync Gate A~F` = PlanningOps Sync 게이트
3. 기본값 원천 확인:
- Foundation: `Working Defaults`
- PlanningOps Sync: `Deferred Decisions` + `Working Defaults`
4. 협업 규칙 확인:
- 기본값은 `PR-first`이며 직접 `main` 푸시는 금지한다.
- PR 본문은 `.github/pull_request_template.md`를 사용한다.
- `pr-review-gate`와 문서/CI 게이트 통과 후 병합한다.
5. 리팩토링 작업이면 먼저 스코프를 결정한다:
- 단일 레포: `python3 planningops/scripts/refactor_hygiene_loop.py --policy-file planningops/config/refactor-hygiene-policy.json`
- 멀티 레포: `python3 planningops/scripts/refactor_hygiene_multi_repo.py --config-file planningops/config/refactor-hygiene-multi-repo.json --workspace-root .`

## UX Snapshot (What You Will Experience)
이 저장소의 계획대로 이슈를 처리하면, 사용자는 아래 UX를 경험한다.

1. 사용자가 카드/문서를 갱신한다.
- 핵심 필드: `Status`, `workflow_state`, `loop_profile`, `execution_order`, `plan_lane`, `depends_on`, `initiative`, `component`, `target_repo`
2. 에이전트는 비정기 Kanban pull로 카드 하나를 선택한다.
- pull 조건: `Status=Todo` AND `workflow_state in {ready-contract, ready-implementation}`
- `depends_on` 미충족이면 즉시 `blocked`로 처리
3. 에이전트가 `loop_profile`(`L1~L5`)을 결정해 루프 1회를 실행한다.
4. 실행 결과가 검증되어 `pass|fail|inconclusive`가 산출된다.
5. 사용자에게 보이는 결과가 자동 반영된다.
- Issue comment: `verdict`, `reason_code`, `loop_profile`, 증빙 경로
- Project fields: `Status`, `workflow_state`, `loop_profile`, `last_verdict`, `last_reason`
6. 반복 실패 시 자동 재계획 경로로 이동한다.
- 트리거: 동일 `reason_code` 3회 또는 `inconclusive` 2회 연속

운영 원칙:
- 스프린트 기반이 아니라 비정기 Kanban 기반이다.
- 진행 판단은 기간보다 증빙/게이트 결과를 우선한다.

현재 구현 기준(`2026-03-03`) 참고:
- `ready-contract` 기본 선택은 `L1`이다.
- issue body에 `simulation_required: true` 또는 `uncertainty_level: medium|high|critical`가 있으면 `L2`를 선택한다.

## Agent Execution Sequence (How the Agent Works)
1. Intake: 후보 카드 수집 및 우선순위/의존성 검사
2. Selector: `loop_profile` 결정 + selection trace 기록
3. Execute: loop 실행 및 아티팩트 생성
4. Verify: verdict/reason 및 trigger 판정
5. Feedback: issue/project 업데이트
6. Transition log: 상태 전이와 재계획 플래그 기록

필수 증빙:
- `intake-check.json`
- `simulation-report.md`
- `verification-report.json`
- `transition-log.ndjson`

루프별 추가 증빙:
- `L1`: `contract-gap-report.md`
- `L2`: `scenario-matrix.json`
- `L3`: `test-report.json`
- `L4`: `sync-summary.json`, `drift-report.json`
- `L5`: `replan-decision.md`

## What To Do First (Implementation Start)
1. Decision-agnostic Track A 작업부터 시작
2. Decision-dependent 작업은 스텁까지만 허용
3. Gate evidence 저장 경로를 먼저 만들고 산출물 축적
4. 모듈 리팩토링이 필요한 경우 먼저 hygiene analyzer를 실행해 external-first/internal-next 큐를 확정

## Do Not Do
- 계약(C1~C8/C1~C5) 밖의 암묵 상태를 시스템 경계로 노출하지 않는다.
- `issue closed`만으로 완료를 확정하지 않는다.
- Foundation Gate와 Sync Gate를 혼용해 판정하지 않는다.
- 직접 모듈 결합(import)을 추가하지 않는다.

## Escalate When
- 기본값 변경이 필요할 때
- 계약 필드 의미를 바꿔야 할 때
- 게이트 판정 근거가 불충분할 때
