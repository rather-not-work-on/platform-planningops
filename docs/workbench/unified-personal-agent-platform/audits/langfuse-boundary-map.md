---
title: audit: LangFuse Integration Boundary Map
type: audit
date: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Freezes LangFuse integration boundaries across monday, observability gateway, and planningops runtime evidence.
---

# audit: LangFuse Integration Boundary Map

## Objective
LangFuse 연동 경계를 고정해 Track 2 prototype 단계에서 관측 계약 드리프트를 차단한다.

## Integration Surface
- producer: `rather-not-work-on/monday`
- gateway: `rather-not-work-on/platform-observability-gateway`
- sink/consumer: LangFuse endpoint (`local` or `oracle_cloud`)
- verifier: `planningops/scripts/verify_loop_run.py`

## Boundary Contract
1. run/span/event payload는 C5 observability 계약을 따른다.
2. monday는 raw LangFuse SDK 세부를 직접 노출하지 않는다.
3. gateway는 ingest/replay/dedupe 책임을 소유한다.
4. planningops는 verdict 판정에 필요한 최소 추적 필드만 해석한다.

## Required Event Fields
- `trace_id`
- `span_id`
- `parent_span_id`
- `run_id`
- `event_type`
- `event_time`
- `delivery_status`
- `delivery_attempt`

Reference:
- `planningops/schemas/c5-observability-event.schema.json`

## Local and OCI Boundary
- Local baseline: `langfuse_host=http://127.0.0.1:3001`
- OCI migration target: `langfuse_host=https://langfuse.example.oracle.cloud`
- profile switch는 runtime profile만 변경하고 이벤트 계약은 유지한다.

## Failure Handling Contract
- LangFuse down 시 run 수행은 중단하지 않는다.
- delivery 실패는 `delivery_status`와 retry evidence로 기록한다.
- replay 수행 후 dedupe 결과를 gateway 산출물로 남긴다.

## Validation Evidence
- schema source: `planningops/schemas/c5-observability-event.schema.json`
- adapter boundary baseline:
  - `docs/workbench/unified-personal-agent-platform/audits/2026-02-28-provider-and-observability-gateway-bootstrap-audit.md`
- loop verifier contract:
  - `planningops/scripts/verify_loop_run.py`
- docs/schema checks:
  - `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
  - `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch`

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-03T16:10:40+09:00
