---
title: plan: Monday Local Codex Runtime Rollout
type: plan
date: 2026-04-01
updated: 2026-04-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the planningops-owned rollout for running monday locally with a local LLM path and Codex as the operator shell, using readiness-first evidence instead of ad hoc repo hopping.
related_docs:
  - ./2026-04-01-query-engine-and-harness-upgrade-plan.md
  - ./2026-03-23-monday-agent-harness-reference-assimilation-plan.md
  - ./2026-03-14-autonomous-scheduler-queue-control-plane-plan.md
---

# plan: Monday Local Codex Runtime Rollout

## Why This Exists

The local pieces already exist, but they are still spread across repo boundaries:

- `planningops` can orchestrate sibling-repo local stack smoke
- `monday` already exposes `local`, `local_ollama`, and `local_lmstudio` planner profiles
- provider and observability gateways already have local launcher surfaces
- Codex already works as the operator shell on this machine

What is missing is a planningops-owned readiness view that answers a simpler question:

Can we run `monday` locally, with a local LLM path available, and use Codex as the operator shell without manually rediscovering the wiring every time?

## External Reference Patterns

The public reference page for Claude Code is useful for local runtime design because it makes four things explicit:

- the system runs as an agentic loop: request, context assembly, tool execution, observe, repeat
- the runtime treats context as a first-class object rather than accidental shell state
- the query engine and tool dispatcher are separate from the higher-level runtime shell
- the terminal process is the execution boundary, not a hidden remote server

That maps cleanly onto the current repo split:

- `Codex` is the operator shell and tool surface
- `monday` is the mission runtime and planner execution host
- local LLM infrastructure is a selectable backend, not the operator shell itself
- `planningops` owns readiness, evidence, governance, and promotion rules

## Target Local Operating Model

### Operator shell

Codex remains the human-facing operator shell for:

- triage
- plan selection
- handoff packet generation
- smoke invocation
- evidence review

### Runtime host

`monday` remains the runtime owner for:

- planner profile selection
- mission execution
- handoff generation
- runtime-private memory and queue behavior

### Model path

The local model path must support two valid shapes:

1. gateway-first local mode
   - `monday local -> LiteLLM/provider gateway -> Gemini primary or local fallback`
2. direct local LLM mode
   - `monday local_ollama -> Ollama`
   - `monday local_lmstudio -> LM Studio`

### Governance owner

`planningops` must not become the mission executor. It should own:

- readiness checks
- federated smoke orchestration
- report and artifact indexing
- next-step recommendations

## Phase Plan

### Phase 0. Structural readiness

Make the wiring visible from `planningops` without touching runtime internals.

Deliverables:

- a planningops-owned readiness assessor for:
  - sibling repo presence
  - local gateway-first alignment
  - direct local LLM profile presence
  - Codex shell availability
- deterministic next-step commands for:
  - federated local stack smoke
  - monday direct profile smoke
  - gateway bootstrap

### Phase 1. Local smoke promotion lane

Promote a repeatable operator entrypoint:

- one `planningops` command that:
  - checks readiness
  - runs federated local stack smoke
  - optionally runs direct monday profile smoke
  - stores one stamped local operator report

Current deliverables:

- `planningops/scripts/run_monday_local_operator_stack.py`
- `planningops/runtime-artifacts/local/monday-local-operator-stack/<run-id>.json`
- `planningops/artifacts/validation/monday-local-operator-stack-report.json`
- `planningops/artifacts/validation/<run-id>-monday-local-operator-stack-report.json`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-operator-stack`
- `planningops/scripts/federation/query_federated_ci_artifacts.py triage-feed|triage-brief|triage-report` now carry the latest local operator stack pointer
- `planningops/scripts/federation/query_federated_ci_artifacts.py handoff-report` emits a handoff-ready operator packet with local validation freshness/promotability
- `planningops/scripts/federation/query_federated_ci_artifacts.py write-handoff-report`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness`
- `planningops/artifacts/validation/operator-handoff-report.json`
- `planningops/artifacts/validation/<report-id>-operator-handoff-report.json`
- `planningops/contracts/monday-local-mission-packet-contract.md`
- `planningops/scripts/write_monday_local_mission_packet.py`
- `planningops/artifacts/validation/monday-local-mission-packet.json`
- `planningops/artifacts/validation/<packet-id>-monday-local-mission-packet.json`

### Phase 2. Codex-to-monday handoff packet

Add a stable packet for Codex-originated local mission execution:

- mission objective
- planner profile
- local model route
- expected evidence outputs
- rollback instruction when live prerequisites fail

### Phase 3. Operator-grade local report

Expose a report shaped for handoff and reuse:

- headline
- active planner profile
- local LLM route
- readiness blockers
- recommended commands
- latest smoke evidence

## Immediate Commands

Gateway-first local smoke:

```bash
python3 planningops/scripts/federation/run_local_runtime_stack_smoke.py --workspace-root .. --profile local --run-id monday-local-stack-smoke
```

Direct monday smoke via local Ollama:

```bash
cd ../monday
python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-ollama-smoke
```

Direct monday smoke via LM Studio:

```bash
cd ../monday
python3 scripts/run_local_runtime_smoke.py --profile local_lmstudio --run-id monday-local-lmstudio-smoke
```

Provider gateway bootstrap:

```bash
cd ../platform-provider-gateway
bash scripts/litellm_stack_launcher.sh --mode start
```

## Success Criteria

- `planningops` can say whether `monday + local LLM + Codex` is structurally ready without repo hopping
- the report contains exact commands for the next smoke step
- `monday` local profiles stay runtime-owned
- `planningops` remains evidence-first and fail-closed
- the next implementation packet can focus on one operator entrypoint instead of rediscovering prerequisites

## Next Natural Packets

1. decide whether mission packet promotion should also emit an inbox-ready day packet or stay as a reusable validation-sidecar primitive
2. add a monday-native packet consumer once the repo exposes a mission executor richer than the current runtime smoke entrypoint
3. decide whether the local validation snapshot should also be mirrored into a day-level inbox or handoff digest artifact
