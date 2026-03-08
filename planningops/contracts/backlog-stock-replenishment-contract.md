# Backlog Stock and Replenishment Contract

## Goal
Keep autonomous Kanban execution stable by enforcing queue stock floors and evidence-backed replenishment quality.

## Queue Classes
Three queue classes are mandatory:
1. `ready_now`: executable now (`Todo` + `ready-*` + `execution_kind=executable` + no open dependency blocker)
2. `next_up`: near-ready (`Todo` + `ready-*` + `execution_kind=executable` + dependency blocker exists)
3. `quality_hardening`: executable contract/test/governance hardening queue

Closed issues are never counted as stock, even if stale project fields still show `Todo` or `ready-*`.
Inventory cards are never counted as stock, even when they remain open for audit or replenishment bookkeeping.

## Execution Kind Semantics
- Issue body metadata may declare `execution_kind`.
- Allowed values:
  - `executable` (default when omitted)
  - `inventory`
- `inventory` means the issue exists to preserve queue memory, replenishment history, or bookkeeping state. It is not eligible for stock floors or live pull selection.

Stock floor source:
- `planningops/config/backlog-stock-policy.json`

## High-Value Pull Rule
- Intake must apply `high_value_ready_first`.
- Selection target is always the smallest `(execution_order, issue_number)` inside `ready_now`.
- `backlog`/non-ready cards cannot preempt a `ready_now` candidate even when they have smaller `execution_order`.
- `execution_kind=inventory` cards must be skipped before dependency and blueprint checks.

## Replenishment Gate
New follow-up backlog candidates must be evidence-backed and normalized before queue insertion.

Required candidate fields:
1. `title`
2. `evidence_refs` (one or more artifact refs)
3. `depends_on` (field required; empty list allowed only when explicitly independent)
4. `acceptance_criteria` (non-empty checklist)

Candidate normalization output must include:
- deterministic `candidate_id`
- baseline issue body template with:
  - `execution_kind`
  - `depends_on`
  - checklist-style acceptance criteria
  - evidence references section

## Gate Behavior
- Stock gate fails when any queue class is below `min_stock`.
- Replenishment gate fails when any candidate misses required fields.
- Report-only mode is allowed for observation runs, but strict mode is required for CI/contract validation.

## Artifacts
- Policy config:
  - `planningops/config/backlog-stock-policy.json`
- Validation report:
  - `planningops/artifacts/validation/backlog-stock-report.json`
- Runner replenishment candidate artifact:
  - `planningops/artifacts/backlog/issue-<n>-replenishment-candidates.json`

## Testability Mapping
- stock/replenishment validation implementation:
  - `planningops/scripts/backlog_stock_replenishment_guard.py`
- high-value-ready selection enforcement:
  - `planningops/scripts/issue_loop_runner.py`
- regression:
  - `planningops/scripts/test_backlog_stock_replenishment_contract.sh`
  - `planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
