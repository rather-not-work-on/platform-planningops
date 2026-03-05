---
title: audit: Track 1 Drift and Reconcile Policy
type: audit
date: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Completed drift signal catalog and reconcile fail-safe policy for loop profile selection and project schema validation.
---

# audit: Track 1 Drift and Reconcile Policy

## Scope
- `loop_profile` selector drift
- feedback field/schema drift fail-safe
- `workflow_state` and `loop_profile` compatibility drift
- reconcile and rollback trigger policy

## Regression Inputs
- `todos/008-complete-p2-loop-profile-l2-unreachable.md`
- `todos/009-complete-p2-loop-profile-field-drift-crash.md`
- `todos/010-complete-p3-loop-profile-validator-state-coverage-gap.md`

## Checklist
- [x] drift signals cataloged
- [x] fail-safe behavior documented
- [x] reconcile order documented
- [x] rollback trigger documented

## Drift Signals
- Selector signal missing:
  - `simulation_required`, `uncertainty_level` 누락/오해석
- Feedback update failure:
  - Project field 업데이트 예외 또는 schema drift
- Matrix coverage gap:
  - `workflow_state`별 `loop_profile` 허용 집합 누락

## Reconcile Policy
1. selector stage에서 contract signal 우선 해석
2. feedback 실패는 크래시 대신 `reason_code=feedback_failed`로 수렴
3. schema validator는 workflow-state matrix로 허용 프로필 검증
4. 증빙은 `last-run.json` + transition log + watchdog report에 저장

## Rollback and Replan Triggers
- `same_reason_x3` -> auto-pause + replan decision artifact
- `inconclusive_x2` -> auto-pause + replan decision artifact
- `dependency_blocked` 지속 -> `blocked` 유지 및 의존성 해소 후 재시도

## Evidence
- selector and fail-safe implementation:
  - `planningops/scripts/issue_loop_runner.py`
- workflow-state matrix validation:
  - `planningops/scripts/validate_project_field_schema.py`
- regression tests:
  - `bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
  - `bash planningops/scripts/test_validate_project_field_schema_matrix.sh`
- latest schema/gate reports:
  - `planningops/artifacts/validation/project-field-schema-report.json`
  - `planningops/artifacts/validation/track1-validation-chain-report.json`

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-03T06:31:50+00:00
