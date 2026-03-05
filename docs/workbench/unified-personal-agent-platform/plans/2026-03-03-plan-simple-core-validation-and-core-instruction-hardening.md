---
title: plan: Simple Core Validation and Core Instruction Hardening
type: plan
date: 2026-03-03
updated: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Validates whether the current PlanningOps system follows simple-core agent best practices and defines a hardening plan for instruction clarity and runtime simplicity.
---

# plan: Simple Core Validation and Core Instruction Hardening

## Enhancement Summary
**Deepened on:** 2026-03-03  
**Scope:** instruction simplicity + core loop architecture  
**Source plan:** `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`

### Key Improvements
1. `simple core` 기준으로 현재 시스템을 pass/conditional-pass/fail로 명시 평가했다.
2. 코어 지시문과 운영 지시문을 분리하는 계층 모델을 고정했다.
3. 루프 런타임의 복잡도 hotspot(단일 대형 함수)을 구조 리스크로 명시했다.
4. “지시문 강도 유지 + 복잡도 축소”를 동시에 달성하는 단계별 실행안을 정의했다.

## External Research Insights
### Source A: AI Times 기사 (2026-03-03)
- 링크: `https://www.aitimes.com/news/articleView.html?idxno=207369`
- 핵심 해석: AGENTS/지시문은 기술 문서 전체 요약이 아니라, 에이전트가 반드시 알아야 할 프로젝트 특화 규칙만 담아야 한다.

### Source B: Anthropic `Building effective agents`
- 링크: `https://www.anthropic.com/research/building-effective-agents`
- 핵심 해석:
  - 단순하고 composable한 패턴을 우선 사용한다.
  - 워크플로 복잡도는 필요한 지점에서만 단계적으로 증가시킨다.

### Source C: OpenAI `A practical guide to building agents`
- 링크: `https://cookbook.openai.com/examples/agents_sdk/guide_to_building_effective_agents`
- 핵심 해석:
  - 단일 에이전트 + 명확한 지시문으로 시작하고,
  - 핸드오프/멀티에이전트는 명확한 복잡도 임계치를 넘을 때 도입한다.

## Section Manifest
1. **Core instruction layer**: AGENT 원칙/시작 가이드가 최소·강한 형태인지 평가
2. **Contract layer**: 요구사항 계약이 코어와 운영 세부를 과도하게 혼합하는지 평가
3. **Runtime layer**: loop runner 구조가 simple core 원칙을 저해하는지 평가
4. **Validation layer**: 현재 검증 체인이 단순성과 안정성을 동시에 보장하는지 평가

## Current State Validation
### A. Core Instruction Layer
검토 대상:
- `docs/initiatives/unified-personal-agent-platform/AGENT.md`
- `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`

평가:
- `AGENT.md`는 44 lines의 invariant-only 구조로 매우 우수하다.
- `AGENT-START.md`는 강한 운영 가이드이지만 범위가 넓어(145 lines) 코어 지시문으로 쓰기엔 다소 무겁다.

판정:
- **Strong core instructions:** `pass`
- **Instruction minimalism:** `conditional-pass`

### B. Contract Layer
검토 대상:
- `planningops/contracts/requirements-contract.md`
- `planningops/contracts/problem-contract.md`
- `planningops/contracts/failure-taxonomy-and-retry-policy.md`

평가:
- 계약 명세의 강도는 높고 실행 가능하다.
- 다만 일부 필드/상태 의미가 AGENT-START/plan 문서와 중복 기재되어 drift 위험이 있다.

판정:
- **Contract rigor:** `pass`
- **Contract simplicity:** `conditional-pass`

### C. Runtime Layer
검토 대상:
- `planningops/scripts/issue_loop_runner.py`

정량 지표:
- 전체 함수 수: `27`
- `main()` 길이: `824 lines`

평가:
- 기능 완성도는 높지만 단일 진입점에 책임이 과집중되어 있다.
- simple core 원칙 관점에서 운영 복잡도가 코어 지시문 단순성을 상쇄할 가능성이 있다.

판정:
- **Runtime maintainability simplicity:** `fail`

### D. Validation Layer
검토 대상:
- `uap-docs.sh`, `validate_project_field_schema.py`, Track1/Track2 contract pack checks

평가:
- 검증 체인은 충분히 강하고 재현 가능하다.
- 다만 “복잡도 예산” 자체를 게이트로 관리하지는 않는다.

판정:
- **Verification strength:** `pass`
- **Simplicity governance:** `conditional-pass`

## Overall Verdict
- **Core instruction strength:** `pass`
- **System simplicity:** `conditional-pass`
- **Readiness score (simple-core lens):** `7/10`

결론:
- 코어 지시문의 방향은 맞다.
- 그러나 런타임 구조 복잡도가 증가하고 있어, 지금 단계에서 단순성 가드레일을 명문화해야 한다.

## Critical Improvement (Must Address)
가장 중요한 개선점은 단일 런타임 진입점 복잡도 축소다.

Must-fix:
- `issue_loop_runner.py`의 대형 `main()`을 stage 함수군으로 분해하고,
- stage 입력/출력 필드를 고정해 drift를 차단한다.

Field key baseline (for simplification work):
- `workflow_state`
- `loop_profile`
- `last_verdict`
- `last_reason`
- `execution_order`

## Gaps and Risks
1. 코어/운영 지시 경계가 일부 문서에서 중첩됨
2. 대형 단일 함수 중심 런타임으로 변경 파급이 커질 수 있음
3. simple-core 준수 여부를 CI에서 정량적으로 관리하지 않음

## Deepened Hardening Plan
### Phase 1: Instruction Layer Freeze (Core/Operating split)
목표:
- 코어 지시문을 invariant-only로 고정
- 운영 절차는 별도 playbook로 분리

작업:
1. `Core Instruction Pack` 단일 문서 신설(<= 60 lines 목표)
2. `AGENT-START`는 링크 허브/착수 절차만 유지
3. 상태/필드 정의의 canonical source를 계약 문서 1곳으로 통합

완료 기준:
- 코어 지시문 단일 파일에서 5개 불변원칙 확인 가능
- 중복 정의 제거로 필드 의미 drift 0건

### Phase 2: Runtime Core Simplification
목표:
- `issue_loop_runner.py`를 단계별 조립 구조로 분해

작업:
1. `main()` 책임을 `intake/select/execute/verify/feedback` 함수군으로 분리
2. 함수당 라인 수 상한 도입(soft limit 220)
3. stage별 contract test 추가

완료 기준:
- 최대 단일 함수 길이 <= 220 lines
- stage 단위 회귀 테스트 유지

### Phase 3: Simplicity Governance Gates
목표:
- 단순성 원칙을 운영 게이트에 포함

작업:
1. `simplicity-budget.json` 도입
2. CI에 complexity budget check 추가
3. 문서 중복 키(상태/필드) 탐지 스크립트 추가

완료 기준:
- complexity budget 위반 시 CI fail
- 핵심 필드 정의 중복 경고 자동화

### Phase 4: Revalidation by Simulation
목표:
- 단순화 후에도 loop 안정성과 판정 재현성을 유지

작업:
1. Track1/Track2 validation chain 재실행
2. failure/replan 시나리오 재주입
3. 이전 대비 운영 리스크/시간 비교

완료 기준:
- 기존 gate verdict 재현성 100% 유지
- 동일 실패 케이스 triage 시간 단축

## Acceptance Criteria
- [ ] Core instruction pack <= 60 lines
- [ ] AGENT start guide <= 90 lines
- [ ] 핵심 필드 정의 canonical source 1개로 수렴
- [ ] `issue_loop_runner.py` 최대 함수 길이 <= 220 lines
- [ ] 단순성 budget check CI fail-fast 동작 확인
- [ ] 기존 Track1/Track2 검증 체인 pass 유지

## Recommended Next Actions
1. `Phase 1`을 먼저 수행해 코어/운영 지시문 경계를 확정한다.
2. 이후 `Phase 2`로 런타임 구조 단순화를 진행한다.
3. 마지막으로 `Phase 3/4`로 단순성 게이트를 운영 체계에 내장한다.
