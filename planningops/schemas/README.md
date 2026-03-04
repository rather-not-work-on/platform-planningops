# planningops/schemas

## Purpose
Keep local schema copies used for contract validation fixtures and compatibility checks.

## Contents
- `c1-run-lifecycle.schema.json`
- `c2-subtask-handoff.schema.json`
- `c3-executor-result.schema.json`
- `c4-provider-invocation.schema.json`
- `c5-observability-event.schema.json`
- `plan-execution-contract.schema.json`
- `meta-plan-graph.schema.json`
- `worker-task-pack.schema.json`

## Change Rules
- Schema shape changes must be synchronized with `platform-contracts` source schemas.
- Fixture samples under `planningops/fixtures/contracts` must remain valid after updates.
- Breaking changes require contract compatibility review evidence.
