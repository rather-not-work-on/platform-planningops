# Monday Local Operator Day Packet Contract

## Purpose
Define the deterministic boundary for the inbox-ready day-level packet that PlanningOps promotes after the monday local mission packet exists.

This contract exists so:
- Codex can hand one reusable day packet to the next operator step without reopening multiple artifacts
- `planningops` remains the owner of promotion, evidence, and rollback guidance
- `monday` local launch work can start from one deterministic packet instead of ad hoc note assembly

## Canonical Boundary

PlanningOps owns:
- the day packet contract
- day packet promotion into validation artifacts
- deterministic derivation from:
  - `planningops/artifacts/validation/monday-local-mission-packet.json`
  - `planningops/artifacts/validation/operator-handoff-report.json`
  - `planningops/artifacts/validation/monday-local-operator-stack-report.json`

Monday owns:
- runtime execution after the packet boundary
- planner semantics beyond the packet
- future monday-native consumers for this packet

PlanningOps must not:
- invent monday-private runtime state
- hide launch commands inside prompt-local prose
- drop local validation context while compressing the packet into a day-level artifact

## Canonical Artifacts

Every promoted day packet must include:
- latest packet: `planningops/artifacts/validation/monday-local-operator-day-packet.json`
- stamped packet: `planningops/artifacts/validation/<day-packet-id>-monday-local-operator-day-packet.json`

The packet may also be written to one caller-specified extra output path.

## Packet Document Shape

Top-level required fields:
1. `generated_at_utc`
2. `day_packet_id`
3. `contract_ref`
4. `artifact_paths.latest_packet_path`
5. `artifact_paths.stamped_packet_path`
6. `day_packet`

`day_packet` required fields:
1. `version` (`v1`)
2. `day_packet_id`
3. `mission_packet_id`
4. `headline`
5. `mission_objective`
6. `mission_prompt`
7. `planner_profile`
8. `launch_mode`
9. `local_model_route`
10. `first_action_command`
11. `monday_runtime_entrypoint_command`
12. `rollback_command`
13. `queue_lines`
14. `target_lines`
15. `immediate_actions`
16. `local_validation_snapshot_status`
17. `local_validation_records`
18. `local_validation_summary_lines`
19. `local_validation_action_lines`
20. `attachments`
21. `cross_repo_validation_packet_report_id`
22. `cross_repo_validation_packet_path`
23. `body_markdown`
24. `source_artifacts.mission_packet_path`
25. `source_artifacts.handoff_report_path`
26. `source_artifacts.local_operator_report_path`

Optional fields:
- `attention_summary`
- `newest_failing_summary`
- `local_runtime_summary`
- `local_runtime_next_step`

## Deterministic Resolution Rules

1. Identical promoted mission packet, handoff report, and local operator report must produce the same day packet apart from timestamps.
2. The day packet must reuse mission-launch fields from the promoted mission packet instead of recomputing them.
3. `headline` must be derivable from the promoted mission objective and remain operator-readable.
4. `attachments` must include the latest + stamped day packet paths and the source artifact references needed to reopen the launch context.
5. local validation snapshot fields must be copied from the mission packet when present; otherwise the writer may fall back to the promoted handoff snapshot and must mark that fallback explicitly; otherwise it must emit `missing` with empty collections.
6. when the promoted mission packet already carries a promoted `cross-repo-validation-packet` pointer, the day packet must preserve that immutable `report_id`/`path` pair; only legacy mission packets may fall back to the handoff pointer.

## Command Rules

- `first_action_command` must remain PlanningOps-owned and come from the mission packet `preflight_command`.
- `monday_runtime_entrypoint_command` must remain explicit and deterministic.
- `rollback_command` must remain explicit and deterministic.
- the day packet must never require the next operator to infer launch commands from `body_markdown`

## Evidence Requirements

Every day packet must preserve the source artifact references it was derived from:
- mission packet path
- promoted handoff report path
- promoted local operator report path

Every day packet must also preserve the current local validation snapshot:
- machine-readable local validation records
- operator-facing local validation summary lines
- operator-facing local validation action lines
- an explicit snapshot status marker

When present, every day packet must also preserve the promoted cross-repo validation packet pointer:
- immutable `cross_repo_validation_packet_report_id`
- immutable `cross_repo_validation_packet_path`
- attachment reuse of the packet path so operators can reopen the promoted evidence directly from the day packet
- body-level visibility of the pointer so the deep link survives packet-only handoff flows

## Failure Rules

- missing promoted mission packet is fail-fast
- missing promoted handoff report is fail-fast
- missing promoted local operator report is fail-fast
- empty `headline`, `mission_objective`, `first_action_command`, `monday_runtime_entrypoint_command`, or `rollback_command` is fail-fast
- empty `attachments` is fail-fast

## Validation

- `planningops/scripts/write_monday_local_operator_day_packet.py`
- `planningops/scripts/test_write_monday_local_operator_day_packet.sh`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness`
