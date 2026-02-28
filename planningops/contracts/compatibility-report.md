# C1~C5 Compatibility Report

## Versioning Rules
- major: required field removal/rename, enum meaning changes
- minor: optional field addition
- patch: non-semantic correction (docs/comments/examples)

## Guardrails
- required keys in C1~C5 cannot be removed without major bump
- enum additions require consumer fallback checks
- unknown optional keys must not break validation

## Current Baseline
- contract set: C1, C2, C3, C4, C5
- baseline version: `1.0.0`
- validation command:

```bash
python3 planningops/scripts/validate_contracts.py
```

## Change Checklist
- [ ] schema diff reviewed
- [ ] compatibility impact classification assigned (major/minor/patch)
- [ ] fixture validation passes
- [ ] downstream contract consumers acknowledged
