# Local Operator Target Resolution Contract

## Purpose
Define the deterministic boundary for monday-owned local delivery target resolution when autonomous apply-mode flows need operator or terminal notifications without caller-supplied transport arguments.

This contract exists so:
- `planningops` can stay transport-agnostic while still completing local apply-mode delivery paths
- `monday` can resolve local operator and terminal targets from repo-owned configuration instead of prompt-local guesses
- local-first autonomy can deliver to a durable outbox sink before real Slack or email transports are introduced

## Canonical Boundary
- operator policy contract: `planningops/contracts/operator-channel-adapter-contract.md`
- supervisor handoff contract: `planningops/contracts/supervisor-operator-handoff-contract.md`
- reflection action handoff contract: `planningops/contracts/reflection-action-handoff-contract.md`
- monday local outbox resolver: `monday/scripts/operator_channel_local_outbox.py`
- monday status delivery CLI: `monday/scripts/send_operator_message.py`
- monday goal-completion CLI: `monday/scripts/send_goal_completion_notification.py`
- monday reflection delivery CLI: `monday/scripts/send_reflection_decision_update.py`
- monday supervisor completion CLI: `monday/scripts/send_supervisor_goal_completion.py`
- monday local target profiles: `monday/config/local-operator-channel-profiles.json`

## Resolution Scope
The local target resolution boundary applies only when monday delivery CLIs are invoked without an explicit concrete target on the primary local-first path.

The boundary includes:
- selecting one repo-owned local profile by `channel_kind`
- resolving one deterministic local outbox sink target for that profile
- emitting delivery evidence that records whether target resolution came from an explicit argument or a local profile

The boundary does not include:
- real Slack API calls
- SMTP or third-party mail provider calls
- planningops-owned recipient registries
- prompt-authored target selection

## Required Local Profile Document
`monday/config/local-operator-channel-profiles.json` must exist once this contract is active.

The profile document must include:
- `config_version`
- `profiles`

Each profile entry must include:
- `channel_kind`
- `transport_kind`
- `outbox_root`
- `default_target_name`
- `supports_threads`

Profile rules:
- `channel_kind` must match the channel kinds projected by `planningops` policy, including `slack_skill_cli` and `email_cli`
- `transport_kind` must currently equal `local_outbox`
- `outbox_root` must stay repo-root relative from the `monday` repo when possible
- `default_target_name` must be a monday-owned logical name, not a real Slack channel ID or email address
- `supports_threads` must be boolean

## Required Delivery Evidence
Every monday delivery CLI that resolves a local target must emit evidence containing:
- `channel_kind`
- `delivery_mode`
- `delivery_verdict`
- `delivery_idempotency_key`
- `delivery_target`
- `target_resolution_mode`
- `target_profile_ref`

Evidence rules:
- `target_resolution_mode` must be one of `explicit_argument` or `local_profile`
- `target_profile_ref` must be `-` only when `target_resolution_mode = explicit_argument`
- `delivery_target` must be the resolved local sink target even when monday derived it from a profile

## Deterministic Resolution Rules
- monday must resolve local targets only from repo-owned config, explicit CLI arguments, or skill/MCP context that maps into the same monday-owned config model
- planningops must never resolve a concrete `delivery_target` for the primary local autonomous path
- when an explicit CLI target is provided, monday may use it as an override and must record `target_resolution_mode = explicit_argument`
- when no explicit CLI target is provided, monday must resolve exactly one profile by `channel_kind`
- identical apply-mode inputs plus the same monday local profile config must resolve the same local target apart from timestamps
- monday must fail closed when `channel_kind` has no matching local profile
- monday must fail closed when `transport_kind` is not supported by the invoked CLI

## Local Outbox Rules
- monday local apply-mode delivery must succeed by writing one deterministic outbox artifact and one delivery report when `transport_kind = local_outbox`
- local outbox paths must remain inside the monday repo runtime-artifacts boundary
- outbox artifact naming must be idempotent by the delivery idempotency key so repeated apply-mode attempts do not duplicate terminal notifications
- thread-aware status updates may include a thread reference in outbox metadata, but local target resolution must not require one

## Ownership Boundary
### PlanningOps owns
- channel intent and channel kind policy
- handoff artifacts and completion policy
- validation that monday delivery evidence remains wired to the control-plane artifacts

### Monday owns
- local target profile configuration
- target resolution
- local outbox persistence
- transport-facing delivery evidence

### PlanningOps must not own
- local outbox sink paths
- concrete Slack channel identifiers
- concrete email recipients
- transport credentials

## Failure Rules
- missing `monday/config/local-operator-channel-profiles.json` must fail local target resolution once this contract is active
- missing or duplicate profile matches for a required `channel_kind` must fail delivery
- `planningops` must fail if its primary local autonomous apply path still requires a caller-supplied concrete `delivery-target`
- monday must fail if local outbox delivery cannot write deterministic evidence for `apply` mode
- monday must not silently downgrade a local apply-mode delivery failure into `dry_run` or `skipped`

## Validation
- `planningops/scripts/test_local_operator_target_resolution_contract.sh`
- `planningops/contracts/reflection-delivery-cycle-contract.md`
- `planningops/contracts/supervisor-operator-handoff-contract.md`
- `monday/scripts/operator_channel_local_outbox.py`
- `monday/scripts/send_operator_message.py`
- `monday/scripts/send_goal_completion_notification.py`
- `monday/scripts/send_reflection_decision_update.py`
- `monday/scripts/send_supervisor_goal_completion.py`
