# ADR-0002: Local-First Runtime Profiles and Naming Freeze

- Status: Accepted
- Date: 2026-02-28
- Owner: @JJBINY
- Related Issues: #14, #18, #19, #20, #21

## Context
Topology expansion decisions were required for:
1. repository creation policy,
2. Executor/Worker naming,
3. per-task provider/runtime flexibility,
4. local-first deployment with easy Oracle Cloud migration.

## Decision
1. Create the following repositories and operate them as public:
   - `rather-not-work-on/platform-contracts`
   - `rather-not-work-on/platform-provider-gateway`
   - `rather-not-work-on/platform-observability-gateway`
2. Freeze naming contract:
   - External term: `Executor`
   - Internal implementation term: `Worker`
3. Support per-task runtime overrides via profile catalog:
   - `planningops/config/runtime-profiles.json`
   - task key format: `issue-<number>` (with `default` fallback)
4. Adopt local-first runtime baseline for LiteLLM/LangFuse/NanoClaw and prepare profile-based migration path to Oracle Cloud.

## Consequences
- Short-term:
  - Faster local verification loop with consistent contracts.
  - No hard coupling to a single infrastructure target.
- Mid-term:
  - Oracle migration becomes configuration-level change for selected tasks.
  - Gate evidence contract remains unchanged across runtime environments.
