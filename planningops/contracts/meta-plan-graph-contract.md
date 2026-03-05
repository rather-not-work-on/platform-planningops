# Meta Plan Graph Contract (MPG v1)

## Purpose
Define a deterministic plan-of-plans contract so multiple execution plans can be orchestrated as one graph with explicit dependency, gate, and replan policies.

## Contract Object
Top-level key:
- `meta_plan_graph`

Required fields:
1. `meta_plan_id` (string): stable graph identity
2. `graph_revision` (integer >= 1): revision for drift tracking
3. `source_of_truth` (string): repo-relative plan path
4. `initiative` (string): initiative key
5. `nodes` (array): executable plan nodes
6. `edges` (array): directed relations between nodes

## Node Schema
Each node must include:
- `node_id` (string, unique)
- `plan_path` (string, repo-relative path)
- `execution_order` (integer >= 1, unique)
- `target_repo` (string, `owner/repo`)
- `component` (enum key):
  - `planningops`
  - `contracts`
  - `provider_gateway`
  - `observability_gateway`
  - `runtime`
  - `orchestrator`
- `workflow_state` (enum key):
  - `backlog`
  - `ready_contract`
  - `ready_implementation`
  - `in_progress`
  - `review_gate`
  - `blocked`
  - `done`
- `loop_profile` (enum key):
  - `l1_contract_clarification`
  - `l2_simulation`
  - `l3_implementation_tdd`
  - `l4_integration_reconcile`
  - `l5_recovery_replan`
- `status` (enum key):
  - `draft`
  - `ready`
  - `in_progress`
  - `review_gate`
  - `blocked`
  - `replan_required`
  - `done`

Optional:
- `owner` (string)
- `notes` (string)

## Edge Schema
Each edge must include:
- `from` (string, existing `node_id`)
- `to` (string, existing `node_id`)
- `type` (enum):
  - `depends_on`
  - `blocks`
  - `supersedes`

Rules:
1. `depends_on` and `blocks` subgraphs must be acyclic.
2. Duplicate edges (`from,to,type`) are not allowed.
3. Self-edge (`from == to`) is not allowed.

## Canonical Field Policy
The graph contract is projection-aligned with issue/project fields.

Required canonical keys per node:
- `initiative`
- `target_repo`
- `component`
- `execution_order`
- `workflow_state`
- `loop_profile`
- `last_verdict`
- `last_reason`

Key policy:
- internal keys: `snake_case`
- project display labels: existing single-select display values

## Ready Set Policy
A node is eligible for pull when all conditions are true:
1. `status == ready`
2. all inbound `depends_on` source nodes are `done`
3. no inbound `blocks` source node is in `{in_progress, review_gate, blocked, replan_required}`
4. policy-level WIP cap is not exceeded

## Transition Contract
Allowed node status transitions:
1. `draft -> ready`
2. `ready -> in_progress`
3. `in_progress -> review_gate`
4. `review_gate -> done`
5. `in_progress|review_gate -> blocked`
6. `blocked -> ready` (only after dependency recovery + drift=0 evidence)
7. `in_progress|review_gate|blocked -> replan_required` (escalation trigger)

Escalation trigger contract:
- `same_reason_x3` or `inconclusive_x2` must transition to `replan_required`

## Determinism Rules
1. `node_id` is immutable once published.
2. same graph input must yield same ready set output.
3. graph projection key is `initiative + node_id + target_repo`.

## Validation Requirements
Before orchestration apply mode:
1. schema validation pass (`planningops/schemas/meta-plan-graph.schema.json`)
2. node/edge uniqueness checks pass
3. acyclic checks for dependency/blocking edges pass
4. project field schema validation pass (`planningops/scripts/validate_project_field_schema.py`)

## Evidence Artifacts
- `planningops/artifacts/meta-plan/meta-graph.json`
- `planningops/artifacts/meta-plan/meta-execution-report.json`
- `planningops/artifacts/validation/plan-compile-report.json`
- `planningops/artifacts/validation/plan-projection-report.json`

## Compatibility Policy
- `v1` keeps node keys aligned with PEC v1 naming.
- Breaking key/domain changes require `v2` + migration notes.
- Optional fields may be added in `v1` when required keys remain unchanged.
