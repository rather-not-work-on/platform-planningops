---
title: audit: GitHub Adapter Baseline and Idempotency Replay
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Records REST/GraphQL smoke checks, idempotency replay convergence, and drift classification samples for issue #5.
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# audit: GitHub Adapter Baseline and Idempotency Replay

## Executed At (UTC)
`2026-02-28T05:10:52Z`

## Commands
- `python3 planningops/scripts/github_sync_adapter.py smoke --owner rather-not-work-on --project-num 2 --issue-num 5`
- `python3 planningops/scripts/github_sync_adapter.py replay-test`
- `python3 planningops/scripts/github_sync_adapter.py drift-sample`

## Smoke Output
```json
{
  "ok": true,
  "results": {
    "executed_at_utc": "2026-02-28T05:10:48.983672+00:00",
    "rest": {
      "rc": 0,
      "stdout": "{\"number\":5,\"state\":\"OPEN\",\"title\":\"Build GitHub sync adapter baseline with idempotency replay checks\"}",
      "stderr": ""
    },
    "graphql": {
      "rc": 0,
      "stdout": "{\"fields\":[{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBms\",\"name\":\"Title\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBmw\",\"name\":\"Assignees\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTSSF_lADOD8NujM4BQYNEzg-hBm0\",\"name\":\"Status\",\"options\":[{\"id\":\"f75ad846\",\"name\":\"Todo\"},{\"id\":\"47fc9ee4\",\"name\":\"In Progress\"},{\"id\":\"98236657\",\"name\":\"Done\"}],\"type\":\"ProjectV2SingleSelectField\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBm4\",\"name\":\"Labels\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBm8\",\"name\":\"Linked pull requests\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBnA\",\"name\":\"Milestone\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBnE\",\"name\":\"Repository\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBnM\",\"name\":\"Reviewers\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBnQ\",\"name\":\"Parent issue\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBnU\",\"name\":\"Sub-issues progress\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBrM\",\"name\":\"target_repo\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hBrQ\",\"name\":\"initiative\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTSSF_lADOD8NujM4BQYNEzg-hBsE\",\"name\":\"component\",\"options\":[{\"id\":\"1a47f1d9\",\"name\":\"planningops\"},{\"id\":\"ac884f5a\",\"name\":\"contracts\"},{\"id\":\"f6ceeede\",\"name\":\"provider-gateway\"},{\"id\":\"2a19b378\",\"name\":\"observability-gateway\"},{\"id\":\"d55bc97a\",\"name\":\"runtime\"},{\"id\":\"9233c6ef\",\"name\":\"orchestrator\"}],\"type\":\"ProjectV2SingleSelectField\"},{\"id\":\"PVTF_lADOD8NujM4BQYNEzg-hM3Y\",\"name\":\"execution_order\",\"type\":\"ProjectV2Field\"},{\"id\":\"PVTSSF_lADOD8NujM4BQYNEzg-hM3c\",\"name\":\"plan_lane\",\"options\":[{\"id\":\"c12b812b\",\"name\":\"M0 Bootstrap\"},{\"id\":\"0f566f80\",\"name\":\"M1 Contract Freeze\"},{\"id\":\"196964ba\",\"name\":\"M2 Sync Core\"},{\"id\":\"6b2c1c64\",\"name\":\"M3 Guardrails\"}],\"type\":\"ProjectV2SingleSelectField\"}],\"totalCount\":15}",
      "stderr": ""
    }
  }
}
```

## Replay Output
```json
{
  "executed_at_utc": "2026-02-28T05:10:51.001622+00:00",
  "first_apply_count": 2,
  "second_apply_count": 0,
  "duplicate_creation_rate": 0.0,
  "idempotent_convergence": true
}
```

## Drift Sample Output Path
`planningops/artifacts/drift/drift-sample-cases.json`

## Docs Check Output
```text
canonical check passed
workbench check passed
check passed for profile 'all'
```
