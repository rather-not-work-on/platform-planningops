# Worker Task Pack Contract

## Purpose
Define a deterministic execution bundle for a selected issue so Ralph Loop can run real worker commands with explicit safety and replay boundaries.

## Contract Object
Top-level key:
- `worker_task_pack`

Required fields:
1. `version` (string): contract version (`v1`)
2. `task_key` (string): runtime task key (e.g., `issue-42`)
3. `issue_number` (integer >= 1)
4. `mode` (enum): `dry-run|apply`
5. `loop_profile` (string): resolved loop profile label
6. `runtime_profile` (string): resolved runtime profile id
7. `worker_policy_kind` (enum): `parser_diff_dry_run|python_script|shell`
8. `command` (array of strings, min length 1): command to execute
9. `retry_policy.max_retries` (integer >= 0)
10. `timeout_ms` (integer >= 1)
11. `idempotency_key` (string): stable execution identity hash input

Optional:
- `target_repo` (string, `owner/repo`)
- `metadata` (object): auxiliary non-critical fields

## Determinism Rules
1. same `{task_key, issue_number, mode, worker_policy}` must produce same `command`.
2. `idempotency_key` must be derived from deterministic inputs only.
3. unresolved template placeholders must fail contract validation.

## Safety Rules
1. unknown `worker_policy_kind` is fail-fast.
2. empty command array is fail-fast.
3. non-positive timeout is fail-fast.

## Validation Requirements
Before loop execution:
1. `worker-task-pack.schema.json` validation pass
2. worker policy render pass (no missing template keys)
3. retry/timeout numeric domain checks pass

## Evidence Artifacts
- `planningops/artifacts/validation/worker-task-pack-issue-<issue_number>.json`
