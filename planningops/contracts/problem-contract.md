# Ralph Loop Problem Contract

## Objective
Resolve `platform-planningops` issues autonomously in repeatable loops with explicit verification and feedback.

## Inputs (Required)
- `issue_number`
- `issue_title`
- `issue_body`
- `execution_order`
- `depends_on`
- `ecp_ref` (Execution Context Pack path)
- `contract_refs` (C1~C8, policy docs)

## Outputs (Required)
- `patch_summary.md`
- `simulation-report.md`
- `verification-report.json`
- `transition-log.ndjson`
- `issue_comment_payload.md`

## Success Condition
A loop is successful only when:
1. required outputs are generated,
2. verification verdict is `pass`,
3. GitHub feedback update is applied (issue comment + project field update),
4. no contract violation is reported.

## Failure Condition
A loop fails when one of these holds:
- required input is missing,
- required output artifact is missing,
- verification verdict is `fail`,
- feedback update cannot be persisted after retry policy.

## Inconclusive Condition
A loop is `inconclusive` when execution partially completes but:
- verification evidence is insufficient, or
- dependency/permission constraint blocks final verdict.
