# Monday Local Operator Inbox Payload Bridge Contract

## Purpose
Define the deterministic bridge from a promoted monday local operator day packet into a monday-friendly inbox payload artifact.

This contract exists so:
- `planningops` can promote one machine-readable payload that monday can consume without reparsing day-level markdown
- the local launch context stays validation-first and reproducible
- a future monday-native packet consumer can rely on one stable payload surface

## Canonical Boundary

PlanningOps owns:
- the inbox payload bridge contract
- deterministic bridge payload promotion into validation artifacts
- deterministic derivation from:
  - `planningops/artifacts/validation/monday-local-operator-day-packet.json`
  - `planningops/artifacts/validation/monday-local-mission-packet.json`
  - `planningops/artifacts/validation/operator-handoff-report.json`
  - `planningops/artifacts/validation/monday-local-operator-stack-report.json`

Monday owns:
- any packet-native consumer that reads the promoted payload
- runtime execution after the payload boundary
- transport- or channel-specific delivery semantics beyond the payload shape

PlanningOps must not:
- re-infer launch commands from markdown when explicit command fields already exist
- drop local validation context while translating the packet into an inbox payload
- claim a monday-native consumer exists if only the bridge payload is implemented

## Canonical Artifacts

Every promoted inbox payload bridge must include:
- latest payload: `planningops/artifacts/validation/monday-local-operator-inbox-payload.json`
- stamped payload: `planningops/artifacts/validation/<bridge-id>-monday-local-operator-inbox-payload.json`

The payload may also be written to one caller-specified extra output path.

## Payload Document Shape

Top-level required fields:
1. `generated_at_utc`
2. `bridge_id`
3. `contract_ref`
4. `artifact_paths.latest_payload_path`
5. `artifact_paths.stamped_payload_path`
6. `payload`

`payload` required fields:
1. `title`
2. `status`
3. `headline`
4. `priority_headline`
5. `operator_action`
6. `recommended_wait_minutes`
7. `retry_mode`
8. `needs_human_attention`
9. `message_class_hint`
10. `planner_profile`
11. `launch_mode`
12. `local_model_route`
13. `first_action_command`
14. `monday_runtime_entrypoint_command`
15. `rollback_command`
16. `local_validation_snapshot_status`
17. `local_validation_summary_lines`
18. `local_validation_action_lines`
19. `attachments`
20. `body_markdown`
21. `bridge_contract_ref`
22. `source_artifacts.day_packet_path`
23. `source_artifacts.mission_packet_path`
24. `source_artifacts.handoff_report_path`
25. `source_artifacts.local_operator_report_path`

Optional fields:
- `day_packet_id`
- `mission_packet_id`
- `mission_objective`
- `queue_lines`
- `target_lines`
- `immediate_actions`

## Deterministic Resolution Rules

1. Identical promoted day packet inputs must produce the same bridge payload apart from timestamps.
2. The bridge must reuse explicit launch fields from the day packet instead of recomputing them from `body_markdown`.
3. `status` must be derived fail-closed:
   - `blocked` when local validation actions are present or the carried runtime summary already indicates `verdict=fail` or `readiness=blocked`
   - otherwise `ready`
4. `needs_human_attention`, `message_class_hint`, `recommended_wait_minutes`, and `retry_mode` must be deterministically derived from `status`.
5. local validation snapshot fields must be copied directly from the promoted day packet.
6. `attachments` must include both bridge payload paths plus the source packet/report artifacts needed to reopen the launch context.

## Status Mapping Rules

- when `status=blocked`:
  - `needs_human_attention=true`
  - `message_class_hint=decision_request`
  - `recommended_wait_minutes=5`
  - `retry_mode=manual_recheck`
- when `status=ready`:
  - `needs_human_attention=false`
  - `message_class_hint=status_update`
  - `recommended_wait_minutes=0`
  - `retry_mode=none`

## Evidence Requirements

Every bridge payload must preserve the source artifact references it was derived from:
- promoted day packet path
- promoted mission packet path
- promoted handoff report path
- promoted local operator report path

Every bridge payload must also preserve the current local validation snapshot:
- the snapshot status marker
- summary lines
- action lines

## Failure Rules

- missing promoted day packet is fail-fast
- missing promoted mission packet, handoff report, or local operator report referenced by the day packet is fail-fast
- empty `title`, `headline`, `first_action_command`, `monday_runtime_entrypoint_command`, `rollback_command`, or `body_markdown` is fail-fast
- empty `attachments` is fail-fast

## Validation

- `planningops/scripts/write_monday_local_operator_inbox_payload.py`
- `planningops/scripts/test_write_monday_local_operator_inbox_payload.sh`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness`
