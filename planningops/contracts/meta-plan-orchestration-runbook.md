# Meta Plan Orchestration Runbook

## Purpose
Provide a deterministic operating procedure for MPG v1 graph validation, ready-set orchestration, and evidence synchronization in a local-first Kanban model.

## Scope
- Applies to `planningops` control-plane operation.
- Covers meta graph build/orchestrate flow, CI hard-gates, and replan escalation handoff.
- Excludes external infra runtime provisioning details.

## Prerequisites
1. Graph contract and schema are present:
   - `planningops/contracts/meta-plan-graph-contract.md`
   - `planningops/schemas/meta-plan-graph.schema.json`
2. Sample or live graph contract exists:
   - `planningops/fixtures/meta-plan-graph-sample.json`
3. Tooling baseline:
   - `gh` authenticated (for project/issue integration flows)
   - `python3` available

## Canonical Commands
1. Graph schema contract check:
   - `bash planningops/scripts/test_meta_plan_graph_schema_contract.sh`
2. Graph builder contract check:
   - `bash planningops/scripts/test_build_meta_plan_graph_contract.sh`
3. Orchestrator contract check:
   - `bash planningops/scripts/test_meta_plan_orchestrator_contract.sh`
4. Build graph artifact:
   - `python3 planningops/scripts/build_meta_plan_graph.py --contract-file planningops/fixtures/meta-plan-graph-sample.json --strict --output planningops/artifacts/meta-plan/meta-graph.json`
5. Run orchestrator dry-run:
   - `python3 planningops/scripts/meta_plan_orchestrator.py --meta-graph-contract planningops/fixtures/meta-plan-graph-sample.json --mode dry-run --strict --meta-graph-output planningops/artifacts/meta-plan/meta-graph.json --output planningops/artifacts/meta-plan/meta-execution-report.json`

## Operating Procedure
### 1) Preflight
Run:
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
- `bash planningops/scripts/test_module_readme_contract.sh`

Gate:
- Any failure blocks orchestration.

### 2) Graph Validity
Run schema + builder checks:
- `bash planningops/scripts/test_meta_plan_graph_schema_contract.sh`
- `bash planningops/scripts/test_build_meta_plan_graph_contract.sh`

Expected:
- no node/edge duplication
- no unknown edge references
- no cycle for `depends_on|blocks`

### 3) Ready-Set Derivation
Run:
- `python3 planningops/scripts/build_meta_plan_graph.py ...`

Inspect:
- `planningops/artifacts/meta-plan/meta-graph.json`
  - `ready_set`
  - `blocked_nodes`
  - `reasons`

### 4) Orchestration Dry-Run
Run:
- `python3 planningops/scripts/meta_plan_orchestrator.py ... --mode dry-run ...`

Inspect:
- `planningops/artifacts/meta-plan/meta-execution-report.json`
  - selected nodes
  - simulated pipeline commands
  - verdict/reasons

### 5) Apply (Controlled)
When dry-run is stable, run:
- `python3 planningops/scripts/meta_plan_orchestrator.py --meta-graph-contract planningops/fixtures/meta-plan-graph-sample.json --mode apply --strict --meta-graph-output planningops/artifacts/meta-plan/meta-graph.json --output planningops/artifacts/meta-plan/meta-execution-report.json`

Rule:
- keep `--strict` enabled
- stop immediately on first failed pipeline command

## Escalation and Replan
Escalate when:
1. graph validation fails repeatedly
2. orchestrator pipeline repeatedly fails on same reason family
3. downstream loop evidence reports `inconclusive_x2` or `same_reason_x3`

Required actions:
1. mark impacted node as `replan_required`
2. attach evidence paths in issue/project comment
3. create/refresh recovery plan before next apply run

## CI Integration
Graph validity gates are wired in:
- `.github/workflows/federated-ci-matrix.yml`
- `planningops/scripts/federation/federated_ci_matrix_local.sh` (canonical)
- `planningops/scripts/federated_ci_matrix_local.sh` (compatibility wrapper)

Required CI checks include:
- meta graph schema/builder/orchestrator contract tests
- graph build + orchestrator dry-run artifact generation

## Evidence Paths
- `planningops/artifacts/meta-plan/meta-graph.json`
- `planningops/artifacts/meta-plan/meta-execution-report.json`
- `planningops/artifacts/validation/plan-compile-report.json`
- `planningops/artifacts/validation/plan-projection-report.json`

## Rollback
If orchestration apply introduces instability:
1. switch to `--mode dry-run`
2. revert to last known-good graph contract revision
3. rerun preflight + graph validity checks
4. re-enable apply only after pass evidence is regenerated
