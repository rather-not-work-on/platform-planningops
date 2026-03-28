# Supervisor Operator Handoff Contract

## Purpose
Freeze the canonical boundary between `platform-planningops` supervisor artifacts and `monday` operator-channel delivery entrypoints.

This contract exists so:
- `planningops` remains the control tower that emits deterministic run outcomes
- `monday` owns the CLI or MCP adapters that actually deliver Slack/email messages
- later transport work does not re-invent payload semantics in prompt-local logic

## Boundary

### PlanningOps owns
- supervisor run summary and stop semantics
- machine-readable operator handoff artifacts
- message-class hints
- channel policy references from the active-goal registry

### Monday owns
- translation from planningops handoff artifacts into delivery envelopes
- CLI or MCP entrypoints
- transport-specific target resolution
- Slack/email delivery evidence

PlanningOps must not:
- resolve a concrete `deliveryTarget`
- invoke Slack or email transport directly
- embed prompt-authored channel logic inside the control plane

## Canonical Handoff Artifacts

Every supervisor run must continue to emit:
- `summary.json`
- `operator-report.json`
- `operator-summary.md`
- `inbox-payload.json`
- `operator-handoff-validation.json`

When goal lifecycle transition data is relevant, the handoff may also reference:
- `cycle-<nn>/goal-transition-report.json`

## Artifact Roles

### `operator-report.json`
Machine-readable control-plane handoff document.

Required fields:
- `run_id`
- `summary_path`
- `supervisor_verdict`
- `stop_reason`
- `status`
- `headline`
- `priority_headline`
- `operator_action`
- `recommended_wait_minutes`
- `retry_mode`
- `needs_human_attention`
- `reason`
- `guidance`
- `message_class_hint`
- `handoff_contract_ref`
- `operator_handoff_validation_path`
- `priority_preview_ref`
- `priority_display_packet_ref`
- `operator_handoff_bundle_path`
- `operator_handoff_bundle_validation_path`
- `operator_handoff_bundle_readiness_path`
- `operator_handoff_bundle_readiness_validation_path`
- `priority_summary_markdown`

Optional fields:
- `cycle_report_path`
- `allowed_modes`
- `blocked_modes`
- `first_action_command`
- `priority_cta_command`
- `goal_key`
- `primary_operator_channel`
- `terminal_notification_channel`
- `goal_transition_report_path`
- `goal_completion_delivery_report_path`
- `federated_ci_summary`

### `operator-summary.md`
Human-readable attachment for the operator surface.

Requirements:
- must summarize status, headline, action, and reason
- must remain attachment-friendly and transport-agnostic
- must not become the only machine-readable handoff source
- should surface the canonical `operator-handoff-validation.json` path so downstream operators can inspect emitted handoff validation evidence directly

### `inbox-payload.json`
Normalized payload companion for monday-owned delivery surfaces.

Required fields:
- `title`
- `status`
- `headline`
- `priority_headline`
- `operator_action`
- `recommended_wait_minutes`
- `retry_mode`
- `needs_human_attention`
- `attachments`
- `body_markdown`
- `message_class_hint`
- `handoff_contract_ref`
- `operator_handoff_validation_path`
- `priority_preview_ref`
- `priority_display_packet_ref`
- `operator_handoff_bundle_path`
- `operator_handoff_bundle_validation_path`
- `operator_handoff_bundle_readiness_path`
- `operator_handoff_bundle_readiness_validation_path`
- `priority_summary_markdown`

Optional fields:
- `first_action_command`
- `priority_cta_command`
- `goal_key`
- `goal_transition_report_path`
- `primary_operator_channel`
- `terminal_notification_channel`

### `operator-handoff-validation.json`
Machine-readable validator report for the generated handoff sidecars.

Requirements:
- must be emitted by `planningops/scripts/autonomous_supervisor_loop.py`
- must validate `operator-report.json` and `inbox-payload.json` against:
  - `planningops/schemas/supervisor-operator-report.schema.json`
  - `planningops/schemas/supervisor-inbox-payload.schema.json`
- must fail closed when cross-artifact equality, attachment membership, or promoted CTA propagation regresses

## Goal-Aware Requirement

When supervisor execution is invoked with an active-goal registry:
- `operator-report.json` must include `goal_key`
- `operator-report.json` must include `primary_operator_channel`
- `operator-report.json` must include `terminal_notification_channel`
- `inbox-payload.json` must include `goal_key`

For sequence-only or fallback dry-runs that do not resolve an active goal, those fields may be absent.

## Message-Class Hint Rules

`planningops` must emit `message_class_hint` using this deterministic mapping:

1. `goal_completed`
Rule:
- when `stop_reason=goal_completed`

2. `blocked_report`
Rule:
- when `status=blocked`

3. `decision_request`
Rule:
- when `needs_human_attention=true` and rule 1 or 2 did not apply

4. `status_update`
Rule:
- all remaining cases

## Goal Completion Handoff Rule

When `message_class_hint=goal_completed`:
- `operator-report.json` must include `goal_transition_report_path`
- monday must derive the completion envelope from:
  - `operator-report.json`
  - `operator-summary.md`
  - the referenced `goal-transition-report.json`
- monday must use `terminal_notification_channel`, not `primary_operator_channel`, for terminal delivery
- when planningops supplies `first_action_command` or `federated_ci_summary.remediation_commands`, monday should preserve `headline`, `first_action_command`, and the first remediation command as terminal-delivery convenience fields and inject a `## First Action` block into the delivered markdown body unless that section already exists
- monday-owned goal-completion wrappers and downstream delivery evidence should preserve root-level `operator_handoff_validation_path`, `priority_preview_ref`, and `priority_display_packet_ref` so consumers can dereference the canonical handoff validation sidecar plus preview/display packets without reopening nested delivery reports
- monday-owned goal-completion wrappers and downstream delivery evidence should also preserve `operator_handoff_bundle_path`, `operator_handoff_bundle_validation_path`, `operator_handoff_bundle_readiness_path`, and `operator_handoff_bundle_readiness_validation_path` so consumers can dereference the planningops bundle and readiness sidecars without reopening nested delivery reports
- CTA consumers should use monday's canonical preview/display consumer path:
  - `scripts/resolve_operator_priority_preview.py`
  - `scripts/resolve_operator_priority_display_packet.py`
- canonical bundle validation consumer path: `python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-bundle-validation.json> --strict`
- canonical bundle doctor command: `python3 planningops/scripts/doctor_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --require-pass`
- canonical bundle gate command: `bash planningops/scripts/gate_supervisor_operator_handoff_bundle.sh --artifact-file <wrapper-or-scheduler-report>`
- if multiple goal-completion artifacts from one delivery path dereference different preview/display packet JSON, that is a contract regression and must fail closed
- when planningops invokes monday-owned terminal delivery, `operator-report.json` may also include `goal_completion_delivery_report_path`

## Status/Decision Handoff Rule

When `message_class_hint` is one of:
- `status_update`
- `decision_request`
- `blocked_report`

monday must treat:
- `inbox-payload.json` as the normalized operator-facing source
- `operator-summary.md` as the primary human attachment
- `operator-report.json` as machine evidence and policy context
- monday-owned status wrappers and downstream dispatch evidence should preserve root-level `operator_handoff_validation_path`, `priority_preview_ref`, and `priority_display_packet_ref` so consumers can dereference the canonical handoff validation sidecar plus preview/display packets without reparsing nested delivery reports
- monday-owned status wrappers and downstream dispatch evidence should also preserve `operator_handoff_bundle_path`, `operator_handoff_bundle_validation_path`, `operator_handoff_bundle_readiness_path`, and `operator_handoff_bundle_readiness_validation_path` so consumers can dereference the planningops bundle and readiness sidecars without reparsing nested delivery reports
- canonical handoff-validation consumer path: `python3 planningops/scripts/resolve_supervisor_operator_handoff_validation.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-validation.json>`
- canonical bundle consumer path: `python3 planningops/scripts/resolve_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-bundle.json>`
- canonical bundle validation consumer path: `python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-bundle-validation.json> --strict`
- canonical bundle readiness consumer path: `python3 planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py --artifact-file <wrapper-or-scheduler-report> --bundle-validation-output <handoff-bundle-validation.json> --output <handoff-bundle-readiness.json> --readiness-validation-output <handoff-bundle-readiness-validation.json> --strict`
- canonical bundle doctor command: `python3 planningops/scripts/doctor_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --require-pass`
- canonical bundle gate command: `bash planningops/scripts/gate_supervisor_operator_handoff_bundle.sh --artifact-file <wrapper-or-scheduler-report>`
- CTA consumers should use monday's canonical preview/display consumer path:
  - `scripts/resolve_operator_priority_preview.py`
  - `scripts/resolve_operator_priority_display_packet.py`
- if multiple status/dispatch artifacts from one delivery path dereference different preview/display packet JSON, that is a contract regression and must fail closed

## Channel Policy Rule

PlanningOps may expose:
- `primary_operator_channel`
- `terminal_notification_channel`

Those fields are policy hints only.

PlanningOps must not set:
- concrete Slack channel IDs
- concrete email recipients
- transport credentials

Monday resolves delivery targets from local configuration, skill context, or operator-specified arguments under `planningops/contracts/local-operator-target-resolution-contract.md`.

## Federated CI Evidence Rule

When the latest cross-repo runtime-gate evidence is available, `planningops` may include a `federated_ci_summary` snapshot inside `operator-report.json`.

If present, that snapshot must:
- reference the canonical latest readiness artifact instead of reconstructing readiness from raw summary data
- carry enough fields for operator triage:
  - `summary_path`
  - `readiness_path`
  - `validation_report_path`
  - `summary_run_id`
  - `summary_verdict`
  - `readiness_status`
  - `ready`
  - `next_step`
  - `first_action_command`
  - `remediation_commands`

When `federated_ci_summary` is present:
- `operator-summary.md` should include a short Federated CI section
- `inbox-payload.json` attachments should include the canonical `operator_handoff_validation_path` and may include the federated summary and readiness artifact refs
- `operator-summary.md` and `inbox-payload.json` should surface `first_action_command`, `remediation_commands`, and `priority_summary_markdown` when federated readiness is blocked
- `operator-report.json` and `inbox-payload.json` should carry `priority_headline`, `priority_cta_command`, and `priority_summary_markdown` so downstream operator surfaces do not need to recompute CTA precedence

If `federated_ci_summary.ready=false` while the supervisor would otherwise emit `status=ok`:
- `operator-report.json` should downgrade that handoff to `status=degraded`
- `operator_action` should point to federated gate inspection rather than `none`
- the human-readable reason should surface the canonical federated readiness `next_step`
- `operator-report.json`, `operator-summary.md`, and `inbox-payload.json` should promote the first remediation command as `first_action_command`

## Validation
- implementation: `planningops/scripts/autonomous_supervisor_loop.py`
- machine validator: `planningops/scripts/validate_supervisor_operator_handoff.py`
- bundle validator: `planningops/scripts/validate_supervisor_operator_handoff_bundle.py`
- bundle readiness assessor: `planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py`
- bundle readiness validator: `planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py`
- bundle doctor: `planningops/scripts/doctor_supervisor_operator_handoff_bundle.py`
- bundle gate: `planningops/scripts/gate_supervisor_operator_handoff_bundle.sh`
- machine schemas:
  - `planningops/schemas/supervisor-operator-report.schema.json`
  - `planningops/schemas/supervisor-inbox-payload.schema.json`
  - `planningops/schemas/supervisor-operator-handoff-bundle.schema.json`
  - `planningops/schemas/supervisor-operator-handoff-bundle-validation.schema.json`
- contract regression: `planningops/scripts/test_supervisor_operator_handoff_contract.sh`
- validator regression: `planningops/scripts/test_validate_supervisor_operator_handoff_contract.sh`
- bundle-validator regression: `planningops/scripts/test_validate_supervisor_operator_handoff_bundle.sh`
- bundle-readiness regression: `planningops/scripts/test_assess_supervisor_operator_handoff_bundle_readiness.sh`
- bundle-readiness-validator regression: `planningops/scripts/test_validate_supervisor_operator_handoff_bundle_readiness.sh`
- bundle-doctor regression: `planningops/scripts/test_doctor_supervisor_operator_handoff_bundle.sh`
- bundle-gate regression: `planningops/scripts/test_gate_supervisor_operator_handoff_bundle.sh`
- broader supervisor regression: `planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
