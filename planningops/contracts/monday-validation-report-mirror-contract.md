# Monday Validation Report Mirror Contract

## Purpose

Promote monday-owned inbox schema validation verdicts into `planningops/artifacts/validation` so planningops can reason about those verdicts without rereading sibling runtime artifacts directly.

## Source Inputs

- `monday/runtime-artifacts/validation/planningops-local-operator-inbox-payload-validation-report.json`
- `monday/runtime-artifacts/validation/planningops-local-operator-inbox-consumer-report-validation-report.json`

Each source report is expected to carry:

- `generated_at_utc`
- `kind`
- `artifact_path`
- `schema_path`
- `error_count`
- `warning_count`
- `errors`
- `warnings`
- `verdict`

## Promoted Outputs

### Bridge Validation

- latest: `planningops/artifacts/validation/monday-local-inbox-bridge-schema-validation.json`
- stamped: `planningops/artifacts/validation/<report-id>-monday-local-inbox-bridge-schema-validation.json`

### Consumer Validation

- latest: `planningops/artifacts/validation/monday-local-inbox-consumer-schema-validation.json`
- stamped: `planningops/artifacts/validation/<report-id>-monday-local-inbox-consumer-schema-validation.json`

## Document Shape

Each promoted mirror must include:

- `generated_at_utc`
- `report_id`
- `artifact_family`
- `artifact_kind`
- `contract_ref`
- `artifact_paths.latest_mirror_path`
- `artifact_paths.stamped_mirror_path`
- `artifact_paths.source_report_path`
- `mirror.source_report_present`
- `mirror.report_kind`
- `mirror.report_verdict`
- `mirror.error_count`
- `mirror.warning_count`
- `mirror.artifact_exists`
- `mirror.schema_exists`
- `mirror.validation_dependency_paths`
- `mirror.payload`

## Family Mapping

- `kind=bridge` -> `artifact_family=monday_local_inbox_bridge_schema_validation`
- `kind=consumer-report` -> `artifact_family=monday_local_inbox_consumer_schema_validation`

## Dependency Mapping

- bridge validation depends on `planningops/artifacts/validation/monday-local-operator-inbox-payload.json`
- consumer validation depends on `planningops/artifacts/validation/monday-local-inbox-consumer-report.json`

## Promotion Rules

- mirror whichever validation kinds are present; do not fail if one kind is absent
- fail only when no promotable source validation report documents are discovered
- preserve source payload verbatim under `mirror.payload`
- generate deterministic latest and stamped paths for each mirrored kind

## Verification

- `python3 planningops/scripts/write_monday_validation_report_mirror.py --validation-root <validation-root> --monday-validation-root <monday-validation-root>`
- `bash planningops/scripts/test_write_monday_validation_report_mirror.sh`
- `bash planningops/scripts/test_query_federated_ci_artifacts.sh`
