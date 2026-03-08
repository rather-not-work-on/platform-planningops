# Node Workspace Bootstrap Contract

## Purpose
Define a deterministic, local-first bootstrap contract for TypeScript workspaces across federated execution repos.

## Scope
- Governing repo: `rather-not-work-on/platform-planningops`
- In-scope execution repos:
  - `rather-not-work-on/monday`
  - `rather-not-work-on/platform-provider-gateway`
  - `rather-not-work-on/platform-observability-gateway`

## Baseline Requirements
1. Global `pnpm` installation must not be assumed.
2. The canonical package manager invocation must be `npm exec --yes pnpm@9.15.9 --`.
3. Every runtime workspace root must contain:
   - `package.json`
   - `pnpm-workspace.yaml`
   - `tsconfig.base.json`
4. Every runtime workspace root `package.json` must expose `scripts.typecheck`.
5. Every runtime workspace root must declare `typescript` as a dev dependency for the baseline typecheck path.
6. Every runtime workspace must commit `pnpm-lock.yaml` once the first successful local bootstrap is established.
7. Local bootstrap must use the non-global invocation path before CI requirements are hardened.
8. CI installation must use the same pinned `pnpm` version with `--frozen-lockfile`.
9. Python harnesses remain harnesses; Node workspace bootstrap must not rewrite harness ownership boundaries.

## Source of Truth
- Policy config: `planningops/config/node-workspace-bootstrap-policy.json`

## Verification
- Policy validator: `planningops/scripts/validate_node_workspace_policy.py`
- Contract test: `planningops/scripts/test_node_workspace_bootstrap_contract.sh`
- Expected downstream evidence:
  - `pnpm-lock.yaml`
  - successful `typecheck` execution through the pinned local invocation path

## Operational Notes
- The contract standardizes toolchain entry, not runtime business logic.
- Execution repos may add more root scripts, but they must preserve the canonical `typecheck` entry.
- If a repo cannot satisfy this contract without extra shared packages or SDK choices, it must re-enter `ready-contract` with failure evidence rather than improvising bootstrap behavior.
