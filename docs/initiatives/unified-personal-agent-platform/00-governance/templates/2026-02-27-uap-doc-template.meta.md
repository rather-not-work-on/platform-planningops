---
doc_id: uap-doc-template
title: UAP Document Template
doc_type: meta
domain: governance
status: active
date: 2026-02-27
updated: 2026-02-27
initiative: unified-personal-agent-platform
tags:
  - uap
  - template
  - governance
summary: Reusable template snippet for creating new UAP documents with required frontmatter.
related_docs:
  - ../uap-doc-governance.meta.md
  - ../scripts/uap-new-doc.sh
---

# UAP Document Template

Use `uap-new-doc.sh` for the default flow.

```md
---
doc_id: uap-<subject-slug>
title: <Document Title>
doc_type: <brainstorm|simulation|strategy|architecture|execution-plan|quality|navigation|meta>
domain: <governance|discovery|architecture|planning|quality|navigation>
status: reference
date: YYYY-MM-DD
updated: YYYY-MM-DD
initiative: unified-personal-agent-platform
summary: <One-line summary>
related_docs:
  - ./README.md
---

# <Document Title>

## Context
- TODO

## Decision
- TODO

## Next Step
- TODO
```
