# Autonomous Run Policy Contract

## Goal
Define autonomous loop control as convergence/risk/quality bounded execution, not clock-time bounded execution.

## Control Axis
- Primary control axis: convergence quality and risk gates.
- Secondary metadata: elapsed runtime (`max_duration_minutes`) and token usage.
- Prohibited interpretation: fixed-duration target such as "run N hours regardless of quality state".

## Continue Conditions
Autonomous run may continue only while all are true:
1. latest verification verdict is not `fail`,
2. escalation gate is not auto-paused,
3. lease lock ownership remains valid,
4. required reliability evidence is present and valid.

## Stop Conditions
Autonomous run must stop immediately when any occurs:
1. quality gate failure (`verdict=fail`),
2. escalation trigger (`same_reason_x3` or `inconclusive_x2`),
3. safety conflict (`lock_owner_drift` / `heartbeat_refresh_failed` / lock conflict),
4. missing or invalid required evidence for pass-path verification.

## Replan Linkage
- Stop by escalation or safety conflict sets `replanning_triggered=true`.
- Runner must emit:
  - transition-log event with replanning flag,
  - replan decision artifact for auto-pause path.

## Testability Mapping
- Escalation trigger behavior:
  - implementation: `planningops/scripts/issue_loop_runner.py` (`evaluate_escalation`)
  - regression: `planningops/scripts/test_escalation_gate.sh`
- Runtime safety stop behavior:
  - implementation: `planningops/scripts/issue_loop_runner.py` (`run_with_runtime_heartbeat`)
  - regression: `planningops/scripts/test_lease_lock_watchdog.sh`
- Verification evidence stop behavior:
  - implementation: `planningops/scripts/verify_loop_run.py`
  - regression: `planningops/scripts/test_verify_loop_run_hard_gate_contract.sh`

## Notes
- Attempt/token/duration budgets remain useful as operational limits, but they do not override safety and convergence stop rules.
