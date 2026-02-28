---
title: UAP Core 7 Canonicalization Rollout Note
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures path canonicalization outcome and follow-up items for Core 7 docs.
owner: planningops
---

# UAP Core 7 Canonicalization Rollout Note

## Changed Paths
- `00-governance/2026-02-27-uap-monday-identity.meta.md` -> `00-governance/uap-monday-identity.meta.md`
- `90-navigation/2026-02-27-uap-document-map.navigation.md` -> `90-navigation/uap-document-map.navigation.md`
- `30-execution-plan/2026-02-27-uap-github-planningops-sync.execution-plan.md` -> `30-execution-plan/uap-github-planningops-sync.execution-plan.md`
- `00-governance/2026-02-27-uap-doc-governance.meta.md` -> `00-governance/uap-doc-governance.meta.md`
- `40-quality/2026-02-27-uap-planningops-tradeoff-decision-framework.quality.md` -> `40-quality/uap-planningops-tradeoff-decision-framework.quality.md`

## Compatibility Notes
- Core 7은 date-less canonical filename으로 고정했다.
- Non-core 문서는 기존 `YYYY-MM-DD-uap-*` 네이밍을 유지한다.
- status 체계는 `active/reference/deprecated`로 통일했다.
- 문서 링크/`related_docs`는 문서 파일 기준 상대경로(`./`, `../`)를 사용한다.
- 셸/CI 명령 경로는 repo 루트 기준 상대경로를 사용한다.

## Follow-up TODOs
- 외부 시스템(Notion/Wiki/Issue 본문)에서 dated Core 7 링크를 사용하는 경우 canonical 경로로 교체한다.
- CI 문서 검증 워크플로가 새 status 허용값(`active/reference/deprecated`)을 전제로 동작하는지 점검한다.
- Core 7 범위 밖 legacy dated 파일의 canonicalization 여부는 별도 ADR로 결정한다.
