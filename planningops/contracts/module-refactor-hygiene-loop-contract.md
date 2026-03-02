# Module Refactor Hygiene Loop Contract

## Purpose
Define a bounded, repeatable refactor loop that keeps module topology clean without triggering context pollution or over-engineering.

## Scope
- Unit of work: module-level (not whole-repo rewrite).
- Mode: analysis + prioritized queue generation by default.
- Execution order is fixed:
  1. external dependency cleanup
  2. internal dependency cleanup
- Single-repo and multi-repo operation must produce the same queue semantics.

## Invariants
1. External dependencies must be audited before internal dependency rewiring.
2. Every cycle must respect a hard scope budget (`max_modules_per_cycle`, `max_files_per_module`).
3. Mid-cycle housekeeping checkpoints are mandatory.
4. Refactor proposals must preserve behavior and record interface deltas.
5. Legacy removal is allowed only when replacement path and compatibility impact are explicit.

## Required Inputs
- `policy_file` (JSON):
  - `scan_roots`
  - `include_extensions`
  - `exclude_dirs`
  - `max_modules_per_cycle`
  - `max_files_per_module`
  - `checkpoint_every_tasks`
- multi-repo mode:
  - `multi_repo_config` (JSON)
  - `workspace_root`
  - shared policy + per-repo policy overrides

## Required Outputs
- `report.json`:
  - module topology (`internal_dependencies`, `external_dependencies`, cycle info)
  - prioritized queues (`external_first`, `internal_next`, `execution_order`)
  - checkpoint plan
- `summary.md`:
  - concise queue view and checkpoint placement
- `latest.json` pointer
- multi-repo mode:
  - `aggregate.json` with per-repo pass/fail and queue contract checks
  - `summary.md` with cross-repo ordering and next actions

## Guardrails
- If no sources are discoverable, fail fast.
- Parse errors must be reported, not ignored.
- Queue generation must remain deterministic for same input snapshot.
- Internal cleanup queue cannot appear before external cleanup queue.
- Any repo that violates queue ordering contract must be marked failed in aggregate result.

## Done Criteria
- Topology report generated.
- External-first/internal-next queue generated with explicit limits.
- Checkpoint actions generated for context cleanup.
