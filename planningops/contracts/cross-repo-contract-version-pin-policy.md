# Cross-Repo Contract Version Pin Policy

## Goal
Enforce deterministic contract consumption across `platform-contracts`, `platform-provider-gateway`, `platform-observability-gateway`, and `monday`.

## Rule
Each consumer repository must declare:
1. `source_repo` = `rather-not-work-on/platform-contracts`
2. `contract_bundle_version` pinned to an explicit value
3. `pinned_contracts` list for consumed contracts

Pin file locations:
- `platform-provider-gateway/config/contract-pin.json`
- `platform-observability-gateway/config/contract-pin.json`
- `monday/contracts/contract-pin.json`

## Compatibility Rule
- `contract_bundle_version` changes require conformance check rerun.
- Incompatible example (`contract_violation` scenario) must fail fast and be recorded as evidence.

## Validation Entry Point
- `python3 planningops/scripts/federation/cross_repo_conformance_check.py` (canonical)
- `python3 planningops/scripts/cross_repo_conformance_check.py` (compatibility wrapper)
