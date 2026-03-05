# planningops/fixtures

## Purpose
Provide deterministic sample inputs for contract and loop verification tests.

## Contents
- `contracts/`: valid schema fixture payloads (C1~C5)
- `plan-items/`: valid/invalid planning item sample sets
- `plan-execution-contract-sample.json`: minimal valid PEC v1 sample
- `plan-projection-snapshot-sample.json`: sample project snapshot matching PEC sample
- `meta-plan-graph-sample.json`: minimal valid MPG v1 graph sample
- `worker-task-pack-sample.json`: minimal valid worker task pack sample
- `track1-kpi-baseline-ci.json`: strict gate KPI baseline input
- `backlog-stock-items-sample.json`: normalized project-item sample for stock gate checks
- `backlog-replenishment-candidates-sample.json`: evidence-backed replenishment candidate sample

## Change Rules
- Fixtures must be static and deterministic.
- Runtime-generated artifacts must not be committed under fixtures.
- Invalid fixtures should represent a single failure cause to keep tests readable.
