# ADR-0001: Ralph Loop Harness Topology

- Status: Accepted
- Date: 2026-02-28
- Owner: @JJBINY
- Related Issue: #8

## Context
Ralph Loop issue-resolution MVP를 구현하기 위해 하네스 토폴로지를 결정해야 한다.
선택지:
1. dedicated harness repository
2. existing repo internal harness
3. local scripts first

## Decision Matrix
| Option | Pros | Cons | Risk | Time-to-first-loop |
|---|---|---|---|---|
| Dedicated repo | 경계 명확, 배포 독립 | 초기 운영비용 큼 | 중간 | 느림 |
| Internal harness | 컨텍스트 접근 빠름 | 책임 혼합 가능 | 중간~높음 | 중간 |
| Local scripts first | 즉시 실행 가능, 단순함 | 재사용/운영 자동화 제한 | 낮음 | 가장 빠름 |

## Decision
Phase 1은 `Local scripts first`를 채택한다.

## Storage and Ownership
- harness source root: `planningops/`
- contracts: `planningops/contracts/`
- quality checks: `planningops/quality/`
- runtime scripts: `planningops/scripts/`
- ADR ownership: PlanningOps DRI (`@JJBINY`)

## Re-evaluation Triggers
아래 중 하나가 발생하면 topology 재결정 이슈를 연다.
- 주당 10회 이상 루프 실행
- 동일 실패 유형 3회 이상 반복
- 다중 레포 동시 처리 요구 발생
- 로컬 스크립트 권한/보안 제약으로 운영 불가 발생

## Consequences
- 단기: 구현 속도 상승, 검증 루프 빠르게 확보
- 중기: 운영 자동화 요구가 증가하면 internal 또는 dedicated repo로 분리 필요
