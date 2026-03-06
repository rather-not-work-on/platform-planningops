# Federated Label Taxonomy Contract

## Purpose
Keep issue classification and automation quality consistent across execution repositories.

## Scope
- `rather-not-work-on/platform-contracts`
- `rather-not-work-on/platform-provider-gateway`
- `rather-not-work-on/platform-observability-gateway`
- `rather-not-work-on/monday`

## Required Taxonomy
Each scoped repo must provide the configured label set including:
- task marker: `task`
- priority labels: `p1|p2|p3`
- area labels: `area/*`
- type labels: `type/*`

Each in-scope planning issue (`plan_item_id:` marker in body) must include:
1. `task`
2. one priority label (`p1|p2|p3`)
3. at least one `area/` label
4. at least one `type/` label

## Source of Truth
- Config: `planningops/config/federated-label-taxonomy.json`

## Verification
- Label sync: `planningops/scripts/ensure_label_taxonomy.py`
- Issue quality validator: `planningops/scripts/validate_federated_issue_quality.py`
- Contract test: `planningops/scripts/test_validate_federated_issue_quality_contract.sh`

## Operational Notes
- `ensure_label_taxonomy.py --apply` creates/updates missing taxonomy labels per repo.
- `validate_federated_issue_quality.py --apply-default-labels` can backfill missing labels for open in-scope issues using repo defaults.
