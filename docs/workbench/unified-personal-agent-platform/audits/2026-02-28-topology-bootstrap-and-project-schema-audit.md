---
title: audit: Topology Bootstrap and Project Schema Guard
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Records issue #14 and #15 completion evidence for cross-repo topology bootstrap and GitHub Project field schema guard validation.
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# audit: Topology Bootstrap and Project Schema Guard

## Scope
- Issue #14: Bootstrap cross-repo topology for contracts/provider/o11y surfaces
- Issue #15: Harden GitHub Project field schema v2 for component/repo/initiative guards

## Repository Bootstrap Verification
Command:
```bash
gh repo list rather-not-work-on --limit 100 --json nameWithOwner,isPrivate,url \
  | jq -r '.[] | select(.nameWithOwner|test("platform-contracts|platform-provider-gateway|platform-observability-gateway")) | [.nameWithOwner,(if .isPrivate then "private" else "public"),.url] | @tsv'
```

Observed:
```text
rather-not-work-on/platform-observability-gateway    public
rather-not-work-on/platform-provider-gateway         public
rather-not-work-on/platform-contracts                public
```

## Project Field Guard Validation
Command:
```bash
python3 planningops/scripts/validate_project_field_schema.py \
  --owner rather-not-work-on \
  --project-num 2 \
  --config planningops/config/project-field-ids.json \
  --initiative unified-personal-agent-platform \
  --output planningops/artifacts/validation/project-field-schema-report.json \
  --fail-on-mismatch
```

Observed:
```text
report written: planningops/artifacts/validation/project-field-schema-report.json
evaluated_items=25 violation_count=0 verdict=pass
```

## Replay Idempotency Check
Command:
```bash
python3 planningops/scripts/github_sync_adapter.py replay-test
```

Observed:
```json
{
  "duplicate_creation_rate": 0.0,
  "idempotent_convergence": true
}
```

## Gate A Pre-check
Command:
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
```

Observed:
```text
canonical check passed
workbench check passed
check passed for profile 'all'
```

## Evidence
- `planningops/adr/adr-0003-cross-repo-topology-bootstrap.md`
- `planningops/quality/topology-bootstrap-checklist.md`
- `planningops/config/project-view-conventions.md`
- `planningops/scripts/validate_project_field_schema.py`
- `planningops/artifacts/validation/project-field-schema-report.json`
