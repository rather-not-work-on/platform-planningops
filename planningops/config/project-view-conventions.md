# GitHub Project View Conventions

## Scope
Issue: #15  
Project: `rather-not-work-on/projects/2`

## Naming Contract
Use lowercase prefixes and stable keys.

### Queue views
- `queue/<initiative>/<repo>`
- example: `queue/unified-personal-agent-platform/platform-planningops`

### Lane views
- `lane/<initiative>/<plan_lane>`
- example: `lane/unified-personal-agent-platform/m2-sync-core`

### Component views
- `component/<initiative>/<component>`
- example: `component/unified-personal-agent-platform/provider-gateway`

### History views
- `history/<initiative>/inventory`
- example: `history/unified-personal-agent-platform/inventory`

## Required Filters
- `initiative == unified-personal-agent-platform`
- `Status in (Todo, In Progress, Blocked, Done)` as needed
- `workflow_state` filter를 목적에 맞게 병행(`ready-contract`, `ready-implementation`, `blocked`, `done`)
- optional: `target_repo == rather-not-work-on/<repo>`
- queue views should exclude `Status=Done`
- inventory history views should use `Status=Done` and optionally `target_repo == rather-not-work-on/platform-planningops`

## Sort and Group Defaults
- Primary sort: `execution_order` ascending
- Secondary sort: `workflow_state` (ready-contract -> in-progress -> review-gate -> ready-implementation -> blocked -> done)
- Group options:
  - `plan_lane`
  - `component`
  - `Status`
  - `workflow_state`

## Field Consistency Rules
- `initiative` is mandatory on all cards.
- `component` is mandatory on all cards.
- `target_repo` is mandatory for draft issue cards.
- For issue cards:
  - if built-in repository is control repo (`rather-not-work-on/platform-planningops`), cross-repo `target_repo` is allowed.
  - otherwise, `target_repo` must match built-in repository full name.
