---
title: plan: Bootstrap Pilot Metadata and DRI Assignment
type: plan
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Documents pilot repositories, project metadata catalog location, and DRI ownership mapping for M0 bootstrap.
compacted_into: docs/initiatives/unified-personal-agent-platform/40-quality/uap-bootstrap-memory-compaction-summary.quality.md
---

# plan: Bootstrap Pilot Metadata and DRI Assignment

## Pilot Repositories (M0)
- `rather-not-work-on/platform-planningops`
- `rather-not-work-on/monday`

## Project Metadata Catalog
- canonical path: `planningops/config/project-field-ids.json`
- 포함 항목:
  - project number/id
  - field id/status option id
  - component option id
  - lane option id

## DRI Mapping (Initial)
| Track | DRI | Backup |
|---|---|---|
| PlanningOps | `@JJBINY` | `@JJBINY` |
| Contracts | `@JJBINY` | `@JJBINY` |
| Runtime | `@JJBINY` | `@JJBINY` |
| O11y | `@JJBINY` | `@JJBINY` |
| Operations | `@JJBINY` | `@JJBINY` |

Note:
- 초기 부트스트랩 단계에서는 단일 DRI로 시작한다.
- multi-owner 전환 시 이 문서를 갱신하고 프로젝트 필드 `assignee` 정책을 함께 수정한다.

## Preflight Checklist Template
- [ ] pilot repo 2개 접근 권한 확인
- [ ] project field catalog 최신화 확인
- [ ] `uap-docs.sh check --profile all` 통과
- [ ] Gate A pre-check audit 로그 생성
- [ ] M0 checkpoint evidence 포맷에 맞춘 결과 기록
