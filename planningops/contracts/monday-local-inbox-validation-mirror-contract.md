# Monday Local Inbox Validation Mirror Contract

## Purpose

Promote monday-owned local inbox consumer evidence into planningops-owned validation artifacts so freshness and promotability can be judged without leaving the planningops validation lane.

## Artifact Families

- `monday_local_inbox_launch_request`
- `monday_local_inbox_runtime_report`
- `monday_local_inbox_consumer_report`

Each family writes two mirrors:

- latest: `planningops/artifacts/validation/<family-latest>.json`
- stamped: `planningops/artifacts/validation/<run-id>-<family-latest>.json`

## Required Top-Level Fields

- `generated_at_utc`
- `run_id`
- `artifact_family`
- `artifact_kind`
- `contract_ref`
- `artifact_paths.latest_mirror_path`
- `artifact_paths.stamped_mirror_path`
- `artifact_paths.source_artifact_path`
- `artifact_paths.source_launch_request_path`
- `artifact_paths.source_runtime_report_path`
- `artifact_paths.source_consumer_report_path`
- `mirror.source_artifact_present`
- `mirror.bridge_id`
- `mirror.mode`
- `mirror.consumer_verdict`
- `mirror.consumer_status`
- `mirror.planner_profile`
- `mirror.launch_mode`
- `mirror.local_model_route`
- `mirror.has_runtime_input_overrides`
- `mirror.override_kinds`
- `mirror.validation_dependency_paths`
- `mirror.payload`

## Contract Rules

1. latest and stamped documents for the same family must carry the same `run_id`, `artifact_family`, `artifact_kind`, and `mirror` payload.
2. `artifact_paths.latest_mirror_path` must point at the latest mirror written into planningops validation.
3. `artifact_paths.stamped_mirror_path` must point at the stamped mirror written for the selected monday consumer `run_id`.
4. `artifact_paths.source_artifact_path` must point at the monday-owned source artifact for the mirrored family, even when that source artifact is expected-but-missing.
5. `mirror.validation_dependency_paths` must reference planningops-owned latest validation artifacts, not monday runtime-artifact paths.
6. launch-request and consumer-report mirrors must carry a JSON object in `mirror.payload`.
7. runtime-report mirrors may set `mirror.payload` to `null` only when `mirror.source_artifact_present=false`.

## Dependency Expectations

- `monday_local_inbox_launch_request` depends on `monday_local_operator_inbox_payload`
- `monday_local_inbox_runtime_report` depends on:
  - `monday_local_operator_inbox_payload`
  - `monday_local_inbox_launch_request`
- `monday_local_inbox_consumer_report` depends on:
  - `monday_local_operator_inbox_payload`
  - `monday_local_inbox_launch_request`
  - `monday_local_inbox_runtime_report`
