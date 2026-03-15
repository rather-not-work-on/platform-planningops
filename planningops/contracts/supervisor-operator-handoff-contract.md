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
- `operator_action`
- `recommended_wait_minutes`
- `retry_mode`
- `needs_human_attention`
- `reason`
- `guidance`
- `message_class_hint`
- `handoff_contract_ref`

Optional fields:
- `cycle_report_path`
- `allowed_modes`
- `blocked_modes`
- `goal_key`
- `primary_operator_channel`
- `terminal_notification_channel`
- `goal_transition_report_path`
- `goal_completion_delivery_report_path`

### `operator-summary.md`
Human-readable attachment for the operator surface.

Requirements:
- must summarize status, headline, action, and reason
- must remain attachment-friendly and transport-agnostic
- must not become the only machine-readable handoff source

### `inbox-payload.json`
Normalized payload companion for monday-owned delivery surfaces.

Required fields:
- `title`
- `status`
- `headline`
- `operator_action`
- `recommended_wait_minutes`
- `retry_mode`
- `needs_human_attention`
- `attachments`
- `body_markdown`
- `message_class_hint`
- `handoff_contract_ref`

Optional fields:
- `goal_key`
- `goal_transition_report_path`
- `primary_operator_channel`
- `terminal_notification_channel`

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

## Validation
- implementation: `planningops/scripts/autonomous_supervisor_loop.py`
- contract regression: `planningops/scripts/test_supervisor_operator_handoff_contract.sh`
- broader supervisor regression: `planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
