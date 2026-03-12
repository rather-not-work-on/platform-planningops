# Backlog Materialization Contract

## Purpose
Provide one recurring control-plane command that materializes executable backlog from an execution contract without relying on ad hoc shell choreography.

## Canonical Entrypoint
- `planningops/scripts/core/backlog/materialize.py`

## Required Sequence
1. Compile issue/project mutations from the execution contract.
2. In dry-run mode, project deterministic local issues from the execution contract and use them as the offline input set for downstream steps.
3. Backfill required issue labels against the active issue input set.
4. Rebuild the program manifest from the active issue input set.
5. Re-validate PlanningOps issue quality against the active issue input set.

## Execution Rules
- The command must accept an explicit execution contract file.
- Dry-run mode must preserve the full command plan without GitHub mutations.
- Dry-run mode must not require pre-existing live GitHub issues for the selected plan.
- Apply mode may use live GitHub issues, but only through the existing helper scripts.
- Apply mode must pass through issue creation/reopen behavior only via existing helper scripts.
- Apply mode must preflight exact closed matches and fail before creating duplicate issues from an exhausted execution contract unless `--allow-reopen-closed` is explicit.
- The runner must emit a deterministic JSON report under `planningops/artifacts/backlog/`.
- Dry-run mode must emit a projected issues artifact under `planningops/artifacts/backlog/`.

## Failure Rules
- Fail fast on the first step that returns non-zero.
- Preserve each executed step command, rc, and truncated stdout/stderr in the report.
- Do not invent fallback mutations outside the composed helper scripts.

## Validation
- `planningops/scripts/test_backlog_materialization_contract.sh`
