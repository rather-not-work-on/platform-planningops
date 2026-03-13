# Operator Channel Adapter Contract

## Purpose
Define how `monday` communicates with operators without embedding provider-specific channel logic inside PlanningOps control-plane automation.

## Boundary
- PlanningOps owns:
  - channel intent
  - required message classes
  - delivery evidence expectations
- Monday owns:
  - channel adapters
  - skill invocation
  - CLI or MCP transport implementation

## Required Message Classes
- `goal_intake_ack`
- `status_update`
- `decision_request`
- `blocked_report`
- `goal_completed`

## Slack Pattern
Use `Slack skill -> CLI or MCP adapter -> Slack API` as the primary operator path.

Required properties:
- Monday must not rely on raw prompt-authored HTTP calls to Slack.
- A Monday-owned skill may wrap:
  - a repo-local CLI entrypoint, or
  - a repo-local MCP server/client pair
- The skill must accept a deterministic message payload file or JSON string.
- The underlying CLI/MCP layer must support `dry-run` and `apply`.

## Email Pattern
Use `CLI or MCP adapter -> mail provider` as the terminal notification path.

Required properties:
- Email is sent only when goal completion policy says the goal transitioned to `achieved`.
- The adapter must expose idempotency by `goal_key` plus `achieved_at_utc`.
- The adapter must emit a delivery report artifact.

## Delivery Evidence
Every channel adapter invocation must be able to emit:
- `message_class`
- `goal_key`
- `delivery_mode` (`dry-run` or `apply`)
- `channel_kind`
- `delivery_target`
- `delivery_verdict`
- `delivery_timestamp_utc`
- `delivery_idempotency_key`

## Canonical Ownership
- execution repo: `rather-not-work-on/monday`
- bounded context: `packages/messaging-adapter`

## Follow-Up Implementation Shape
- Monday should expose a CLI-callable script or MCP tool first.
- The human-facing skill should be a thin wrapper over that CLI/MCP interface.
