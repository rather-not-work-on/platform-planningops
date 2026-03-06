---
module: PlanningOps
date: 2026-03-05
problem_type: workflow_issue
component: tooling
symptoms:
  - "GitHub Project cards could drift from issue metadata for plan_lane/workflow_state/component."
  - "A00 program skeleton had no machine-readable manifest artifact for deterministic Kanban pull."
  - "Issue evidence comments were error-prone when shell interpolation mixed with inline backticks."
root_cause: missing_tooling
resolution_type: workflow_improvement
severity: medium
tags: [planningops, kanban-pull, project-field-sync, program-manifest, issue-driven-execution]
---

# Troubleshooting: A00 Kanban Pull Baseline (Field Sync + Program Manifest)

## Problem

Issue-driven execution was running, but the control-tower baseline had two reliability gaps: Project field drift after issue creation and missing machine-readable program manifest for A00 acceptance.

## Environment

- Module: PlanningOps (control tower)
- Affected Component: tooling / orchestration workflow
- Date solved: 2026-03-05
- Initiative: `unified-personal-agent-platform`

## Symptoms

- Project card fields (`plan_lane`, `workflow_state`, `component`) were not guaranteed immediately after issue creation/update.
- A00 acceptance required `program-manifest.json`, but no builder/validator existed.
- Commenting evidence with inline command substitution caused corrupted issue comments.

## What Didn't Work

**Attempted Solution 1:** Manual per-issue field edits in GitHub Project.  
- **Why it failed:** Non-deterministic and easy to miss; repeated drift was likely during bulk issue generation.

**Attempted Solution 2:** Issue body normalization only.  
- **Why it failed:** Body values and Project field values can diverge without explicit project `item-edit` sync.

**Attempted Solution 3:** Inline `gh issue comment --body "..."` containing backticks.  
- **Why it failed:** Shell interpolation polluted comment content; evidence links became malformed.

## Solution

### Improved Parts (Completed)

1. Added post-create Project field sync automation:
- `planningops/scripts/sync_project_fields_after_issue_create.py`
- Sync target: `plan_lane`, `workflow_state`, `component` (plus `status`, `initiative`, `target_repo`, `execution_order`, `loop_profile`)
- Applied to all PO-CT cards (`A00~A44`, `B10~B50`, `C90`) with zero mismatch.

2. Strengthened compile path for lane sync:
- `planningops/scripts/compile_plan_to_backlog.py`
- Added `plan_lane` enum validation and project write path (when lane exists).

3. Implemented A00 artifact builder and validator:
- `planningops/scripts/build_program_manifest.py`
- Output: `planningops/artifacts/program/program-manifest.json`
- Validation report: `planningops/artifacts/validation/program-manifest-report.json`
- A00 (`#94`) closed after evidence linkage and checklist completion.

4. Stabilized operational command hygiene:
- For issue comments with markdown/code refs, use `--body-file` instead of inline literal bodies.

### Improve Later (Backlog)

- `035-pending-p2-compile-plan-lane-not-enforced.md`
  - Gap: `plan_lane` is still optional in PEC required keys; full guarantee not yet hard-enforced.
- `036-pending-p2-program-manifest-all-state-duplicate-risk.md`
  - Gap: manifest builder scans `state=all` and can break with future duplicate historical keys.

## Why This Works

1. A single source of truth is enforced twice:
- Issue body metadata encodes execution contract.
- Project fields are synchronized explicitly from that metadata.

2. A00 is no longer narrative-only:
- Manifest builder materializes active execution graph (`24` items, ordered, dependency-validated).
- Validation report provides strict pass/fail evidence for gate decisions.

3. Kanban pull progression becomes deterministic:
- After A00 is marked `done`, runner selection naturally moves to A10 under the same field contract.

## Prevention

- Always run post-create field sync after issue generation or metadata changes.
- Require evidence artifacts for gate cards before close (`manifest/report`, conformance outputs, etc.).
- Use file-based comment payloads (`--body-file`) for any multi-line markdown with code/backticks.
- Keep unresolved consistency gaps in todo backlog with explicit acceptance criteria and ownership.

## Lessons Learned

- Metadata standardization alone is insufficient; projection synchronization is equally critical.
- Early control-plane artifacts (like A00 manifest) reduce ambiguity and downstream loop noise.
- Small shell hygiene mistakes can corrupt governance evidence; safer command patterns should be policy.
- Review-created todos are valuable when they encode concrete contract gaps, not generic refactor wishes.

## Reusable Checklist (Next Runs)

- [ ] Create/update issue with full Planning Context metadata.
- [ ] Run field sync script and verify Project projection.
- [ ] Generate/update required gate artifact(s).
- [ ] Attach evidence to tracker and source issue.
- [ ] Transition issue body checklist + workflow_state before close.
- [ ] Re-run next-card intake dry-run to confirm pull continuity.

## Related Issues

- A00 completion: https://github.com/rather-not-work-on/platform-planningops/issues/94
- Tracker: https://github.com/rather-not-work-on/platform-planningops/issues/92
- Follow-up gap 1: `todos/035-pending-p2-compile-plan-lane-not-enforced.md`
- Follow-up gap 2: `todos/036-pending-p2-program-manifest-all-state-duplicate-risk.md`
