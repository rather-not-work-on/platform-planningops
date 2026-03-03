# planningops/fixtures

## Purpose
Provide deterministic sample inputs for contract and loop verification tests.

## Contents
- `contracts/`: valid schema fixture payloads (C1~C5)
- `plan-items/`: valid/invalid planning item sample sets
- `track1-kpi-baseline-ci.json`: strict gate KPI baseline input

## Change Rules
- Fixtures must be static and deterministic.
- Runtime-generated artifacts must not be committed under fixtures.
- Invalid fixtures should represent a single failure cause to keep tests readable.

