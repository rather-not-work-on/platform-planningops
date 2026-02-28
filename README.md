# platform-planningops

Org-level 단일 계획 저장소입니다.

이 레포는 `rather-not-work-on` 조직의 계획/설계/추적 문서를 위한 canonical source이며, `monday` 같은 실행 레포와 독립적으로 운영합니다.

## Scope

- 포함: 브레인스토밍, 아키텍처, 실행계획, 품질 게이트 문서
- 포함: 계획 검증/카탈로그 자동화 스크립트
- 제외: 제품 런타임 코드, 서비스 배포 코드

## Current Initiative

- `docs/initiatives/unified-personal-agent-platform`

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
```

## Quick Start

```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh sync
```

## Working Rules

- 문서 참조는 상대경로를 사용합니다.
- 경로/구조 변경 시 `README`와 `90-navigation`을 함께 갱신합니다.
- 변경 후 `uap-docs.sh sync`를 실행해 카탈로그와 링크 무결성을 확인합니다.
- PR에서는 `.github/workflows/uap-docs-check.yml`로 문서 검증이 자동 실행됩니다.
- org/repo/agent 식별자 변경은 identity 문서를 먼저 갱신합니다.

## Source of Truth Policy

- 계획의 단일 SoT는 이 레포 문서입니다.
- GitHub Issues/Projects 연동은 문서 -> 트래커 단방향 동기화를 기본으로 합니다.
- 실행 레포(`monday`, `platform-*`)는 이 레포의 계획을 참조해 구현합니다.
