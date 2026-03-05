#!/usr/bin/env python3

import subprocess
import time
from dataclasses import dataclass


STDIO_TAIL_LIMIT = 4000


def _tail(text: str, limit: int = STDIO_TAIL_LIMIT):
    if not text:
        return ""
    if len(text) <= limit:
        return text
    return text[-limit:]


def _coerce_int(value, field_name: str):
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} must be integer") from exc


@dataclass(frozen=True)
class WorkerExecutionPolicy:
    max_retries: int
    timeout_ms: int
    max_attempts: int

    def validate(self):
        if self.max_retries < 0:
            raise ValueError("max_retries must be >= 0")
        if self.timeout_ms <= 0:
            raise ValueError("timeout_ms must be positive integer")
        if self.max_attempts < 0:
            raise ValueError("max_attempts must be >= 0")


def execute_worker_command(command, policy: WorkerExecutionPolicy):
    if not isinstance(command, list) or not command:
        raise ValueError("worker command must be non-empty list")
    policy.validate()

    retry_cap_attempts = policy.max_retries + 1
    attempts_allowed = min(policy.max_attempts, retry_cap_attempts)
    attempt_budget_limited = attempts_allowed < retry_cap_attempts

    if attempts_allowed <= 0:
        return {
            "status": "fail",
            "reason_code": "attempt_budget_exhausted",
            "attempts_executed": 0,
            "attempts_allowed": attempts_allowed,
            "retry_cap_attempts": retry_cap_attempts,
            "attempt_budget_limited": attempt_budget_limited,
            "max_attempts": policy.max_attempts,
            "max_retries": policy.max_retries,
            "timeout_ms": policy.timeout_ms,
            "timed_out": False,
            "final_return_code": None,
            "stdout_tail": "",
            "stderr_tail": "",
            "attempts": [],
        }

    attempts = []
    for attempt_index in range(1, attempts_allowed + 1):
        started = time.monotonic()
        timed_out = False
        return_code = None
        stdout = ""
        stderr = ""
        try:
            completed = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=(policy.timeout_ms / 1000.0),
            )
            return_code = int(completed.returncode)
            stdout = completed.stdout or ""
            stderr = completed.stderr or ""
        except subprocess.TimeoutExpired as exc:
            timed_out = True
            timeout_stdout = exc.stdout if isinstance(exc.stdout, str) else ""
            timeout_stderr = exc.stderr if isinstance(exc.stderr, str) else ""
            stdout = timeout_stdout or ""
            stderr = timeout_stderr or ""

        duration_ms = int((time.monotonic() - started) * 1000)
        attempt_doc = {
            "attempt_index": attempt_index,
            "timed_out": timed_out,
            "return_code": return_code,
            "duration_ms": duration_ms,
            "stdout_tail": _tail(stdout),
            "stderr_tail": _tail(stderr),
        }
        attempts.append(attempt_doc)

        if not timed_out and return_code == 0:
            break

    last = attempts[-1]
    if not last["timed_out"] and last["return_code"] == 0:
        reason_code = "ok"
        status = "pass"
    else:
        status = "fail"
        if attempt_budget_limited and len(attempts) >= attempts_allowed:
            reason_code = "attempt_budget_exhausted"
        elif all(row["timed_out"] for row in attempts):
            reason_code = "runtime_timeout_retries_exhausted"
        else:
            reason_code = "runtime_error_retries_exhausted"

    return {
        "status": status,
        "reason_code": reason_code,
        "attempts_executed": len(attempts),
        "attempts_allowed": attempts_allowed,
        "retry_cap_attempts": retry_cap_attempts,
        "attempt_budget_limited": attempt_budget_limited,
        "max_attempts": policy.max_attempts,
        "max_retries": policy.max_retries,
        "timeout_ms": policy.timeout_ms,
        "timed_out": bool(last["timed_out"]),
        "final_return_code": last["return_code"],
        "stdout_tail": last["stdout_tail"],
        "stderr_tail": last["stderr_tail"],
        "attempts": attempts,
    }
