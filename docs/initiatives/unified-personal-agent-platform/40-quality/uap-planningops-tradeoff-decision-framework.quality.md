---
doc_id: uap-planningops-tradeoff-decision-framework
title: UAP PlanningOps Trade-off Decision Framework
doc_type: quality
domain: quality
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
tags:
  - uap
  - planningops
  - tradeoff
  - decision
  - framework
summary: Provides a decision framework, scoring model, and impact map so deferred planning decisions can be made quickly with clear consequences.
related_docs:
  - ../30-execution-plan/uap-github-planningops-sync.execution-plan.md
  - ../30-execution-plan/2026-02-27-uap-planningops-lifecycle-scenarios.execution-plan.md
  - ../20-repos/monday/40-quality/2026-02-27-uap-issue-closure-matrix.quality.md
---

# UAP PlanningOps Trade-off Decision Framework

## Purpose
판단을 늦춰도 계획은 진행되게 하되, 나중에 결정할 때는 빠르고 일관되게 결론내릴 수 있도록 기준을 고정한다.

## Decisions Covered
- D1: Milestone granularity
- D2: Done source precedence
- D3: Trigger cadence
- D4: Manual override strictness
- D5: Webhook reaction mode

## Scoring Model
각 옵션을 1~5점으로 채점하고 가중합으로 비교한다.

### Criteria and weights
| Criterion | Weight | Meaning |
|---|---:|---|
| Reliability | 30 | 잘못된 상태/중복/드리프트를 줄이는가 |
| Operability | 20 | 장애 대응/재처리/운영 편의가 좋은가 |
| Simplicity | 20 | 계약/구현/문서 복잡도를 낮추는가 |
| Responsiveness | 15 | 상태 반영 지연이 짧은가 |
| Auditability | 15 | 이유/증빙/추적성이 높은가 |

가중합 공식:
- `total = Σ(score * weight)`
- 동점이면 `Reliability` 점수가 높은 옵션 우선

## Hard Constraints (Non-negotiable)
아래 조건 위반 옵션은 점수와 무관하게 탈락한다.
- 문서 SoT(one-way write) 훼손
- C2/C3/C8 식별자/상태 의미론 불안정
- 최소권한 원칙 위반
- dry-run 없이 apply 허용

## Option Cards and Direction Changes
### D1 Milestone granularity
| Option | Direction change | Gains | Costs |
|---|---|---|---|
| `initiative x repo` | 단순 운영 | 매핑 단순, 관리비용 낮음 | release 가시성 낮음 |
| `initiative x release x repo` | 세분 운영 | release 추적 정밀 | milestone 폭증, 매핑 복잡 |

### D2 Done source precedence
| Option | Direction change | Gains | Costs |
|---|---|---|---|
| `gate-first` | 품질 우선 | false success 최소화 | close 반영 지연 |
| `issue-first` | 속도 우선 | 협업 즉시성 | 품질 오판 가능성 증가 |
| `dual-confirm` | 엄격 통제 | 검증 신뢰성 최고 | 절차/운영 복잡도 상승 |

### D3 Trigger cadence
| Option | Direction change | Gains | Costs |
|---|---|---|---|
| `push + dispatch + nightly` | 실시간+백스톱 | 반영 빠름, 복구 경로 다양 | 워크플로 부하 |
| `push + nightly` | 단순화 | dispatch 의존 감소 | 긴급 수동 실행 한계 |
| `dispatch + nightly` | 수동 통제 중심 | 운영자 승인 흐름 명확 | 누락/지연 리스크 증가 |
| `nightly-only` | 배치 중심 | 예측 가능한 운영 | 반영 지연 큼 |

### D4 Manual override strictness
| Option | Direction change | Gains | Costs |
|---|---|---|---|
| `strict` | 자동화 중심 | drift 최소화 | 수동 대응 어려움 |
| `moderate` | 균형 | 운영 유연성과 통제 절충 | 정책 설계 필요 |
| `open-with-audit` | 사람 중심 | 현장 대응 빠름 | 충돌/드리프트 증가 |

### D5 Webhook reaction mode
| Option | Direction change | Gains | Costs |
|---|---|---|---|
| `observe-only` | 안정 우선 | preview 리스크 격리 | 실시간성 낮음 |
| `reactive-reconcile` | 준실시간 정합 | drift 탐지/복구 빠름 | 운영 복잡도 증가 |
| `reactive-apply` | 즉시 반영 | 반응성 최고 | 중복/레이스 리스크 증가 |

## Decision Flow (4 Steps)
1. `screen`: hard constraints 위반 옵션 제거
2. `score`: 기준 5개로 채점
3. `stress`: 실패 시나리오(L1~L12) 영향 확인
4. `select`: 총점/리스크/롤백성 기준 최종 선택

## Decision Pack Template
결정 항목마다 아래 1페이지 팩을 채운다.

| Field | Required content |
|---|---|
| Problem statement | 무엇을 왜 지금 결정해야 하는지 |
| Current default pain | 실제 사례, 빈도, 영향 |
| Options compared | 후보 옵션과 제외 이유 |
| Score table | 가중합 계산표 |
| Blast radius | C2/C3/C7/C8, 워크플로, 운영 변경 범위 |
| Rollbackability | 1주 내 되돌릴 수 있는지 |
| Recommendation | 제안 옵션 + 근거 |

## Scenario Fit Matrix
결정이 어떤 운영 시나리오에 영향을 주는지 매핑한다.
| Decision | High-impact scenarios |
|---|---|
| D1 | L2 (phase1-extended), L3/L4/L10 (deferred) |
| D2 | L5, L6, L9 |
| D3 | L1, L11, L12 |
| D4 | L8, L12 |
| D5 | L11, L12 |

Phase 1 운영 판단은 MVP pack(`L1,L5,L6,L7,L8,L11,L12`) 기준으로 우선 수행한다.
Phase 1 Extended pack(`L2,L9`)은 MVP 안정화 후 평가한다.
Phase 2 Deferred pack(`L3,L4,L10`)은 milestone granularity/ownership 정책이 확정된 후 평가한다.

Phase 1 Extended 진입 기준:
- MVP 운영 2주 연속 KPI 충족
- duplicate creation 0% 유지
- permission mismatch 주간 1회 이하

## Re-evaluation Triggers
- 결정 후 2주간 KPI를 관찰해 재검토 여부 판단
- 아래 중 하나면 재평가:
  - `drift_recovery_time_p95` 목표 초과 3회 이상
  - `manual_override_frequency` 주 5회 초과
  - `false_positive_close` 1건 이상
  - secondary rate limit 빈발

## Anti-Patterns to Avoid
- 점수표 없이 감으로 결정
- rollback 계획 없는 옵션 채택
- 단기 속도만 보고 reliability 희생
- 운영 증거 없이 정책 변경

## Output Contract
각 판단은 아래 산출물을 남긴다.
- `planningops/artifacts/decision-pack/<decision_id>.md`
- `planningops/artifacts/decision-score/<decision_id>.json`
- 계획 문서의 `Deferred Decisions` 업데이트 기록
