# Failure Taxonomy and Retry Policy

## Failure Taxonomy
- `missing_input`: mandatory intake/context field missing
- `dependency_blocked`: `depends_on` unmet
- `permission_denied`: auth/token/app scope insufficient
- `verification_failed`: checklist or contract validation failed
- `feedback_failed`: issue/project update failed
- `idempotency_conflict`: duplicate key or replay mismatch
- `runtime_error`: unexpected local execution error

## Adapter Reason Mapping Standard
Adapter hook reason families are constrained to:
- `contract`
- `permission`
- `context`
- `runtime`
- `feedback_failed`

Mapping to loop failure taxonomy:
- `contract` -> `verification_failed`
- `permission` -> `permission_denied`
- `context` -> `missing_input`
- `runtime` -> `runtime_error`
- `feedback_failed` -> `feedback_failed`

Feedback failure handling rule:
- feedback 단계에서 project field/schema drift 또는 update 예외가 발생하면 프로세스 크래시 대신 `reason_code=feedback_failed`로 수렴하고, `last-run.json` 및 transition evidence를 반드시 남긴다.

## Retry Policy
- `missing_input`: no retry (requires human/doc update)
- `dependency_blocked`: no retry until dependency changes
- `permission_denied`: retry once after credential refresh, then stop
- `verification_failed`: no retry (requires patch change)
- `feedback_failed`: up to 3 retries with exponential backoff (5s, 15s, 45s)
- `idempotency_conflict`: retry once in read-only mode, then stop
- `runtime_error`: up to 2 retries, then mark `inconclusive`

## Escalation Rules
- same `reason_code` repeated 3 times for same issue => create follow-up issue
- `inconclusive` repeated 2 consecutive loops => force replan trigger
