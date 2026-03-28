# planningops/fixtures

## Purpose
Provide deterministic sample inputs for contract and loop verification tests.

## Contents
- `contracts/`: valid schema fixture payloads (C1~C5)
- `plan-items/`: valid/invalid planning item sample sets
- `plan-execution-contract-sample.json`: minimal valid PEC v1 sample
- `plan-compile-sample-issues.json`: deterministic offline issues input for compile sample artifact lanes
- `backlog-materialization-sample-contract.json`: ready-implementation PEC sample for offline backlog materialization tests
- `backlog-materialize-*.expected.json`: normalized expected outputs for the offline backlog materialize sample lane
- `plan-projection-snapshot-sample.json`: sample project snapshot matching PEC sample
- `meta-plan-graph-sample.json`: minimal valid MPG v1 graph sample
- `worker-task-pack-sample.json`: minimal valid worker task pack sample
- `track1-kpi-baseline-ci.json`: strict gate KPI baseline input
- `backlog-stock-items-sample.json`: normalized project-item sample for stock gate checks
- `backlog-replenishment-candidates-sample.json`: evidence-backed replenishment candidate sample
- `supervisor-loop-sequence-sample.json`: deterministic loop-result sequence for supervisor contract tests
- `repository-governance-policy.sample.json`: fixture-backed repository governance policy for branch protection audit tests
- `branch-protection-snapshot-*.sample.json`: valid and invalid branch protection snapshots for repository governance audit tests
- `repository-governance-apply-policy*.sample.json`: valid and invalid repository governance policies for branch protection apply tests
- `branch-protection-apply-snapshot.sample.json`: minimal apply snapshot for branch protection apply tests
- `artifact-storage-policy-invalid.sample.json`: invalid artifact storage policy fixture for validator contract and artifact-lane tests
- `external-only-commit-guard-*.sample.txt`: allowed and blocked file lists for commit guard validator tests
- `external-only-commit-guard-policy.sample.json`: tracked-mode policy fixture for commit guard and migration tests
- `federated-issue-quality-*.sample.json`: config, valid issue set, and invalid issue set for federated label-quality tests

## Change Rules
- Fixtures must be static and deterministic.
- Runtime-generated artifacts must not be committed under fixtures.
- Invalid fixtures should represent a single failure cause to keep tests readable.
