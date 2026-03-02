---
status: complete
priority: p1
issue_id: "011"
tags: [code-review, reliability, gate, automation, planningops]
dependencies: []
---

# Enforce Non-Zero Exit on Failing Track1 Gate Dry-Run

Script reports `fail`/`inconclusive` gate verdicts but still exits with status code `0`, allowing CI or automation pipelines to treat a failed gate as successful.

## Findings

- `planningops/scripts/run_track1_gate_dryrun.py:262` always returns `0`.
- Current behavior observed in generated report:
  - `planningops/artifacts/validation/track1-gate-dryrun-report.json` has `"final_verdict": "inconclusive"`.
  - command exit code remained successful.
- Impact: Gate enforcement can be bypassed unintentionally when pipelines rely on process exit status.

## Proposed Solutions

### Option 1: Strict-by-default exit contract

**Approach:** Return non-zero when `final_verdict != pass`.

**Pros:**
- Strong safety default
- CI and local automation behavior align with gate policy

**Cons:**
- May break current workflows that expect report-only behavior

**Effort:** Small

**Risk:** Medium

---

### Option 2: Add `--strict` flag (default false)

**Approach:** Keep current behavior by default, fail only when `--strict` is passed.

**Pros:**
- Backward compatible
- Controlled rollout

**Cons:**
- Easy to forget strict mode in critical pipelines

**Effort:** Small

**Risk:** Medium

---

### Option 3: Environment-based strict mode

**Approach:** Strict mode enabled automatically in CI env (`CI=true`).

**Pros:**
- Safe default in automated pipelines
- Flexible local dry-run behavior

**Cons:**
- Hidden behavior can confuse maintainers

**Effort:** Small

**Risk:** Low

## Recommended Action

완료. `--strict` 플래그를 도입해 `final_verdict != pass`일 때 non-zero exit를 강제했고, 회귀 테스트로 strict/non-strict 계약을 고정했다.

## Technical Details

**Affected files:**
- `planningops/scripts/run_track1_gate_dryrun.py:247-262`

## Resources

- `planningops/artifacts/validation/track1-gate-dryrun-report.json`
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-02-plan-two-track-hard-gates-execution-plan.md`

## Acceptance Criteria

- [x] Script exits non-zero when strict gate evaluation fails (`fail` or `inconclusive`).
- [x] Behavior is documented (strict default or flag-based).
- [x] CI recipe explicitly uses the intended mode.
- [x] Regression test covers exit code semantics.

## Work Log

### 2026-03-02 - Review Finding Created

**By:** Codex

**Actions:**
- Reviewed gate dry-run script execution semantics.
- Verified mismatch between verdict and process exit behavior.
- Documented remediation options.

**Learnings:**
- Gate verdict without exit contract is insufficient for automated enforcement.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/run_track1_gate_dryrun.py`에 `--strict` 플래그를 추가했다.
- strict 모드에서 `final_verdict`가 `pass`가 아니면 exit code `1`을 반환하도록 수정했다.
- `planningops/scripts/test_track1_gate_dryrun_contract.sh`를 추가해 strict/non-strict 동작을 검증했다.

**Learnings:**
- report-only 기본값을 유지하되 strict를 명시하면 로컬/CI 정책을 분리해 점진적으로 전환할 수 있다.

## Notes

- This is merge-blocking for any pipeline that assumes exit code enforces gate policy.
