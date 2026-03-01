# platform-planningops

Org-level 단일 계획 저장소입니다.

이 레포는 `rather-not-work-on` 조직의 계획/설계/추적 문서를 위한 canonical source이며, `monday` 같은 실행 레포와 독립적으로 운영합니다.
문서는 `canonical`과 `workbench`를 분리해 운영합니다.

## Scope

- 포함: 브레인스토밍, 아키텍처, 실행계획, 품질 게이트 문서
- 포함: 계획 검증/카탈로그 자동화 스크립트
- 제외: 제품 런타임 코드, 서비스 배포 코드

## Current Initiative

- `docs/initiatives/unified-personal-agent-platform`
- `docs/workbench/unified-personal-agent-platform`

핵심 진입점:

1. `docs/initiatives/unified-personal-agent-platform/AGENT-START.md`
2. `docs/initiatives/unified-personal-agent-platform/README.md`

상세 읽기 순서와 문서 관계는 initiative README의 `Recommended Reading Flow`와 `90-navigation` 문서를 단일 기준으로 사용합니다.

## Repository Layout

```text
platform-planningops/
  docs/
    initiatives/
      unified-personal-agent-platform/
        00-governance/
        10-brainstorm/
        20-architecture/
        20-repos/
        30-domains/
        30-execution-plan/
        40-quality/
        90-navigation/
    workbench/
      unified-personal-agent-platform/
        brainstorms/
        plans/
        reviews/
        audits/
```

## Quick Start

```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile canonical
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh sync --profile all
python3 planningops/scripts/refactor_hygiene_loop.py --policy-file planningops/config/refactor-hygiene-policy.json
python3 planningops/scripts/refactor_hygiene_multi_repo.py --config-file planningops/config/refactor-hygiene-multi-repo.json --workspace-root .
```

## Working Rules

- canonical 문서는 `docs/initiatives/...` 하위에서만 운영합니다.
- 비영속 작업 산출물은 `docs/workbench/...` 하위에서만 운영합니다.
- 레거시 경로(`docs/brainstorms`, `docs/plans`)는 재생성 금지이며, 검증 시 실패 처리됩니다.
- 문서 참조는 상대경로를 사용합니다.
- 경로/구조 변경 시 `README`와 `90-navigation`을 함께 갱신합니다.
- 변경 후 `uap-docs.sh sync`를 실행해 카탈로그와 링크 무결성을 확인합니다.
- PR에서는 `.github/workflows/uap-docs-check.yml`로 문서 검증이 자동 실행됩니다.
  - trigger: `README.md`, `docs/brainstorms/**`, `docs/plans/**`, `docs/initiatives/unified-personal-agent-platform/**`, `docs/workbench/unified-personal-agent-platform/**`
- org/repo/agent 식별자 변경은 identity 문서를 먼저 갱신합니다.
- 기본 운영은 `PR-first`입니다. 직접 `main`에 푸시하지 않습니다.
- PR 본문은 `.github/pull_request_template.md` 형식을 따릅니다.
- 리뷰 소유자는 `.github/CODEOWNERS`를 기준으로 지정합니다.
- PR 구조/이슈 연결 검증은 `.github/workflows/pr-review-gate.yml`에서 수행합니다.

## PR and Review Policy

- 브랜치: `feat/*`, `fix/*`, `docs/*`, `chore/*` 중 하나를 사용합니다.
- 병합 기준:
  - PR 본문 템플릿 섹션 충족
  - 관련 이슈 링크 포함
  - 필수 검증 통과(`uap-docs-check`, `pr-review-gate`, 변경 범위별 추가 CI)
  - CODEOWNERS 리뷰 승인

## Validation Guards

- `uap-docs.sh check/sync`는 실행 전에 preflight guard를 수행합니다.
- legacy path guard:
  - `docs/brainstorms`, `docs/plans` 존재 시 즉시 실패합니다.
- root README contract guard:
  - `docs/workbench/unified-personal-agent-platform` 경로 문구가 없으면 실패합니다.
  - `uap-docs.sh check --profile canonical` 명령 문구가 없으면 실패합니다.
  - `uap-docs.sh check --profile all` 명령 문구가 없으면 실패합니다.

Guard 실패 시 위반 항목을 수정한 뒤 `uap-docs.sh check --profile all`을 다시 실행합니다.

## Source of Truth Policy

- 계획의 단일 SoT는 이 레포 문서입니다.
- GitHub Issues/Projects 연동은 문서 -> 트래커 단방향 동기화를 기본으로 합니다.
- 실행 레포(`monday`, `platform-*`)는 이 레포의 계획을 참조해 구현합니다.
