---
title: plan: Auto-Executable Plans Contract and Runner Pipeline
type: plan
date: 2026-03-03
updated: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines a machine-executable planning contract and runner pipeline so plans can be compiled, synced, and executed with minimal manual translation.
---

# plan: Auto-Executable Plans Contract and Runner Pipeline

## Idea Refinement Input
Found relevant brainstorm context (within 14 days):
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-02-uap-post-waveb-next-phase-brainstorm.md`
- `docs/workbench/unified-personal-agent-platform/brainstorms/2026-03-01-uap-loop-selection-policy-brainstorm.md`

Reused decisions:
- 운영 모델은 sprint가 아니라 비정기 Kanban pull
- loop profile(`L1~L5`)과 workflow_state를 계약으로 고정
- hard-gate 기반으로 구현 확장 시점 제어

## Research Consolidation
### Local Repo Research
- Existing plan-to-execution bridge already exists:
  - backlog bootstrap: `planningops/scripts/bootstrap_two_track_backlog.py`
  - loop runtime: `planningops/scripts/issue_loop_runner.py`
  - schema guard: `planningops/scripts/validate_project_field_schema.py`
- Existing validation evidence model:
  - `planningops/artifacts/validation/*`
- Existing human-readable plan is rich, but machine-ingest contract is partial.

### Learnings Research
- `docs/solutions/` entries are not present.
- Reused institutional signals from workbench plans/audits/contracts instead.

### External Research Decision
- Skipped for this pass.
- Reason: this work is internal contract/pipeline formalization with strong local patterns and active scripts.

## Issue Planning & Structure
- Issue type: `enhancement`
- Audience:
  - planning owner
  - execution agent runner
  - project operator
- Detail level: `A LOT`
- Why: 문서 계약, GitHub projection, runner behavior를 동시에 다뤄야 하므로 설계 모호성을 최소화해야 함.

## Overview
현재 계획 문서는 사람에게는 충분히 명확하지만, 에이전트가 자동 실행하기 위해서는 중간 변환(수동 해석)이 필요하다.

목표:
1. 계획 문서에서 machine-readable contract를 추출 가능하게 만든다.
2. 계획을 backlog issue/project card로 deterministic하게 컴파일한다.
3. 실행 결과를 계획 계약에 맞춰 자동 검증/피드백 동기화한다.

## Problem Statement
현재 리스크:
- 계획 섹션은 풍부하지만 실행 metadata는 문서별 형식 편차가 있다.
- runner가 이해하는 입력 형식(issue body metadata)과 원본 plan 섹션이 1:1 대응되지 않는다.
- 계획 변경 시 “컴파일 기준”이 명문화되지 않아 drift가 누적될 수 있다.

## Proposed Solution
`Plan Execution Contract (PEC v1)`를 도입한다.

핵심:
1. plan 문서에 고정된 machine block(`execution_contract`)을 둔다.
2. compiler가 `execution_contract`를 읽어 issue/project payload를 생성한다.
3. runner는 payload를 실행하고 결과를 증빙 아티팩트/프로젝트 필드로 반영한다.
4. verifier는 계약 누락/불일치 시 fail-fast 처리한다.

## Terminology and Field Canonicalization
### Terminology (fixed)
- `Planner`: plan 문서를 작성/갱신하는 주체
- `Compiler`: plan contract를 issue/project payload로 변환하는 주체
- `Runner`: Kanban pull로 issue를 실행하는 주체
- `Verifier`: 실행 결과를 verdict로 판정하는 주체
- External runtime term: `Executor`
- Internal runtime term: `Worker`

### Field Schema (must-use keys)
Issue metadata/compile payload는 아래 키를 고정 사용한다:
- `plan_item_id` (text, stable key)
- `execution_order` (number)
- `target_repo` (text, `owner/repo`)
- `component` (enum key): `planningops`, `contracts`, `provider_gateway`, `observability_gateway`, `runtime`, `orchestrator`
- `workflow_state` (enum key): `backlog`, `ready_contract`, `ready_implementation`, `in_progress`, `review_gate`, `blocked`, `done`
- `loop_profile` (enum key): `l1_contract_clarification`, `l2_simulation`, `l3_implementation_tdd`, `l4_integration_reconcile`, `l5_recovery_replan`
- `depends_on` (list[number], execution_order reference)
- `primary_output` (repo-relative path)

Path rule:
- 모든 경로는 repo root 기준 상대경로를 사용한다.
- absolute path는 금지한다.

## SpecFlow Analysis
### User Flow Overview
1. Planner가 plan 문서를 작성/수정한다.
2. Compiler가 plan에서 실행 카드(issues) 집합을 생성/동기화한다.
3. Runner가 eligible card를 Kanban pull로 실행한다.
4. Verifier가 verdict와 evidence를 생성한다.
5. Feedback sync가 issue/project를 업데이트한다.
6. Drift guard가 plan contract와 실제 projection 차이를 탐지한다.

### Flow Permutations Matrix
| Scenario | Input 상태 | Expected path | Output |
|---|---|---|---|
| 신규 계획 등록 | plan with valid PEC | compile -> issue create -> project sync | backlog seeded |
| 기존 계획 수정 | plan item changed | compile -> issue edit/re-sync | projection updated |
| 계약 누락 | invalid PEC | compile fail-fast | report + no mutation |
| 실행 실패 | runtime fail/inconclusive | verify -> blocked/replan | transition log + replan evidence |

### Missing Elements and Gap Closures
- Gap: plan 문서별 execution metadata 표현 형식 불균일
  - Closure: `execution_contract` schema 강제
- Gap: compile 결과와 project field mapping drift 탐지 불명확
  - Closure: compile report + schema verifier 연동
- Gap: plan 변경의 영향 범위 추적 부족
  - Closure: `plan_revision` + deterministic item key 도입

## Technical Approach
### A. Plan Execution Contract (PEC v1)
`docs/workbench/.../plans/*.md` 내 fixed block:

```yaml
execution_contract:
  plan_id: "uap-auto-exec-20260303"
  plan_revision: 1
  source_of_truth: "docs/workbench/unified-personal-agent-platform/plans/2026-03-03-plan-auto-executable-plans-contract-and-runner-plan.md"
  items:
    - plan_item_id: "pec-100"
      execution_order: 100
      title: "Define PEC schema and linter"
      target_repo: "rather-not-work-on/platform-planningops"
      component: "planningops"
      workflow_state: "ready_contract"
      loop_profile: "l1_contract_clarification"
      depends_on: []
      primary_output: "planningops/contracts/plan-execution-contract-v1.md"
      required_checks:
        - "uap-docs-profile-all"
        - "project-schema-validation"
```

### B. Compiler and Projection
Planned files:
- `planningops/schemas/plan-execution-contract.schema.json`
- `planningops/scripts/compile_plan_to_backlog.py`
- `planningops/scripts/test_compile_plan_to_backlog_contract.sh`

Compiler responsibilities:
1. parse PEC block
2. validate against schema
3. resolve deterministic key (`plan_item_id + target_repo`)
4. create/update issue metadata
5. sync project fields
6. write compile report artifact

### C. Runner Contract Alignment
Runner input stays issue-centric for now.

Compatibility policy:
- compiler output must keep current issue body fields:
  - `execution_order`, `depends_on`, `workflow_state`, `loop_profile`, `target_repo`, `primary_output`
- runner remains backward-compatible with pre-PEC issues during migration.

### D. Verification and Drift Guard
Planned files:
- `planningops/scripts/verify_plan_projection.py`
- `planningops/artifacts/validation/plan-projection-report.json`

Rules:
1. PEC required fields missing -> fail
2. project field mismatch with PEC -> fail (apply mode)
3. runner executed item without matching PEC source -> inconclusive + replan flag

## Implementation Phases
### Phase 1: Contract Freeze
Deliverables:
- `planningops/contracts/plan-execution-contract-v1.md`
- `planningops/schemas/plan-execution-contract.schema.json`
- plan template section for `execution_contract`

### Phase 2: Compiler MVP
Deliverables:
- `planningops/scripts/compile_plan_to_backlog.py`
- compile artifact: `planningops/artifacts/validation/plan-compile-report.json`
- contract test: `planningops/scripts/test_compile_plan_to_backlog_contract.sh`

### Phase 3: Projection Verifier
Deliverables:
- `planningops/scripts/verify_plan_projection.py`
- projection artifact: `planningops/artifacts/validation/plan-projection-report.json`

### Phase 4: Runner Integration
Deliverables:
- runner preflight PEC compatibility check
- migration mode (`legacy|hybrid|strict-pec`) flag

### Phase 5: Hard-Gate Rollout
Deliverables:
- CI wiring for compile/projection checks
- rollback guide for PEC strict mode

## Issue-Ready Backlog (PEC v1)
| execution_order | plan_item_id | title | component | target_repo | workflow_state | loop_profile | depends_on | primary_output |
|---|---|---|---|---|---|---|---|---|
| 300 | `pec-300` | Define PEC contract doc | `contracts` | `rather-not-work-on/platform-planningops` | `ready_contract` | `l1_contract_clarification` | - | `planningops/contracts/plan-execution-contract-v1.md` |
| 310 | `pec-310` | Add PEC schema | `contracts` | `rather-not-work-on/platform-planningops` | `ready_contract` | `l1_contract_clarification` | 300 | `planningops/schemas/plan-execution-contract.schema.json` |
| 320 | `pec-320` | Implement compile_plan_to_backlog | `planningops` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l3_implementation_tdd` | 310 | `planningops/scripts/compile_plan_to_backlog.py` |
| 330 | `pec-330` | Add compile contract test | `planningops` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l3_implementation_tdd` | 320 | `planningops/scripts/test_compile_plan_to_backlog_contract.sh` |
| 340 | `pec-340` | Implement projection verifier | `planningops` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l3_implementation_tdd` | 330 | `planningops/scripts/verify_plan_projection.py` |
| 350 | `pec-350` | Integrate runner preflight modes | `orchestrator` | `rather-not-work-on/platform-planningops` | `ready_implementation` | `l4_integration_reconcile` | 340 | `planningops/scripts/issue_loop_runner.py` |
| 360 | `pec-360` | Wire CI hard-gates for PEC | `planningops` | `rather-not-work-on/platform-planningops` | `review_gate` | `l4_integration_reconcile` | 350 | `.github/workflows/federated-ci-matrix.yml` |

## Pseudo Implementation Snippets
### `planningops/scripts/compile_plan_to_backlog.py`
```python
def compile_plan(plan_path: str) -> dict:
    doc = parse_markdown_with_yaml_block(plan_path, block_key="execution_contract")
    validate_schema(doc["execution_contract"], "planningops/schemas/plan-execution-contract.schema.json")
    rows = normalize_items(doc["execution_contract"]["items"])
    sync_result = project_and_issue_sync(rows)
    return build_report(plan_path, rows, sync_result)
```

### `planningops/scripts/verify_plan_projection.py`
```python
def verify_projection(plan_path: str, project_snapshot: dict) -> dict:
    expected = extract_expected_projection(plan_path)
    actual = build_actual_projection(project_snapshot)
    drift = diff_projection(expected, actual)
    verdict = "pass" if not drift else "fail"
    return {"verdict": verdict, "drift": drift}
```

## Acceptance Criteria
### Functional Requirements
- [ ] Plan with valid PEC compiles to issue/project payload without manual editing
- [ ] Same plan input generates deterministic compile output
- [ ] Project fields are synchronized from PEC values
- [ ] Runner executes compiled cards without metadata loss

### Non-Functional Requirements
- [ ] Compile runtime for 100 items <= 2 minutes
- [ ] Compile is idempotent across repeated runs
- [ ] Legacy plans remain executable in hybrid mode

### Quality Gates
- [ ] `uap-docs.sh check --profile all`
- [ ] PEC schema contract tests green
- [ ] projection verifier mismatch count = 0 in strict mode

## Success Metrics
- `manual_plan_to_issue_translation_steps`: 감소(목표 80% 이상)
- `projection_drift_incidents_per_week`: 감소(목표 <= 1)
- `compile_determinism_conflicts`: 0

## Dependencies and Risks
Dependencies:
- `planningops/config/project-field-ids.json` 안정성
- GitHub CLI token/project write access

Risks:
- 과도한 strict mode로 초기 계획 속도 저하
  - mitigation: `legacy|hybrid|strict-pec` 단계 rollout
- schema 버전 업 시 하위호환 부담
  - mitigation: `plan_revision`/compat matrix 운영

## References
### Internal References
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`
- `planningops/scripts/bootstrap_two_track_backlog.py`
- `planningops/scripts/issue_loop_runner.py`
- `planningops/contracts/requirements-contract.md`

### External References
- none for this pass

## Next Actions
1. PEC v1 schema + contract doc부터 먼저 고정
2. compiler MVP로 기존 two-track plan을 재컴파일해 동등성 확인
3. projection verifier를 CI hard gate에 연결
