---
title: audit: Infra Local and OCI Profile Boundary Map
type: audit
date: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines local-first runtime boundaries, OCI migration triggers, and profile-level guardrails for Track 2.
---

# audit: Infra Local and OCI Profile Boundary Map

## Objective
LiteLLM/LangFuse/NanoClaw 인프라를 `local` 기본값으로 유지하면서 OCI 이행 경계를 명확히 고정한다.

## Source Config
- `planningops/config/runtime-profiles.json`
- `planningops/config/ready-implementation-blueprint-defaults.json`

## Profile Matrix
| profile | execution_mode | LiteLLM | LangFuse | NanoClaw | usage policy |
|---|---|---|---|---|---|
| `local` | `local` | `http://127.0.0.1:4000` | `http://127.0.0.1:3001` | `http://127.0.0.1:8787` | default for all tasks |
| `oracle_cloud` | `hybrid` | `https://litellm.example.oracle.cloud` | `https://langfuse.example.oracle.cloud` | `https://nanoclaw.example.oracle.cloud` | scoped migration only |

## Boundary Rules
1. Contract shape는 profile 전환 전후 동일해야 한다.
2. 기본 실행은 `task_overrides.default.runtime_profile=local`을 유지한다.
3. OCI 전환은 task 단위 override로만 허용한다.
4. profile 전환 시 evidence 경로와 gate 산출물 형식은 변경하지 않는다.

## Migration Triggers (Local -> OCI)
- local latency/availability가 SLO를 반복 위반할 때
- 특정 task가 local resource limit를 지속 초과할 때
- 보안/네트워크 정책상 cloud endpoint가 필요할 때

## Migration Procedure
1. `profiles.oracle_cloud` endpoint/credential 유효성 점검
2. 대상 task만 `task_overrides.issue-<n>.runtime_profile=oracle_cloud`로 전환
3. dry-run loop로 산출물/필드 동기화 검증
4. 회귀 시 즉시 `local`로 롤백

## Rollback Triggers
- provider invocation 실패율 급증
- observability ingest 지연 임계치 초과
- transition log/replan artifact 누락

## Validation Evidence
- config inspection: `planningops/config/runtime-profiles.json`
- profile switch contract: `planningops/README.md` (`Local -> Oracle Cloud Migration`)
- schema check: `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch`

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-03T16:10:20+09:00
