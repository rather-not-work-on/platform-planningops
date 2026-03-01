# Execution Adapter Interface Contract

## Purpose
Define a deterministic adapter boundary so the loop runner can execute repository-specific pre/post hooks without changing the core loop flow.

This contract is the baseline for:
- issue `#34`: `platform-contracts` and `platform-provider-gateway` adapter hooks
- issue `#35`: `platform-observability-gateway` and `monday` adapter hooks
- issue `#36`: cross-repo adapter integration smoke/evidence

## Interface
Each adapter must expose two hook methods:

1. `before_loop(context) -> result`
2. `after_loop(context, payload) -> result`

`context` and `payload` must be JSON-serializable.

## Context Payload
### Required fields
- `issue_number` (int)
- `issue_repo` (string, `owner/repo`)
- `target_repo` (string, `owner/repo`)
- `workflow_state` (string)
- `loop_profile` (string)
- `mode` (`dry-run|apply`)
- `selection_transition_id` (string)

### Optional fields
- `loop_id` (string)
- `runtime_profile_file` (string path)
- `selection_trace` (object)

## Hook Result Payload
### Required fields
- `status` (`ok|error`)
- `phase` (`before_loop|after_loop`)
- `adapter` (string id)
- `target_repo` (string, `owner/repo`)
- `reason_code` (see taxonomy below)
- `message` (string)

### Optional fields
- `emitted_artifacts` (array of string paths)
- `details` (object)

## Reason Taxonomy (Adapter Standard)
Adapters must emit one of:
- `contract`
- `permission`
- `context`
- `runtime`
- `feedback_failed`

## Canonical Mapping to Loop Failure Taxonomy
| Adapter reason_code | Loop reason_code |
|---|---|
| `contract` | `verification_failed` |
| `permission` | `permission_denied` |
| `context` | `missing_input` |
| `runtime` | `runtime_error` |
| `feedback_failed` | `feedback_failed` |

## Compatibility Rules
- Unknown `target_repo` must use default adapter (`generic`) and still emit valid result payload.
- Adapter hooks must not mutate the loop runner's selection decision.
- In `dry-run`, adapter hooks may emit simulation artifacts only (no remote writes).
