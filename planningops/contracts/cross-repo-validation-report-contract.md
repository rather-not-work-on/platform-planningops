# Cross-Repo Validation Report Contract

## Purpose

Promote the fixed-format `cross-repo-validation-report` packet into `planningops/artifacts/validation` so operators can reuse one stamped report without recomputing cross-repo monday inbox freshness and monday-owned schema verdicts on demand.

## Source Inputs

- `planningops/scripts/federation/query_federated_ci_artifacts.py cross-repo-validation-report`
- `planningops/artifacts/validation/monday-local-inbox-launch-request.json`
- `planningops/artifacts/validation/monday-local-inbox-runtime-report.json`
- `planningops/artifacts/validation/monday-local-inbox-consumer-report.json`
- `planningops/artifacts/validation/monday-local-inbox-bridge-schema-validation.json`
- `planningops/artifacts/validation/monday-local-inbox-consumer-schema-validation.json`
- `monday/runtime-artifacts/validation/planningops-local-operator-inbox-payload-validation-report.json`
- `monday/runtime-artifacts/validation/planningops-local-operator-inbox-consumer-report-validation-report.json`

## Promoted Outputs

- latest: `planningops/artifacts/validation/cross-repo-validation-report.json`
- stamped: `planningops/artifacts/validation/<report-id>-cross-repo-validation-report.json`

## Document Shape

Each promoted report must include:

- `generated_at_utc`
- `report_id`
- `contract_ref`
- `artifact_paths.latest_report_path`
- `artifact_paths.stamped_report_path`
- `artifact_paths.output_path`
- `record.headline`
- `record.cross_repo_snapshot_status`
- `record.cross_repo_snapshot_summary`
- `record.cross_repo_validation_records`
- `record.cross_repo_summary_lines`
- `record.cross_repo_action_lines`
- `record.monday_source_validation_status`
- `record.monday_source_validation_summary`
- `record.monday_validation_report_records`
- `record.monday_validation_report_lines`
- `record.monday_validation_report_action_lines`
- `record.latest_payload_bridge_id`
- `record.latest_payload_status`
- `record.latest_payload_monday_validation_snapshot_status`
- `record.latest_consumer_run_id`
- `record.latest_consumer_mode`
- `record.latest_consumer_verdict`
- `record.latest_consumer_status`
- `record.latest_consumer_monday_validation_snapshot_status`
- `record.markdown`

## Promotion Rules

- always materialize the report from the same record shape returned by the query surface
- write both latest and stamped copies on every invocation
- preserve the full rendered record under `record`
- allow an optional `--output` path for ad hoc export without skipping latest/stamped promotion

## Verification

- `python3 planningops/scripts/federation/query_federated_ci_artifacts.py write-cross-repo-validation-report --validation-root <validation-root> --consumer-root <consumer-root> --monday-validation-root <monday-validation-root>`
- `bash planningops/scripts/test_query_federated_ci_artifacts.sh`
