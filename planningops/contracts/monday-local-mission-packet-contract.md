# Monday Local Mission Packet Contract

## Purpose
Define the deterministic boundary between promoted PlanningOps handoff evidence and the next local `monday` mission input packet consumed by Codex or a future monday-native mission entrypoint.

This contract exists so:
- promoted handoff artifacts stop being prompt-local suggestions and become reproducible mission inputs
- `planningops` stays the owner of evidence, packet promotion, and rollback guidance
- `monday` can accept one stable packet that already freezes mission objective, planner profile, model route, and expected evidence outputs

## Canonical Boundary

PlanningOps owns:
- the mission packet contract
- mission packet promotion into validation artifacts
- deterministic packet derivation from:
  - `planningops/artifacts/validation/operator-handoff-report.json`
  - `planningops/artifacts/validation/monday-local-operator-stack-report.json`

Monday owns:
- the actual planner runtime
- mission execution semantics beyond the packet boundary
- runtime-private memory, queue behavior, and future packet-native execution CLIs

PlanningOps must not:
- invent monday-private runtime state
- claim a packet-native monday executor exists when only a smoke or wrapper path is available
- hide rollback expectations inside prompt-local prose

## Canonical Artifacts

Every promoted local mission packet must include these artifact surfaces:
- latest packet: `planningops/artifacts/validation/monday-local-mission-packet.json`
- stamped packet: `planningops/artifacts/validation/<packet-id>-monday-local-mission-packet.json`

The packet may also be written to one caller-specified extra output path for downstream handoff tooling.

## Packet Document Shape

Top-level required fields:
1. `generated_at_utc`
2. `packet_id`
3. `contract_ref`
4. `artifact_paths.latest_packet_path`
5. `artifact_paths.stamped_packet_path`
6. `mission_packet`

`mission_packet` required fields:
1. `version` (`v1`)
2. `packet_id`
3. `mission_objective`
4. `mission_prompt`
5. `planner_profile`
6. `launch_mode`
7. `local_model_route`
8. `source_kind`
9. `primary_action`
10. `preflight_command`
11. `rollback_command`
12. `expected_evidence_outputs`
13. `immediate_actions`
14. `target_lines`
15. `source_artifacts.handoff_report_path`
16. `source_artifacts.local_operator_report_path`

Optional fields:
- `attention_summary`
- `newest_failing_summary`
- `local_runtime_summary`
- `local_runtime_next_step`
- `monday_runtime_entrypoint_command`

## Deterministic Resolution Rules

1. Identical promoted handoff artifact, local operator artifact, and explicit CLI overrides must produce the same packet fields apart from timestamps.
2. `launch_mode`, `planner_profile`, and `local_model_route` must be derived fail-closed:
   - if local readiness is `ready`, prefer `launch_mode=stack`, `planner_profile=local`, `local_model_route=gateway_first_local`
   - otherwise prefer `launch_mode=direct` with the local operator's direct profile
   - if no direct profile is present, fall back to `local_ollama`
3. `mission_objective` must come from the promoted handoff surface, not from prompt-local inference.
4. `expected_evidence_outputs` must point at deterministic artifact paths that the chosen launch path is expected to refresh.

## Command Rules

`preflight_command` must remain PlanningOps-owned.

Today that means:
- stack launch uses `planningops/scripts/run_monday_local_operator_stack.py --execution-mode stack`
- direct launch uses `planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct`

`monday_runtime_entrypoint_command` is optional until monday exposes a packet-native mission executor. When present, it may reference the currently available monday local runtime smoke surface.

`rollback_command` must be explicit and deterministic:
- stack packets must rollback toward a direct local profile
- direct packets must rollback toward gateway bootstrap when live prerequisites fail

## Evidence Requirements

Every packet must preserve the source artifact references it was derived from:
- promoted handoff packet path
- promoted local operator packet path

Every packet must also name the mission-run evidence it expects next:
- latest + stamped mission packet paths
- the local operator runtime aggregate path keyed by `packet_id`
- the stamped local operator validation mirror keyed by `packet_id`

## Failure Rules

- missing promoted handoff artifact is fail-fast
- missing promoted local operator artifact is fail-fast
- missing `record` payload in the promoted handoff artifact is fail-fast
- empty `mission_objective`, `preflight_command`, or `rollback_command` is fail-fast
- unsupported explicit `launch_mode`, `planner_profile`, or `local_model_route` overrides are fail-fast

## Validation

- `planningops/scripts/write_monday_local_mission_packet.py`
- `planningops/scripts/test_write_monday_local_mission_packet.sh`
- `docs/workbench/unified-personal-agent-platform/plans/2026-04-01-monday-local-codex-runtime-rollout-plan.md`
