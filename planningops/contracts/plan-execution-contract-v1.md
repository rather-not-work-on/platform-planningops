# Plan Execution Contract v1

## Purpose
Define a machine-readable contract that allows a plan document to be compiled into executable backlog issues and project field updates without manual translation.

## Contract Object
Top-level key:
- `execution_contract`

Required fields:
1. `plan_id` (string): stable plan identity key
2. `plan_revision` (integer >= 1): revision number for change tracking
3. `source_of_truth` (string): repo-relative plan path
4. `items` (array): executable plan items

## Item Schema
Each item in `items` must include:
- `plan_item_id` (string, unique within plan)
- `execution_order` (integer >= 1)
- `title` (string)
- `target_repo` (string, `owner/repo`)
- `component` (enum):
  - `planningops`
  - `contracts`
  - `provider_gateway`
  - `observability_gateway`
  - `runtime`
  - `orchestrator`
- `workflow_state` (enum):
  - `backlog`
  - `ready_contract`
  - `ready_implementation`
  - `in_progress`
  - `review_gate`
  - `blocked`
  - `done`
- `loop_profile` (enum):
  - `l1_contract_clarification`
  - `l2_simulation`
  - `l3_implementation_tdd`
  - `l4_integration_reconcile`
  - `l5_recovery_replan`
- `plan_lane` (enum):
  - `m0_bootstrap`
  - `m1_contract_freeze`
  - `m2_sync_core`
  - `m3_guardrails`
- `depends_on` (array of integers, execution_order references)
- `primary_output` (string, repo-relative path)

Optional:
- `required_checks` (array of strings)
- `notes` (string)

## Determinism Rules
1. `plan_item_id` is immutable once published.
2. Compile identity key is `plan_id + plan_item_id + target_repo`.
3. `execution_order` must be unique within one `execution_contract`.
4. `depends_on` must reference existing `execution_order` values.

## Mapping Rules
Compiler output must include issue body metadata keys:
- `plan_doc`
- `plan_item_id`
- `execution_order`
- `target_repo`
- `component`
- `workflow_state`
- `loop_profile`
- `plan_lane`
- `depends_on`
- `primary_output`

Project field mapping:
- `Status` derives from `workflow_state`
- `workflow_state` single-select uses the same canonical key domain
- `loop_profile` single-select uses the same canonical key domain
- `execution_order`, `target_repo`, `initiative` are mirrored directly
- `plan_lane` single-select uses the same canonical key domain

## Compatibility Policy
- `v1` supports legacy issue execution by requiring compiler output to preserve existing issue body metadata shape.
- Breaking key changes require `v2` contract and migration note.
- Optional field additions are allowed in `v1` if required fields remain unchanged.

## Validation Requirements
Before apply mode:
1. schema validation pass (`plan-execution-contract.schema.json`)
2. duplicate `plan_item_id`/`execution_order` check pass
3. dependency reference check pass
4. project field schema validation pass

## Failure Policy
- Missing required key: fail-fast
- Unknown enum value: fail-fast
- Unresolved dependency reference: fail-fast
- Projection mismatch in apply mode: fail-fast with report artifact

## Evidence Artifacts
- `planningops/artifacts/validation/plan-compile-report.json`
- `planningops/artifacts/validation/plan-projection-report.json`
