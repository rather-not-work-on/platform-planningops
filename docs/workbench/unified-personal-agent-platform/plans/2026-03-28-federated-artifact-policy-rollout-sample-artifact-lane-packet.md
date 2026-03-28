---
title: plan: Federated Artifact Policy Rollout Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes a deterministic `.sample.json` lane for `rollout_external_artifact_policy.py` using a synthetic cross-repo workspace.
related_docs:
  - ./2026-03-28-validation-sample-artifact-lanes-packet.md
---

# plan: Federated Artifact Policy Rollout Sample Artifact Lane Packet

## Summary
- Build a synthetic three-repo workspace in the regression itself so the rollout validator no longer depends on local sibling repo state.
- Publish a committed sample rollout report from that workspace.
- Add one regression that replays `rollout_external_artifact_policy.py` and compares normalized output to the committed `.sample.json` artifact.

## Scope
- `planningops/artifacts/validation/federated-artifact-policy-rollout-report.sample.json`
- `planningops/scripts/test_rollout_external_artifact_policy_artifact_lane.sh`
- `planningops/artifacts/README.md`
- `planningops/scripts/README.md`

## Acceptance
- `test_rollout_external_artifact_policy_artifact_lane.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
