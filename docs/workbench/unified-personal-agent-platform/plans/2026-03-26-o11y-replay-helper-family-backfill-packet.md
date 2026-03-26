---
title: plan: O11y-Replay Helper Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the o11y-replay helper entrypoint and its contract and wiring regressions so the local matrix and workflow no longer depend on local-only helper files.
related_docs:
  - ./2026-03-26-contract-conformance-helper-family-backfill-packet.md
  - ./2026-03-26-runtime-operations-ready-helper-family-backfill-packet.md
---

# plan: O11y-Replay Helper Family Backfill Packet

## Summary
- Backfill the tracked `o11y-replay` helper family that the local federated matrix, workflow job, and helper guardrails already invoke directly.
- Promote the missing helper entrypoint plus contract and wiring regressions into git-tracked reality so observability replay dry-runs are reproducible from remote `main`.
- Verify the helper owns the Langfuse stack launcher dry-run instead of leaving launcher commands inlined in matrix or workflow YAML.

## Scope
- `planningops/scripts/run_o11y_replay_ci_check.sh`
- `planningops/scripts/test_run_o11y_replay_ci_check_contract.sh`
- `planningops/scripts/test_o11y_replay_helper_wiring.sh`
- workbench hub link for this helper-family backfill

## Acceptance
- `test_run_o11y_replay_ci_check_contract.sh` passes
- `test_o11y_replay_helper_wiring.sh` proves local matrix and workflow blocks call only the canonical helper
- `run_o11y_replay_ci_check.sh --run-id <id> --o11y-root ../platform-observability-gateway` succeeds from the repo root
