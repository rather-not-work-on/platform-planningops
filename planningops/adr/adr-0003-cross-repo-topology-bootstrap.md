# ADR-0003: Cross-Repo Topology Bootstrap

- Status: Accepted
- Date: 2026-02-28
- Owner: @JJBINY
- Related Issues: #14, #16, #18, #19

## Context
Ralph Loop/PlanningOps MVP 이후 단계에서는 contract/provider/observability surface가 독립 레포로 운영되어야 한다.
토폴로지 경계가 모호하면 계약 drift와 실행 흐름 충돌이 반복된다.

## Decision
Execution topology를 4-plane으로 고정한다.

1. Control plane:
   - `rather-not-work-on/platform-planningops`
   - canonical planning docs, sync orchestration, gate evidence baseline
2. Data/contract plane:
   - `rather-not-work-on/platform-contracts`
   - C1~C8 schema, compatibility, version policy
3. Infra plane:
   - `rather-not-work-on/platform-provider-gateway`
   - LiteLLM/provider routing policy, C4 invocation contract
   - `rather-not-work-on/platform-observability-gateway`
   - LangFuse/trace/log pipeline, C5 observability contract
4. Runtime plane:
   - `rather-not-work-on/monday`
   - Executor/Worker runtime, scheduler, orchestration integration

## Repository Policy
- Bootstrapped repositories are public for visibility and cross-repo coordination:
  - `platform-contracts`
  - `platform-provider-gateway`
  - `platform-observability-gateway`
- Migration-sensitive runtime behavior is managed via profile configuration, not contract shape changes.

## DRI and Escalation Contract
| Surface | Primary DRI | Escalation Owner |
|---|---|---|
| planningops control plane | PlanningOps DRI | Initiative Owner |
| platform-contracts | Contracts DRI | PlanningOps DRI |
| platform-provider-gateway | Provider Gateway DRI | Runtime DRI |
| platform-observability-gateway | Observability DRI | PlanningOps DRI |
| monday runtime | Runtime DRI | Initiative Owner |

## Consequences
- Benefits:
  - contract and runtime responsibilities are separated explicitly
  - multi-repo sync expansion can proceed with stable target surfaces
- Trade-offs:
  - additional repository lifecycle overhead (branch protection, CODEOWNERS, release discipline)
  - cross-repo coordination is mandatory for C1~C8 changes
