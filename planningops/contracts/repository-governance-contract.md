# Repository Governance Contract

## Purpose
Define a federated baseline for default-branch protection so merge quality is deterministic across control-plane and execution repos.

## Scope
- Control repository: `rather-not-work-on/platform-planningops`
- Governed repositories:
  - `rather-not-work-on/platform-planningops`
  - `rather-not-work-on/platform-contracts`
  - `rather-not-work-on/monday`
  - `rather-not-work-on/platform-provider-gateway`
  - `rather-not-work-on/platform-observability-gateway`

## Baseline Requirements
Per governed repo default branch:
1. Branch protection rule must exist for default branch pattern.
2. Pull request reviews must be required.
3. Minimum approving review count must be met.
4. Status checks must be required.
5. Strict status checks must be enabled.
6. Conversation resolution must be required.
7. Force pushes and deletions must be disabled.
8. Required status checks must satisfy repo-specific policy (`all` and/or `any` sets).
9. Branch-protection-required checks must be emitted on every pull request for that repo. Path-filtered checks cannot be marked as required unless the workflow still produces the context for all PRs.

## Source of Truth
- Policy config: `planningops/config/repository-governance-policy.json`

## Verification
- Audit script: `planningops/scripts/audit_branch_protection.py`
- Contract test: `planningops/scripts/test_audit_branch_protection_contract.sh`
- Report output (default): `planningops/artifacts/validation/branch-protection-audit-report.json`

## Operational Notes
- `--strict` mode fails when baseline violations are found.
- `--allow-fetch-failure` turns fetch errors into `inconclusive` (soft-fail only when strict mode is also enabled).
- Live apply uses `planningops/scripts/apply_branch_protection.py` and expects concrete `required_status_checks_all` values in policy.
