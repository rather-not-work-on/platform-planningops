---
title: audit: C1-C5 Schema Validation Baseline
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures C1-C5 schema validation CLI output and Gate A/E/F baseline evidence for issue #3.
---

# audit: C1-C5 Schema Validation Baseline

## Executed At (UTC)
`2026-02-28T05:05:20Z`

## Contract Validation Command
`python3 planningops/scripts/validate_contracts.py`

## Contract Validation Output
```text
[PASS] c1-run-lifecycle.schema.json <- c1-run-lifecycle.valid.json
[PASS] c2-subtask-handoff.schema.json <- c2-subtask-handoff.valid.json
[PASS] c3-executor-result.schema.json <- c3-executor-result.valid.json
[PASS] c4-provider-invocation.schema.json <- c4-provider-invocation.valid.json
[PASS] c5-observability-event.schema.json <- c5-observability-event.valid.json
validation passed: all C1~C5 fixtures are valid
```

## Gate Baseline Evidence
- Gate A (contract baseline): schema files + compatibility report committed
- Gate E (evidence quality precondition): C3 evidence schema validates strong/weak enum
- Gate F (idempotency baseline): C1/C2 require idempotency key fields

## Docs Consistency Check Command
`bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`

## Docs Check Output
```text
canonical check passed
workbench check passed
check passed for profile 'all'
```

## Evidence Files
- `planningops/schemas/c1-run-lifecycle.schema.json`
- `planningops/schemas/c2-subtask-handoff.schema.json`
- `planningops/schemas/c3-executor-result.schema.json`
- `planningops/schemas/c4-provider-invocation.schema.json`
- `planningops/schemas/c5-observability-event.schema.json`
- `planningops/contracts/compatibility-report.md`
