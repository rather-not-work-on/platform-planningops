# Implementation Readiness Gate Contract

## Purpose
Enforce design-first delivery so implementation starts only after interface contracts, package layout, dependency boundaries, and file naming are explicitly defined.

## Required Blueprint Pack (Before Implementation)
Each issue moving to `workflow_state=ready-implementation` must reference all of the following (issue body keys in parentheses):

1. Interface contract refs (`interface_contract_refs`)
2. Package/module topology ref (`package_topology_ref`)
3. Dependency manifest ref (`dependency_manifest_ref`)
4. File plan ref (`file_plan_ref`)
5. Verification plan ref (tests/checks that prove contract conformance)
6. Module README updates for touched modules

## Gate Conditions
Implementation work is allowed only when:

1. Blueprint pack refs are present and resolvable
2. Required contracts are valid
3. `planningops/scripts/test_module_readme_contract.sh` passes
4. Required issue metadata is complete (`execution_order`, `depends_on`, `workflow_state`, `target_repo`)
5. Normalization baseline is executed at least in dry-run:
   `python3 planningops/scripts/normalize_ready_implementation_blueprint_refs.py`

## Redefinition Loop (During Implementation)
When implementation reveals structure mismatch, stop and redefine before continuing.

### Trigger Conditions
- interface contract mismatch
- module boundary or dependency direction violation
- file naming/path collision
- repeated verification failure that indicates design ambiguity

### Required Transition
1. Move card to `workflow_state=ready-contract`
2. Update blueprint refs (contract/topology/dependency/file plan)
3. Update affected module README files
4. Re-run validation gates
5. Return to `ready-implementation` only after evidence is green

## Evidence
- `planningops/artifacts/validation/track1-validation-chain-report.json`
- `planningops/artifacts/validation/transition-log.ndjson`
- `planningops/artifacts/loop-runner/last-run.json`

## Related Contracts
- `planningops/contracts/problem-contract.md`
- `planningops/contracts/requirements-contract.md`
- `planningops/contracts/failure-taxonomy-and-retry-policy.md`
