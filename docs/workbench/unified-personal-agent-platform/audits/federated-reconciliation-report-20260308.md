---
title: audit: Federated Reconciliation Report
type: audit
date: 2026-03-08
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Reconciles the core/federation split, wrapper deprecation governance, and final closure gates for the current planningops federation cycle.
---

# Federated Reconciliation Report (2026-03-08)

## Scope
- reconcile `A20`~`A22` core/federation split
- reconcile `A30`~`A32` wrapper deprecation governance
- verify `C90` closure gates for planningops control-plane boundaries and federated evidence flow

## Closure Summary
- `planningops/scripts/core/loop/runner.py` is now the canonical loop runner module.
- `planningops/scripts/federation/adapter_registry.py` now owns repo-to-adapter mapping.
- legacy root entrypoints remain as thin compatibility wrappers only.
- wrapper lifecycle is now governed by `planningops/config/wrapper-deprecation-map.json` and enforced by `planningops/scripts/validate_wrapper_deprecation.py`.
- live reconciliation gates passed on 2026-03-08 after running federated conformance in an ephemeral virtualenv because the host Python is PEP 668 externally managed.

## Evidence By Work Item
### A20 Core loop split layer 1
- canonical modules:
  - `planningops/scripts/core/loop/checkpoint_lock.py`
  - `planningops/scripts/core/loop/selection.py`
  - `planningops/scripts/core/loop/runner.py`
- regression evidence:
  - `bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
  - `bash planningops/scripts/test_loop_checkpoint_resume.sh`
  - `bash planningops/scripts/test_lease_lock_watchdog.sh`
  - `bash planningops/scripts/test_escalation_gate.sh`

### A21 Core/federation split layer 2
- canonical federation registry:
  - `planningops/scripts/federation/adapter_registry.py`
- active code migrated off legacy wrapper path where practical:
  - `planningops/scripts/federation/federated_ci_matrix_local.sh`
  - `planningops/scripts/test_multi_repo_fanout.sh`
- regression evidence:
  - `bash planningops/scripts/test_repo_execution_adapters.sh`

### A22 Compatibility wrapper mode
- legacy wrappers retained:
  - `planningops/scripts/issue_loop_runner.py`
  - `planningops/scripts/repo_execution_adapters.py`
- wrapper compatibility evidence:
  - `bash planningops/scripts/test_issue_loop_runner_wrapper_compat.sh`
  - `bash planningops/scripts/test_repo_execution_adapters_wrapper_compat.sh`

### A30-A32 Wrapper deprecation governance
- lifecycle map:
  - `planningops/config/wrapper-deprecation-map.json`
- validator:
  - `planningops/scripts/validate_wrapper_deprecation.py`
- CI enforcement:
  - `.github/workflows/federated-ci-matrix.yml`
- contract evidence:
  - `bash planningops/scripts/test_validate_wrapper_deprecation_contract.sh`
  - `python3 planningops/scripts/validate_wrapper_deprecation.py --mode warn`
  - `python3 planningops/scripts/validate_wrapper_deprecation.py --mode fail`

## Live Gate Results
### Docs and topology
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile workbench`
- result: `pass`

### Memory governance
- `python3 planningops/scripts/memory_compactor.py --mode check --root . --rules planningops/config/memory-tier-rules.json --strict`
- result: `record_count=229`, `l0_record_count=135`, `trigger_count=0`, `error_count=0`, `verdict=pass`

### Wrapper lifecycle
- `python3 planningops/scripts/validate_wrapper_deprecation.py --mode fail`
- result: `config_error_count=0`, `warning_count=0`, `error_count=0`, `verdict=pass`

### Branch protection
- `python3 planningops/scripts/audit_branch_protection.py --policy planningops/config/repository-governance-policy.json --allow-fetch-failure`
- result: `repo_evaluated_count=5`, `fetch_error_count=0`, `violation_count=0`, `verdict=pass`

### Federated conformance
- execution note: local run required an ephemeral virtualenv under `/tmp` because direct `pip install` into the host interpreter was blocked by PEP 668 (`externally-managed-environment`).
- validation command:
  - `python planningops/scripts/federation/cross_repo_conformance_check.py --workspace-root .. --run-id c90-20260308`
- result after dependency bootstrap: `check_count=19`, `assertion_count=6`, `incompatibility_example=pass`, `verdict=pass`
- environment gap identified during first attempt:
  - sibling repos depend on `jsonschema` from their `requirements-dev.txt`
  - conformance is reproducible locally, but bootstrap is not yet automated inside planningops

## Issue Alignment
- completed planningops items in this cycle:
  - `A20` `#97`
  - `A21` `#98`
  - `A22` `#99`
  - `A30` `#100`
  - `A31` `#101`
  - `A32` `#102`
- closure item for this report:
  - `C90` `#109`
- prior dependencies already reconciled before this cycle:
  - `A10` `#95`
  - `A11` `#96`
  - `A40`~`A44` `#103`~`#107`
  - `B50` `#108`

## Next Maintenance Backlog
- keep federated execution repo umbrella issues active until deeper runtime stabilization is done:
  - `platform-contracts#1`
  - `platform-provider-gateway#1`
  - `platform-observability-gateway#1`
  - `monday#2`
- track the newly identified local dependency bootstrap gap in:
  - `platform-planningops#132`
- fold `stock-034` replenishment candidates back into the next planningops pull only after federation hardening demand drops:
  - `#86`, `#87`, `#88`, `#89`

## Reconciliation Verdict
- control-plane boundary: `pass`
- memory governance: `pass`
- wrapper deprecation governance: `pass`
- branch protection baseline: `pass`
- federated evidence consistency: `pass`
- overall: `pass`
