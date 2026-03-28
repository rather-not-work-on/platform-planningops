---
title: plan: Track1 Gate Sample Artifact Lane Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Promotes deterministic `.sample.json` outputs for the Track1 gate dry-run reports by replaying the gate with mocked docs/schema checks and a fixed KPI verdict.
related_docs:
  - ./2026-03-28-track1-gate-artifact-refresh-packet.md
  - ./2026-03-28-track2-contract-pack-sample-artifact-lane-packet.md
---

# plan: Track1 Gate Sample Artifact Lane Packet

## Summary
- Replay `run_track1_gate_dryrun.py` in a temporary validation root with mocked docs/schema command results.
- Fix the KPI outcome to one passing baseline so the Track1 gate reports become deterministic and replayable.
- Publish committed `.sample.json` fixtures for the chain report and dry-run report, then lock them with one artifact-lane regression.

## Scope
- `planningops/artifacts/validation/track1-validation-chain-report.sample.json`
- `planningops/artifacts/validation/track1-gate-dryrun-report.sample.json`
- `planningops/scripts/test_run_track1_gate_dryrun_artifact_lane.sh`
- `planningops/artifacts/README.md`
- `planningops/scripts/README.md`

## Acceptance
- `test_track1_gate_dryrun_contract.sh` passes
- `test_run_track1_gate_dryrun_artifact_lane.sh` passes
- `test_module_readme_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
