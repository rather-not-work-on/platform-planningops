---
doc_id: uap-automation-operations-summary
title: UAP Automation Operations Summary
doc_type: quality
domain: quality
status: active
date: 2026-03-11
updated: 2026-03-19
initiative: unified-personal-agent-platform
memory_tier: L1
tags:
  - uap
  - automation
  - planningops
  - supervisor
  - standup
summary: Canonical operating summary for active Codex automations, their role boundaries, active-goal driven execution rules, and the resolved local-only failure mode.
related_docs:
  - ../README.md
  - ./uap-planningops-tradeoff-decision-framework.quality.md
  - ../../../../planningops/contracts/federated-ci-summary-contract.md
  - ../../../../planningops/contracts/active-goal-registry-contract.md
  - ../../../../planningops/contracts/operator-channel-adapter-contract.md
  - ../../../../planningops/contracts/supervisor-operator-handoff-contract.md
  - ../../../workbench/unified-personal-agent-platform/audits/federated-reconciliation-report-20260311.md
  - ../../../archive/README.md
---

# UAP Automation Operations Summary

## Purpose
Keep active automation behavior compact and current so long-running loops do not keep acting on stale blocker memory.

## Active Automations
### Overnight UAP
- role: execution automation for `platform-planningops`, `monday`, `platform-provider-gateway`, `platform-observability-gateway`, and `platform-contracts`
- authority:
  - branch create/switch
  - commit/push
  - PR create/edit
  - PR body repair for `template-and-link-check`
  - check monitoring
  - merge and post-merge sync
  - issue/project field sync
- boundary:
  - keep `planningops` as control tower only
  - move execution logic into owning repos
  - stop only for irreversible decisions, missing credentials, or manual external actions

### Standup Summary
- role: observational automation only
- authority:
  - read git history
  - summarize prior-day activity
- boundary:
  - no repo mutation
  - no issue/project mutation
  - no PR/merge activity

## Current State
Last manually re-verified on `2026-03-11` KST.

- GitHub auth is healthy for the operator account.
- GitHub API rate limit is healthy.
- `git ls-remote` to `origin` succeeds.
- all five managed repos currently report `0` open issues.
- automation worktree roots use the space-free symlink `/Users/minijb/rather-not-work-on`.

## Resolved Failure Mode
The earlier local-only behavior was not caused by git permissions.

- failure source: worktree execution rooted under `/Volumes/T7 Touch/...`
- failure symptom: cwd truncation at the first space
- observed error: `fatal: cannot change to '/Volumes/T7'`
- mitigation:
  - automation `cwds` moved to `/Users/minijb/rather-not-work-on`
  - execution prompt now requires remote reconciliation when auth/network are healthy
  - automation memory must treat auth/network blockers as stale unless re-verified in the current run

## Operating Rules
1. Re-check GitHub auth, connectivity, and rate limits at the start of every run.
2. If remote operations are healthy, do not stop at local validation or local commits.
3. Finish the full remote lifecycle in the same run whenever work is mergeable:
   - push
   - PR create or update
   - template/link repair
   - check monitoring
   - merge
   - local main sync
   - feature branch cleanup
   - issue/project field sync
4. If all repos are clean and no open issue is ready, regenerate or re-triage backlog from `planningops` instead of inventing repo-local work.
   - canonical command: `python3 planningops/scripts/core/backlog/materialize.py --contract-file <execution-contract.json>`
   - dry-run expectation: the command must project local issues first, then run label backfill / manifest / issue-quality against that projected issue set instead of depending on pre-existing live GitHub issues
   - apply expectation: the command must fail preflight when the selected execution contract only matches closed historical issues unless reopen is explicitly enabled
5. Supervisor runs may opt into automatic backlog regeneration on replanning paths.
   - canonical command: `python3 planningops/scripts/autonomous_supervisor_loop.py --mode apply --auto-materialize-backlog --backlog-materialization-contract-file <execution-contract.json>`
   - dry-run expectation: materialization reports should be attached to the supervisor cycle and surfaced as review guidance rather than being treated as a quality failure
6. Keep durable conclusions in canonical docs or workbench audits; keep automation memory short and current.
7. Prefer the active goal registry over hard-coded execution contract paths whenever goal-driven autonomy is enabled.
   - canonical file: `planningops/config/active-goal-registry.json`
   - canonical command: `python3 planningops/scripts/autonomous_supervisor_loop.py --mode apply --auto-materialize-backlog --active-goal-registry planningops/config/active-goal-registry.json`
8. Operator messaging stays out of planningops runtime code.
   - primary operator channel: `Slack skill -> monday-owned CLI/MCP adapter -> Slack API`
   - terminal completion channel: `monday-owned CLI/MCP adapter -> email provider`
   - planningops owns only the policy, goal state, and delivery evidence requirements
9. Local runtime readiness is now cross-repo.
   - `monday` operator automation should treat `runtime-operations` as the top-level gate for planner/runtime safety
   - `platform-provider-gateway` LiteLLM gate must stay green alongside `monday` because the promoted local planner route depends on that sibling stack
   - local federated CI keeps `monday` on the canonical `local` profile even when `GEMINI_API_KEY` and `GOOGLE_API_KEY` are absent; in that free-only mode `platform-provider-gateway` must prove the LiteLLM-exposed Ollama fallback path with `reason_code=litellm_fallback_only_ready` or better
   - local `loop-guardrails` should soft-skip GitHub project field fetch failures during `track1 gate dry-run`; external rate limits are not allowed to make the local federated runtime gate nondeterministic
10. Federated CI summary artifacts are canonical operator evidence.
   - canonical contract: `planningops/contracts/federated-ci-summary-contract.md`
   - latest summary artifact: `planningops/artifacts/ci/federated-ci-summary.json`
   - latest validation artifact: `planningops/artifacts/validation/federated-ci-summary-validation.json`
   - latest readiness artifact: `planningops/artifacts/validation/federated-ci-summary-readiness.json`
   - latest readiness validation artifact: `planningops/artifacts/validation/federated-ci-summary-readiness-validation.json`
   - canonical readiness command: `python3 planningops/scripts/assess_federated_ci_summary_readiness.py --strict`
   - operator-facing diagnosis command: `python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`
   - diagnosis and gate must fail closed when summary validation, readiness, or readiness-validation is stale
   - fail-closed gate command: `bash planningops/scripts/gate_federated_ci_summary.sh`
11. Supervisor/operator handoff must consume the canonical federated readiness surface, not raw summary files.
   - canonical contract: `planningops/contracts/supervisor-operator-handoff-contract.md`
   - implementation: `planningops/scripts/autonomous_supervisor_loop.py`
   - `operator-report.json` may embed a `federated_ci_summary` snapshot sourced from the latest readiness artifact, and should derive `priority_headline` plus `priority_cta_command` for downstream operator surfaces
   - that snapshot should carry canonical evidence refs plus `remediation_commands` so monday-owned delivery adapters do not need to rediscover the operator path
   - `operator-summary.md` and `inbox-payload.json` should carry the same federated evidence refs and remediation commands
   - monday-owned wrappers, dispatch artifacts, and scheduler evidence should preserve `operator_handoff_validation_path`, `priority_preview_ref`, and `priority_display_packet_ref` so CTA consumers can dereference one canonical validation/preview/display trio instead of reparsing markdown or nested delivery reports
   - canonical planningops handoff-validation consumer command: `python3 planningops/scripts/resolve_supervisor_operator_handoff_validation.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-validation.json>`
   - canonical planningops bundle consumer command: `python3 planningops/scripts/resolve_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-bundle.json>`
   - canonical planningops bundle validation command: `python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --output <handoff-bundle-validation.json> --strict`
   - canonical planningops bundle readiness command: `python3 planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py --artifact-file <wrapper-or-scheduler-report> --bundle-validation-output <handoff-bundle-validation.json> --output <handoff-bundle-readiness.json> --readiness-validation-output <handoff-bundle-readiness-validation.json> --strict`
   - canonical planningops bundle readiness-validation command: `python3 planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py --readiness <handoff-bundle-readiness.json> --output <handoff-bundle-readiness-validation.json> --strict`
   - canonical planningops bundle doctor command: `python3 planningops/scripts/doctor_supervisor_operator_handoff_bundle.py --artifact-file <wrapper-or-scheduler-report> --require-pass`
   - canonical planningops bundle gate command: `bash planningops/scripts/gate_supervisor_operator_handoff_bundle.sh --artifact-file <wrapper-or-scheduler-report>`
   - canonical monday preview consumer command: `python3 scripts/resolve_operator_priority_preview.py --artifact-file <wrapper-or-scheduler-report> --output <preview.json>`
   - canonical monday display consumer command: `python3 scripts/resolve_operator_priority_display_packet.py --artifact-file <wrapper-or-scheduler-report> --output <display-packet.json>`
   - if multiple monday artifacts from one delivery path disagree on their dereferenced preview/display packet JSON, that is a contract regression and must fail closed
   - if federated readiness is blocked while the supervisor would otherwise emit `status=ok`, the handoff must be downgraded to `status=degraded` with `operator_action=inspect_federated_ci_gates`
   - the downgraded reason should surface the canonical readiness `next_step` instead of ad hoc operator guidance

## Reflected Outcomes
- execution-repo remote reconciliation completed for:
  - `platform-contracts` PR `#13`
  - `platform-provider-gateway` PR `#22`
  - `platform-observability-gateway` PR `#22`
  - `monday` PR `#24`
- PlanningOps reconciliation follow-up completed through PR `#272`.
- The remaining automation memory should therefore describe current operating truth, not archived blocker logs.

## Verification
- `gh auth status`
- `gh api rate_limit`
- `git ls-remote --heads origin`
- `gh issue list --state open` across the five managed repos
- `python3 planningops/scripts/core/backlog/materialize.py --contract-file <execution-contract.json>`
- `python3 planningops/scripts/autonomous_supervisor_loop.py --mode apply --auto-materialize-backlog --backlog-materialization-contract-file <execution-contract.json>`
- `python3 planningops/scripts/autonomous_supervisor_loop.py --mode apply --auto-materialize-backlog --active-goal-registry planningops/config/active-goal-registry.json`
- `python3 planningops/scripts/validate_active_goal_registry.py --registry planningops/config/active-goal-registry.json --strict`
- `python3 planningops/scripts/backfill_issue_labels.py --repo rather-not-work-on/platform-planningops --issues-file /tmp/projected-issues.json --write-updated-issues-file /tmp/projected-issues.json --output /tmp/issue-label-backfill-report.json --apply`
- `(cd /Users/minijb/rather-not-work-on/platform-provider-gateway && npm run gate:litellm-stack-ready)`
- `(cd /Users/minijb/rather-not-work-on/monday && npm run gate:runtime-operations-ready)`
- `python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`
- `python3 planningops/scripts/assess_federated_ci_summary_readiness.py --strict`
- `bash planningops/scripts/gate_federated_ci_summary.sh`
- `bash planningops/scripts/test_supervisor_operator_handoff_contract.sh`
- `bash planningops/scripts/test_autonomous_supervisor_loop_contract.sh`
- `(cd /Users/minijb/rather-not-work-on/monday && python3 scripts/resolve_operator_priority_preview.py --artifact-file runtime-artifacts/messaging/local-dispatch-cycle-report.json --output /tmp/operator-priority-preview.json)`
- `(cd /Users/minijb/rather-not-work-on/monday && python3 scripts/resolve_operator_priority_display_packet.py --artifact-file runtime-artifacts/messaging/local-dispatch-cycle-report.json --output /tmp/operator-priority-display-packet.json)`
