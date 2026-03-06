# Issue Label Taxonomy Contract

## Purpose
Keep backlog issues machine-classifiable for scheduling, reporting, and loop automation.

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Applies to issues containing `plan_item_id:` in body.

## Required Labels
Each in-scope issue must satisfy all rules:
1. Include `task`.
2. Include exactly one priority label:
   - `p1` | `p2` | `p3`
3. Include at least one `area/` label:
   - examples: `area/planningops`, `area/contracts`, `area/ci`, `area/artifacts`, `area/quality`
4. Include at least one `type/` label:
   - examples: `type/hardening`, `type/governance`

## Enforcement Path
1. Issue template default label:
   - `.github/ISSUE_TEMPLATE/planningops-task.yml` -> `task`
2. Validator:
   - `planningops/scripts/validate_issue_quality.py`
3. Rules:
   - `planningops/config/issue-quality-rules.json`
4. CI gates:
   - issue event gate: `.github/workflows/issue-quality-gate.yml`
   - PR/federated gate: `.github/workflows/federated-ci-matrix.yml` (`loop-guardrails`)

## Backfill Policy
- Existing open in-scope issues must be backfilled to satisfy required labels.
- Backfill evidence is recorded in:
  - `planningops/artifacts/validation/issue-label-backfill-report.json`
