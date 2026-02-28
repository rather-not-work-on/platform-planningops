---
title: UAP Workbench Hub
type: hub
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Initiative-scoped workbench for ephemeral planning artifacts, reviews, and audits before canonical promotion.
---

# UAP Workbench Hub

이 디렉토리는 `unified-personal-agent-platform` initiative의 비영속 산출물을 보관한다.

## Layout
- `brainstorms/`: 아이디어 탐색 및 접근 옵션
- `plans/`: 실행 계획 초안/수정 계획
- `reviews/`: 리뷰 로그 및 이슈 추적 기록
- `audits/`: 마이그레이션 맵, 검증 로그, 롤아웃 노트

## Contract
- workbench 문서는 운영 중 생성되는 산출물이다.
- canonical source of truth는 `docs/initiatives/unified-personal-agent-platform` 문서다.
- canonical 문서가 workbench 문서를 규범으로 참조하면 안 된다.
- 승격 시 canonical 문서를 갱신하고 workbench 문서는 `status: reference`로 전환한다.

## Validation
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile workbench
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
```

## Active Plans
- [Ralph Loop Issue Resolution Loop Plan](./plans/2026-02-28-plan-ralph-loop-issue-resolution-loop-plan.md)
