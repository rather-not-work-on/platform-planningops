---
title: audit: Parser Diff Dry-Run Pipeline Baseline
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures parser->diff->dry-run execution logs, determinism check, and failure-case validation for issue #4.
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# audit: Parser Diff Dry-Run Pipeline Baseline

## Executed At (UTC)
`2026-02-28T05:08:24Z`

## Run Commands
- `python3 planningops/scripts/parser_diff_dry_run.py --run-id deterministic-a --mode dry-run`
- `python3 planningops/scripts/parser_diff_dry_run.py --run-id deterministic-b --mode dry-run`
- `bash planningops/scripts/test_parser_diff_dry_run.sh`

## Output Summary
```text
summary written: planningops/artifacts/sync-summary/deterministic-a.json
counts create=20 update=0 noop=0
summary written: planningops/artifacts/sync-summary/deterministic-b.json
counts create=20 update=0 noop=0
parser-diff-dry-run tests passed
determinism check passed
```

## Failure Cases Verified
- missing required field fixture fails
- invalid enum fixture fails

## Artifact Format
- sync summary path: `planningops/artifacts/sync-summary/<run_id>.json`
- sample output files:
  - `planningops/artifacts/sync-summary/deterministic-a.json`
  - `planningops/artifacts/sync-summary/deterministic-b.json`

## Docs Check Output
```text
canonical check passed
workbench check passed
check passed for profile 'all'
```
