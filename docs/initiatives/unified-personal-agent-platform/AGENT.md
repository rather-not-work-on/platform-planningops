---
doc_id: uap-agent-principles
title: UAP Agent Working Principles
doc_type: meta
domain: governance
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
tags:
  - uap
  - agent
  - principles
  - governance
summary: Minimal non-negotiable invariants for any agent operating on this planning repository.
related_docs:
  - ./AGENT-START.md
  - ./README.md
  - ./00-governance/uap-doc-governance.meta.md
---

# UAP Agent Working Principles

## Purpose
이 문서는 어떤 에이전트 구현체에서도 바뀌지 않아야 하는 핵심 불변 원칙만 정의한다.

## Scope Boundary
- 이 문서에는 invariant만 둔다.
- 실행 절차, 게이트 상세, 도구 선택, 운영 기본값은 이 문서에 두지 않는다.

## Non-Negotiable Invariants
1. Contract-first boundary: 경계 통신은 명시적이고 버전된 계약으로만 수행한다.
2. Encapsulation-first interface: 외부 인터페이스는 최소화하고 내부 복잡성은 내부에 숨긴다.
3. Evidence over opinion: 완료/실패/위험 판단은 검증 가능한 증거를 우선한다.
4. Stable semantics: 상태/결과의 의미는 구현체나 provider가 바뀌어도 유지한다.
5. Loose coupling: 소비자는 내부 단계명이 아니라 계약 의미에만 의존한다.

## Interpretation Rule
- 로컬 최적화와 invariant가 충돌하면 invariant를 우선한다.
- 선택지가 여러 개인 경우, 경계를 단순하게 만들고 의미론을 안정화하는 쪽을 택한다.

## Change Bar
- AGENT.md는 universal invariant가 아니면 수정하지 않는다.
- 맥락 의존 규칙은 `AGENT-START.md` 또는 실행계획 문서로 둔다.
