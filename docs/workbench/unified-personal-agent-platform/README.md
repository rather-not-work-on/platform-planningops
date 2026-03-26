---
title: UAP Workbench Hub
type: hub
date: 2026-02-28
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Initiative-scoped workbench for ephemeral brainstorm/plan/audit artifacts before canonical promotion.
---

# UAP Workbench Hub

이 디렉토리는 `unified-personal-agent-platform` initiative의 비영속 산출물을 보관한다.

## Layout
- `brainstorms/`: 아이디어 탐색 및 접근 옵션
- `plans/`: 실행 계획 초안/수정 계획
- `audits/`: 마이그레이션 맵, 검증 로그, 롤아웃 노트

## Contract
- workbench 문서는 운영 중 생성되는 산출물이다.
- canonical source of truth는 `docs/initiatives/unified-personal-agent-platform` 문서다.
- canonical 문서가 workbench 문서를 규범으로 참조하면 안 된다.
- 승격 시 canonical 문서를 갱신하고 workbench 문서는 `status: reference`로 전환한다.

## Validation
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile workbench
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
python3 planningops/scripts/memory_compactor.py --mode check --root . --rules planningops/config/memory-tier-rules.json
```

## Active Plans
- [Control Tower Ontology, Memory, and Federation Migration](./plans/2026-03-05-plan-control-tower-ontology-memory-and-federation-migration-plan.md)
- [Meta Backlog Atomic Decomposition and Federated Delivery](./plans/2026-03-05-plan-meta-backlog-atomic-decomposition-and-federated-delivery-plan.md)
- [Worker Reliability Hardening](./plans/2026-03-05-refactor-worker-reliability-hardening-plan.md)
- [Ralph Loop Full Automation Delivery](./plans/2026-03-04-plan-ralph-loop-full-automation-delivery-plan.md)
- [DeepAgents Core, Skillctl, and Sandboxed Apply-Mode Rollout](./plans/2026-03-16-plan-deepagents-core-skillctl-and-sandbox-rollout-plan.md)
- [MONDAY Agent Harness Reference Assimilation](./plans/2026-03-23-monday-agent-harness-reference-assimilation-plan.md)
- [MONDAY Agent Harness Wave 1 Implementation Issue Pack](./plans/2026-03-23-monday-agent-harness-wave1-implementation-issue-pack.md)
- [MONDAY Agent Harness Wave 1 Implementation Handoff Packet](./plans/2026-03-23-monday-agent-harness-wave1-implementation-handoff-packet.md)
- [MONDAY Agent Harness Wave 1 Opening Seed Packet](./plans/2026-03-23-monday-agent-harness-wave1-opening-seed-packet.md)
- [MONDAY Agent Harness Wave 1 Evidence Seed Packet](./plans/2026-03-23-monday-agent-harness-wave1-evidence-seed-packet.md)
- [MONDAY Agent Harness Wave 1 Projection Seed Packet](./plans/2026-03-23-monday-agent-harness-wave1-projection-seed-packet.md)
- [MONDAY Agent Harness Projection Contract Candidate](./plans/2026-03-23-monday-agent-harness-projection-contract-candidate.md)
- [MONDAY Agent Harness Readiness Gate Issue Draft](./plans/2026-03-23-monday-agent-harness-readiness-gate-issue-draft.md)
- [MONDAY Agent Harness Wave 1 Registration Runbook](./plans/2026-03-23-monday-agent-harness-wave1-registration-runbook.md)
- [MONDAY Agent Harness Wave 1 Sub-Issue Decomposition](./plans/2026-03-23-monday-agent-harness-wave1-sub-issue-decomposition.md)
- [MONDAY Agent Memory Implementation Priority Memo](./plans/2026-03-25-monday-agent-memory-implementation-priority-memo.md)
- [MONDAY Agent Memory Implementation Spec and WBS](./plans/2026-03-25-monday-agent-memory-implementation-spec-and-wbs.md)
- [MONDAY Agent Memory Wave A Kickoff Packet](./plans/2026-03-25-monday-agent-memory-wave-a-kickoff-packet.md)
- [MONDAY Agent Memory Wave B Consolidation Packet](./plans/2026-03-25-monday-agent-memory-wave-b-consolidation-packet.md)
- [MONDAY Agent Memory Wave C Job Surface Packet](./plans/2026-03-25-monday-agent-memory-wave-c-job-surface-packet.md)
- [MONDAY Agent Memory Wave D Queue Admission Packet](./plans/2026-03-25-monday-agent-memory-wave-d-queue-admission-packet.md)
- [MONDAY Agent Memory Wave E Scheduler Execution Packet](./plans/2026-03-25-monday-agent-memory-wave-e-scheduler-execution-packet.md)
- [MONDAY Agent Memory Wave F Completion Packet](./plans/2026-03-25-monday-agent-memory-wave-f-completion-packet.md)
- [MONDAY Agent Memory Wave G Reflection Packet](./plans/2026-03-25-monday-agent-memory-wave-g-reflection-packet.md)
- [MONDAY Agent Memory Wave H Control-Plane Reflection Packet](./plans/2026-03-25-monday-agent-memory-wave-h-control-plane-reflection-packet.md)
- [MONDAY Agent Memory Wave I Goal-Completion Handoff Packet](./plans/2026-03-25-monday-agent-memory-wave-i-goal-completion-handoff-packet.md)
- [MONDAY Agent Memory Wave J Scheduled Control-Plane Automation Packet](./plans/2026-03-25-monday-agent-memory-wave-j-scheduled-control-plane-automation-packet.md)
- [MONDAY Agent Memory Wave K Runtime-Handoff CI Packet](./plans/2026-03-25-monday-agent-memory-wave-k-runtime-handoff-ci-packet.md)
- [MONDAY Agent Memory Wave L Shared Handoff Surface Packet](./plans/2026-03-25-monday-agent-memory-wave-l-shared-handoff-surface-packet.md)
- [MONDAY Agent Memory Wave M Runtime-Handoff Supervisor Contract Packet](./plans/2026-03-26-monday-agent-memory-wave-m-runtime-handoff-supervisor-contract-packet.md)
- [MONDAY Agent Memory Wave N Reflection Cycle Shared Plumbing Packet](./plans/2026-03-26-monday-agent-memory-wave-n-reflection-cycle-shared-plumbing-packet.md)
- [MONDAY Agent Memory Wave O Goal-Completion Bridge Shared Plumbing Packet](./plans/2026-03-26-monday-agent-memory-wave-o-goal-completion-bridge-shared-plumbing-packet.md)
- [MONDAY Agent Memory Wave P Delivery Cycle Shared Plumbing Packet](./plans/2026-03-26-monday-agent-memory-wave-p-delivery-cycle-shared-plumbing-packet.md)
- [MONDAY Agent Memory Wave Q Runtime-Handoff Delivery Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-q-runtime-handoff-delivery-lane-packet.md)
- [MONDAY Agent Memory Wave R Runtime-Handoff Reflection Contract Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-r-runtime-handoff-reflection-contract-lane-packet.md)
- [MONDAY Agent Memory Wave S Runtime-Handoff Direct Reflection Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-s-runtime-handoff-direct-reflection-lane-packet.md)
- [MONDAY Agent Memory Wave T Runtime-Handoff Delivery Admission Contract Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-t-runtime-handoff-delivery-admission-contract-lane-packet.md)
- [MONDAY Agent Memory Wave U Runtime-Handoff Local Delivery Contract Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-u-runtime-handoff-local-delivery-contract-lane-packet.md)
- [MONDAY Agent Memory Wave V Runtime-Handoff Goal Policy Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-v-runtime-handoff-goal-policy-lane-packet.md)
- [MONDAY Agent Memory Wave W Runtime-Handoff Supervisor Handoff Contract Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-w-runtime-handoff-supervisor-handoff-contract-lane-packet.md)
- [MONDAY Agent Memory Wave X Runtime-Handoff Bundle Readiness Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-x-runtime-handoff-bundle-readiness-lane-packet.md)
- [MONDAY Agent Memory Wave Y Runtime-Handoff Ops Summary Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-y-runtime-handoff-ops-summary-lane-packet.md)
- [MONDAY Agent Memory Wave Z Runtime-Handoff Federated Summary Readiness Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-z-runtime-handoff-federated-summary-readiness-lane-packet.md)
- [MONDAY Agent Memory Wave AA Runtime-Handoff Federated Summary Contract Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-aa-runtime-handoff-federated-summary-contract-lane-packet.md)
- [MONDAY Agent Memory Wave AB Runtime-Handoff Tmp-Reconcile Root Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ab-runtime-handoff-tmp-reconcile-root-lane-packet.md)
- [MONDAY Agent Memory Wave AC Runtime-Handoff Tmp-Reconcile Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ac-runtime-handoff-tmp-reconcile-bundle-status-lane-packet.md)
- [MONDAY Agent Memory Wave AD Runtime-Handoff Tmp-Reconcile Status-Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ad-runtime-handoff-tmp-reconcile-status-bundle-status-lane-packet.md)
- [MONDAY Agent Memory Wave AE Runtime-Handoff Tmp-Reconcile Status-Bundle-Status-Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ae-runtime-handoff-tmp-reconcile-status-bundle-status-bundle-status-lane-packet.md)
- [MONDAY Agent Memory Wave AF Runtime-Handoff Tmp-Reconcile Status-Bundle-Status-Bundle-Status-Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-af-runtime-handoff-tmp-reconcile-status-bundle-status-bundle-status-bundle-status-lane-packet.md)
- [MONDAY Agent Memory Wave AG Runtime-Handoff Tmp-Reconcile Status-Bundle-Status-Bundle-Status-Bundle-Status-Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ag-runtime-handoff-tmp-reconcile-status-bundle-status-bundle-status-bundle-status-bundle-status-lane-packet.md)
- [MONDAY Agent Memory Wave AH Runtime-Handoff Tmp-Reconcile Status-Bundle-Status-Bundle-Status-Bundle-Status-Bundle-Status-Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ah-runtime-handoff-tmp-reconcile-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-lane-packet.md)
- [MONDAY Agent Memory Wave AI Runtime-Handoff Tmp-Reconcile Status-Bundle-Status-Bundle-Status-Bundle-Status-Bundle-Status-Bundle-Status-Bundle-Status Lane Packet](./plans/2026-03-26-monday-agent-memory-wave-ai-runtime-handoff-tmp-reconcile-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-lane-packet.md)
- [MONDAY Harness Capability Contract Draft](./plans/2026-03-23-monday-harness-capability-contract-draft.md)
- [MONDAY PlanningOps Evidence Projection Contract Draft](./plans/2026-03-23-monday-planningops-evidence-projection-contract-draft.md)
- [MONDAY Runtime Artifact Map Draft](./plans/2026-03-23-monday-runtime-artifact-map-draft.md)
- [MONDAY Team-Phase Contract Draft](./plans/2026-03-23-monday-team-phase-contract-draft.md)
- [MONDAY Session and Replay Evidence Draft](./plans/2026-03-23-monday-session-replay-evidence-draft.md)
- [DeepAgents, Skillctl, and Sandboxed Apply-Mode Issue Pack](./plans/2026-03-16-deepagents-skillctl-sandbox-issue-pack.md)
- [Track2 Implementation Readiness Packet](./plans/track2-implementation-readiness-packet.md)

## Recent Audits
- [MONDAY Agent Harness Reference Gap Analysis](./audits/2026-03-23-monday-agent-harness-reference-gap-analysis.md)
- [MONDAY Agent Harness Reference Traceability Map](./audits/2026-03-23-monday-agent-harness-reference-traceability-map.md)

## Current Note
- `monday` runtime now has `deepagents` as the promoted default local planner path.
- `skillctl` supply-chain baseline is now implemented in `monday`:
  - `config/skill-registry.json`
  - `config/skill-lock.json`
  - vendored `pm-skills` mirror with `65` pinned skills
- sandboxed apply-mode baseline is now implemented in `monday`:
  - `config/apply-sandbox-policy.json`
  - `config/apply-sandbox-container-profiles.json`
  - fail-closed source-class and capability checks
  - isolated subprocess runner with credential stripping
  - reviewed container profile catalog plus optional container-required execution and readiness coverage
- `monday` runtime-operations readiness now treats the sibling `platform-provider-gateway` LiteLLM stack as a first-class surface and points operators at the gateway-local doctor/gate commands when that route blocks planner health.
- `monday` agent-harness MH50 projection publication is now implemented as immutable completion/readiness/verification/handoff surfaces derived from sealed evidence only, so planningops can start drafting projection-only doctor/gate contracts without reopening monday runtime-private state.
- runtime, skill supply chain, sandbox baseline, and canonical migration are now aligned.
- the rollout plans and migration audit below should now be treated as implementation history and reference material.
