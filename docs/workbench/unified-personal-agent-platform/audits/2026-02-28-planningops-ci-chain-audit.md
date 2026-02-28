---
title: audit: PlanningOps CI Chain Validate-Contracts to Dry-Run
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures local-equivalent execution logs for the required CI chain validate-contracts to dry-run and artifact generation for issue #12.
---

# audit: PlanningOps CI Chain Validate-Contracts to Dry-Run

## Executed At (UTC)
2026-02-28T05:13:25Z

## Workflow File
.github/workflows/planningops-contracts-dryrun.yml

## Required Chain
1. validate C1-C5 contracts
2. run parser diff dry-run
3. upload dry-run artifacts

## Local Equivalent Results
~~~text
python3 planningops/scripts/validate_contracts.py
=> validation passed: all C1~C5 fixtures are valid

python3 planningops/scripts/parser_diff_dry_run.py --run-id local-ci-dry-run --mode dry-run
=> summary written: planningops/artifacts/sync-summary/local-ci-dry-run.json
~~~

## Expected Workflow Artifacts
- planningops/artifacts/sync-summary/ci-dry-run.json
- planningops/artifacts/idempotency/ledger.json

## Local Validation
~~~text
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
=> canonical check passed
=> workbench check passed
=> check passed for profile all
~~~
