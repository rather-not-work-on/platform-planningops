# Goal Completion Contract

## Purpose
Define when an active goal is complete enough to stop autonomous execution and emit a terminal operator notification.

## Required Completion Dimensions
1. `backlog_state`
2. `verification_state`
3. `operator_notification_state`
4. `terminal_notification_state`

## Completion Rules
- A goal may transition to `achieved` only when:
  - all in-scope backlog items are closed or archived intentionally,
  - required verification artifacts report `verdict=pass`,
  - the operator channel has received a completion summary,
  - terminal notification has been recorded once.

## Notification Rules
- Terminal notification is required only on transition to `achieved`.
- Terminal notification must be idempotent by `goal_key` and `achieved_at_utc`.
- Email is the default terminal notification channel unless the active goal overrides it explicitly.

## Ownership Boundary
- PlanningOps owns completion policy and evidence requirements.
- Monday owns sending channel messages and returning delivery evidence.

## Validation Targets
- Active goal registry entries must reference this contract when terminal notification is expected.
