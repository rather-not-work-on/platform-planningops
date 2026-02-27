---
doc_id: uap-monday-identity
title: UAP Project Identity (M.O.N.D.A.Y.)
doc_type: meta
domain: governance
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
tags:
  - uap
  - identity
  - monday
  - governance
summary: Canonical identity source for project naming, repository namespace policy, and GitHub org/repository coordinates.
related_docs:
  - ../README.md
  - ../AGENT-START.md
  - ./2026-02-27-uap-doc-governance.meta.md
---

# UAP Project Identity (M.O.N.D.A.Y.)

## Purpose
프로젝트 식별자 관련 정보의 single source of truth를 제공한다.

## Canonical Identity
- Agent name: `M.O.N.D.A.Y.`
- Expanded name: `Maybe Overengineered Neural Digital Assistant Youth`
- GitHub organization: `rather-not-work-on`
- Primary repository: `monday`
- Repository coordinate: `rather-not-work-on/monday`

## Repository Naming Policy
- Agent-specific repos: `monday-*` 또는 단일 에이전트 앱명(`monday`)
- Shared platform repos: `platform-*`
- 목표: 이름만 보고 소유 범위(에이전트 전용 vs 조직 공용)를 즉시 구분

## Current Canonical Repository Set
- Agent app: `rather-not-work-on/monday`
- Planning and tracking: `rather-not-work-on/platform-planningops`
- Shared contracts: `rather-not-work-on/platform-contracts`
- Shared LLM gateway: `rather-not-work-on/platform-provider-gateway`
- Shared observability gateway: `rather-not-work-on/platform-observability-gateway`

## Usage Rule
- 문서, 이슈, 자동화 스크립트, 리포 연동 시 식별자 표기는 본 문서를 기준으로 한다.
- 다른 문서에는 중복 정의하지 않고 본 문서를 링크로 참조한다.

## Change Rule
- org/repo/agent naming 변경 시 이 문서를 먼저 갱신한다.
- 변경 후 `README`, `AGENT-START`, `90-navigation` 링크/표기를 동기화한다.
