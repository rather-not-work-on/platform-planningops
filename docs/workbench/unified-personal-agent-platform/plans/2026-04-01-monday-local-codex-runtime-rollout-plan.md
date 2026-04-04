---
title: plan: Monday Local Codex Runtime Rollout
type: plan
date: 2026-04-01
updated: 2026-04-02
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
- mission packets now carry forward local validation freshness/promotability snapshot fields from promoted handoff packets
- `planningops/contracts/monday-local-operator-day-packet-contract.md`
- `planningops/scripts/write_monday_local_operator_day_packet.py`
- `planningops/artifacts/validation/monday-local-operator-day-packet.json`
- `planningops/artifacts/validation/<day-packet-id>-monday-local-operator-day-packet.json`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness` now includes the promoted day packet family in the same promotion lane
- `planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md`
- `planningops/scripts/write_monday_local_operator_inbox_payload.py`
- `planningops/artifacts/validation/monday-local-operator-inbox-payload.json`
- `planningops/artifacts/validation/<bridge-id>-monday-local-operator-inbox-payload.json`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness` now includes the promoted inbox payload bridge family in the same promotion lane
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-inbox-payload` exposes a payload-first operator view for latest/stamped inbox payload artifacts without going through `handoff-report`
- `monday/contracts/planningops-local-operator-inbox-consumer-contract.md`
- `monday/scripts/consume_planningops_local_operator_inbox_payload.py`
- `monday/scripts/test_consume_planningops_local_operator_inbox_payload.sh`
- `monday/runtime-artifacts/integration/planningops-local-operator-inbox/<run-id>/launch-request.json`
- `monday/runtime-artifacts/integration/planningops-local-operator-inbox/<run-id>/mission.json`
- `monday/runtime-artifacts/integration/planningops-local-operator-inbox/<run-id>/consumer-report.json`
- `planningops/scripts/federation/query_federated_ci_artifacts.py monday-consumer-report` exposes a monday-native apply/result view over dry-run, apply-pass, and blocked consumer reports
- `planningops/scripts/federation/query_federated_ci_artifacts.py monday-consumer-report` now also exposes `runtime_input_overrides` usage for audit; overrides remain regression-only and are not yet promoted to an operator-facing escape hatch
- `monday/contracts/planningops-local-operator-inbox-payload-bridge.schema.json`
- `monday/contracts/planningops-local-operator-inbox-consumer-report.schema.json`
- `monday/scripts/validate_planningops_local_operator_inbox_artifacts.py`
- `monday/scripts/test_validate_planningops_local_operator_inbox_artifacts.sh`
- monday local CI now validates the promoted inbox payload bridge and monday-native consumer report against monday-owned schemas before merge
- `planningops/scripts/federation/query_federated_ci_artifacts.py monday-validation-report` now exposes monday-owned bridge/consumer-report schema validation verdicts from `monday/runtime-artifacts/validation`
- monday now consumes the promoted inbox payload as structured input and materializes native runtime command argv without reparsing day-packet markdown
- monday consumer regression now covers:
  - ready dry-run packet materialization
  - ready apply-time local runtime smoke through `scripts/run_local_runtime_smoke.py`
  - blocked apply-time fail-closed behavior
- explicit `--planner-runtime-config` and `--runtime-profile-file` passthrough can pin deterministic apply-time runtime inputs for local regression
- `monday/scripts/run_local_runtime_smoke.py` now records the reviewed `--planner-runtime-config` override in smoke evidence instead of rejecting the consumer-produced argv
- `planningops/contracts/monday-local-inbox-validation-mirror-contract.md`
- `planningops/scripts/write_monday_local_inbox_validation_mirror.py`
- `planningops/artifacts/validation/monday-local-inbox-launch-request.json`
- `planningops/artifacts/validation/<run-id>-monday-local-inbox-launch-request.json`
- `planningops/artifacts/validation/monday-local-inbox-runtime-report.json`
- `planningops/artifacts/validation/<run-id>-monday-local-inbox-runtime-report.json`
- `planningops/artifacts/validation/monday-local-inbox-consumer-report.json`
- `planningops/artifacts/validation/<run-id>-monday-local-inbox-consumer-report.json`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness` now picks up the mirrored monday launch-request, runtime-report, and consumer-report families when they are present in planningops validation
- `planningops/scripts/federation/query_federated_ci_artifacts.py handoff-report` now carries a local validation snapshot status/summary that folds the mirrored monday launch-request, runtime-report, and consumer-report families into the operator packet when present
- `planningops/contracts/monday-validation-report-mirror-contract.md`
- `planningops/scripts/write_monday_validation_report_mirror.py`
- `planningops/artifacts/validation/monday-local-inbox-bridge-schema-validation.json`
- `planningops/artifacts/validation/<report-id>-monday-local-inbox-bridge-schema-validation.json`
- `planningops/artifacts/validation/monday-local-inbox-consumer-schema-validation.json`
- `planningops/artifacts/validation/<report-id>-monday-local-inbox-consumer-schema-validation.json`
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness` now picks up mirrored monday-owned bridge and consumer schema validation verdicts when they are promoted into planningops validation
- `planningops/scripts/federation/query_federated_ci_artifacts.py handoff-report` now carries a dedicated monday schema validation snapshot/summary/actions section when those mirrored verdicts are present
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-inbox-payload` now carries a bridge-aware monday schema validation snapshot/summary/actions view for the current inbox payload without routing through `handoff-report`
- `planningops/scripts/federation/query_federated_ci_artifacts.py monday-consumer-report` now carries run-aware monday schema validation snapshot/summary/actions fields so apply/result-first triage sees the same cross-repo validation signal as payload-first and handoff surfaces
- `planningops/scripts/federation/query_federated_ci_artifacts.py cross-repo-validation-report` now emits a dedicated fixed-format packet that combines mirrored monday inbox launch/runtime/consumer freshness with monday-owned schema validation verdicts in one operator view
- `planningops/scripts/federation/query_federated_ci_artifacts.py triage-feed` now carries the cross-repo validation snapshot/status summary so the top-level operator overview shows monday inbox mirror health and monday source validation verdicts without leaving the feed
- `planningops/contracts/cross-repo-validation-report-contract.md`
- `planningops/scripts/federation/query_federated_ci_artifacts.py write-cross-repo-validation-report`
- `planningops/artifacts/validation/cross-repo-validation-report.json`
- `planningops/artifacts/validation/<report-id>-cross-repo-validation-report.json`
- the dedicated cross-repo validation packet is now promotion-ready as a stamped validation artifact instead of staying query-only
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-validation-freshness` now tracks the promoted `cross_repo_validation_report` packet as its own validation family once the latest/stamped artifact pair exists
- `planningops/scripts/federation/query_federated_ci_artifacts.py triage-brief|triage-report` now carry the same cross-repo validation snapshot and monday source validation summary that `triage-feed` already exposes
- `planningops/scripts/federation/query_federated_ci_artifacts.py cross-repo-validation-packet` now exposes the promoted latest/stamped packet directly from `planningops/artifacts/validation` so operators can read immutable evidence without recomputing source roots
- `planningops/scripts/federation/query_federated_ci_artifacts.py triage-feed|triage-brief|triage-report` now point summary-first triage surfaces at the promoted `cross-repo-validation-packet` through explicit packet `report_id` and `path` fields so operators can jump to the immutable detail packet without re-expanding source roots
- `planningops/scripts/federation/query_federated_ci_artifacts.py handoff-report` now points blocking cross-repo validation states at the promoted `cross-repo-validation-packet` through explicit packet `report_id` and `path` fields so operator handoff can jump straight to immutable detail evidence
- `planningops/scripts/federation/query_federated_ci_artifacts.py triage-feed|triage-brief|triage-report` now carry dedicated cross-repo detail lines and action lines alongside the immutable packet pointer so operators can read mirror/source specifics without immediately reopening the promoted packet
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-inbox-payload|monday-consumer-report` now point current blocking payload-first and apply/result-first records at the promoted `cross-repo-validation-packet` through explicit packet `report_id` and `path` fields instead of relying on snapshot-only linkage
- `planningops/scripts/federation/query_federated_ci_artifacts.py local-inbox-payload|monday-consumer-report` now also carry the linked packet's dedicated cross-repo detail lines and action lines in their markdown/json surfaces so operators can stay in payload-first or apply/result-first views without reopening the promoted packet immediately
- `planningops/scripts/federation/query_federated_ci_artifacts.py handoff-report` now carries the same linked packet snapshot, detail lines, monday source validation report lines, and action lines that triage surfaces already expose, while still keeping the immutable `cross-repo-validation-packet` pointer for deep-link evidence
- `planningops/scripts/write_monday_local_mission_packet.py|write_monday_local_operator_day_packet.py` now preserve the promoted `cross-repo-validation-packet` pointer inside mission/day packet surfaces so packet-only operator flows can reopen immutable cross-repo evidence without routing back through `handoff-report`
- `planningops/scripts/write_monday_local_mission_packet.py|write_monday_local_operator_day_packet.py` now also carry the linked cross-repo validation snapshot, detail lines, monday source validation report lines, and action lines so mission/day packet-only flows do not lose the same operator context already available on handoff and triage surfaces
- `planningops/scripts/write_monday_local_mission_packet.py|write_monday_local_operator_day_packet.py` now fail-closed promote `cross_repo_validation_action_line` into mission/day action selection only when no stronger `local-runtime:` or `local-validation:` action already exists and an immutable promoted packet pointer is present

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

1. revisit operator-facing override promotion only if the new override audit signal shows repeated reviewed usage beyond regression coverage
2. decide whether promoted cross-repo validation should ever steer `mission_objective` or target ranking itself, or whether action selection is the right ceiling and the packet should stay objective-stable
