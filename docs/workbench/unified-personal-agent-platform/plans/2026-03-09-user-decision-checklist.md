---
title: plan: User Decision Checklist For Next Runtime Waves
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Lists the small set of decisions that should remain user-owned while the autonomous PlanningOps loop continues on contract, topology, and validation work.
tags:
  - uap
  - decisions
  - user-owned
  - runtime
---

# User Decision Checklist For Next Runtime Waves

## Purpose

Separate user-owned decisions from agent-owned execution so autonomous work can continue without stepping on high-impact choices.

## You Should Decide

### 1. First MONDAY UX

Pick the first end-to-end experience that must work before broader expansion.

Recommended shape:
- `planningops issue -> monday run -> provider call -> observability event -> result summary`

What to answer:
- what starts the run
- what the run must produce
- what counts as success
- what counts as an acceptable degraded fallback

### 2. Provider Priority Policy

Pick the default provider order for the first runtime.

What to answer:
- default primary provider
- default fallback provider
- whether local LLM is fallback-only or allowed as primary
- whether per-task override is allowed

### 3. Local Infra Boundary

Pick the minimum local infra topology you want me to assume first.

What to answer:
- LiteLLM location: same machine only vs separate local service
- Langfuse location: same machine only vs separate local service
- artifact storage default: local filesystem vs MinIO/S3-compatible vs OCI object storage
- whether OCI is only later migration target or also an early optional path

### 4. Secrets Handling Policy

Pick how local secrets should be loaded during development.

What to answer:
- `.env` per repo vs shared local secret store
- whether automation may read local `.env` files
- whether provider credentials and observability credentials are separated

## Suggested Reply Format

Reply in this shape:

1. first_ux:
2. provider_primary:
3. provider_fallback:
4. per_task_override:
5. litellm_topology:
6. langfuse_topology:
7. artifact_storage_default:
8. oci_role:
9. secrets_loading:
10. automation_secret_access:

## Until You Decide

I will continue with:
- contract clarification
- topology refinement
- interface wiring freeze
- validation automation
- repo hygiene and CI hardening

I will avoid:
- hard-coding provider precedence as a product decision
- assuming irreversible local infra topology
- embedding secret-loading behavior that you did not approve
