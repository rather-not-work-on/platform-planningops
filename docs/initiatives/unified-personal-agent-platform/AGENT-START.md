---
doc_id: uap-agent-start
title: UAP Agent Start Guide
doc_type: navigation
domain: navigation
status: active
date: 2026-02-27
updated: 2026-02-28
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

## Canonical Core 7
### Entry Core (next reads)
`AGENT-START`(현재 문서)는 Entry Core anchor다. 아래 4개 문서를 이어서 읽는다.

1. [AGENT Principles](./AGENT.md)
2. [Project Identity](./00-governance/uap-monday-identity.meta.md)
3. [Document Map](./90-navigation/uap-document-map.navigation.md)
4. [PlanningOps Sync Plan](./30-execution-plan/uap-github-planningops-sync.execution-plan.md)

### Policy Core (apply before implementation)
1. [Doc Governance](./00-governance/uap-doc-governance.meta.md)
2. [Trade-off Decision Framework](./40-quality/uap-planningops-tradeoff-decision-framework.quality.md)

## Mandatory Read Order (Minimal)
1. Entry Core anchor(현재 문서) + Entry Core next reads 4
2. Policy Core 2
3. [README](./README.md) for broad context
4. [Foundation Execution Plan](./20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md)

## Quick Checks Before Any Work
1. 문서 검증 실행:
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile canonical
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
```
2. 게이트 네임스페이스 확인:
- `Gate A~G` = Foundation 게이트
- `Sync Gate A~F` = PlanningOps Sync 게이트
3. 기본값 원천 확인:
- Foundation: `Working Defaults`
- PlanningOps Sync: `Deferred Decisions` + `Working Defaults`

## What To Do First (Implementation Start)
1. Decision-agnostic Track A 작업부터 시작
2. Decision-dependent 작업은 스텁까지만 허용
3. Gate evidence 저장 경로를 먼저 만들고 산출물 축적

## Do Not Do
- 계약(C1~C8/C1~C5) 밖의 암묵 상태를 시스템 경계로 노출하지 않는다.
- `issue closed`만으로 완료를 확정하지 않는다.
- Foundation Gate와 Sync Gate를 혼용해 판정하지 않는다.
- 직접 모듈 결합(import)을 추가하지 않는다.

## Escalate When
- 기본값 변경이 필요할 때
- 계약 필드 의미를 바꿔야 할 때
- 게이트 판정 근거가 불충분할 때
