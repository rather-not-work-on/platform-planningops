---
title: UAP Workbench Separation Rollout Note
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Records rollout status and follow-up actions for canonical/workbench topology separation.
---

# UAP Workbench Separation Rollout Note

## Executed
- 루트 `docs/brainstorms/*`, `docs/plans/*`, `docs/plans/assets/*`를 initiative-scoped workbench 경로로 이동했다.
- canonical 문서 허브(`README`, `AGENT-START`, `uap-document-map`, `uap-doc-governance`)를 canonical/workbench 분리 모델로 갱신했다.
- `uap-docs.sh`에 `--profile canonical|workbench|all` 검증 옵션을 추가했다.

## Operational Contract
- canonical source: `docs/initiatives/unified-personal-agent-platform/*`
- workbench source: `docs/workbench/unified-personal-agent-platform/*`
- `sync`는 canonical catalog 생성 후 profile 기반 검증을 수행한다.

## Follow-up
- CI에서 `check --profile all`을 주기 실행할지 여부를 운영 정책으로 확정한다.
- workbench 카드(`component`) 운영 결과를 바탕으로 GitHub Project 필드 최소 집합을 재평가한다.
