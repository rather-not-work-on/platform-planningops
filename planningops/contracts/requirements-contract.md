# Ralph Loop Requirements Contract

## Functional Requirements
1. Intake must select only `Todo` issues and enforce `execution_order` ascending.
2. Intake must block issues with unsatisfied `depends_on`.
3. Each loop must produce deterministic artifacts for the same input and commit.
4. Verification must emit one verdict from `pass|fail|inconclusive`.
5. Feedback must post result comments to issue and update project status.

## Non-Functional Requirements
1. Idempotency: repeated execution for same issue+commit must not duplicate updates.
2. Time bounds: loop timeout and retry limit must be configurable.
3. Traceability: every state transition must be recorded in `transition-log.ndjson`.
4. Reproducibility: dry-run mode must simulate updates without remote writes.

## Definition of Ready (DoR)
- issue has execution metadata (`execution_order`, `depends_on`),
- ECP reference exists,
- required contracts are resolvable,
- runtime permissions are valid.

## Definition of Done (DoD)
- code/doc patch created,
- verification verdict generated,
- issue comment posted,
- project feedback update attempted and result logged,
- transition log appended.
