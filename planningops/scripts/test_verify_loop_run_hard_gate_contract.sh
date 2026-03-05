#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/verify_loop_run.py")
spec = importlib.util.spec_from_file_location("verify_loop_run", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def write(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_json(path: Path, doc):
    write(path, json.dumps(doc, ensure_ascii=True, indent=2))


def base_execution_evidence():
    return {
        "status": "pass",
        "reason_code": "ok",
        "attempts_executed": 1,
        "attempts_allowed": 2,
        "retry_cap_attempts": 2,
        "attempt_budget_limited": False,
        "max_attempts": 3,
        "max_retries": 1,
        "timeout_ms": 30000,
        "timed_out": False,
        "final_return_code": 0,
        "stdout_tail": "ok",
        "stderr_tail": "",
        "attempts": [
            {
                "attempt_index": 1,
                "timed_out": False,
                "return_code": 0,
                "duration_ms": 12,
                "stdout_tail": "ok",
                "stderr_tail": "",
            }
        ],
    }


def run_verify(loop_dir: Path, transition_log: Path, output_path: Path, payload_path: Path):
    argv_before = list(sys.argv)
    sys.argv = [
        "verify_loop_run.py",
        "--loop-dir",
        str(loop_dir),
        "--transition-log",
        str(transition_log),
        "--output",
        str(output_path),
        "--project-payload",
        str(payload_path),
    ]
    rc = mod.main()
    sys.argv = argv_before
    return rc, json.loads(output_path.read_text(encoding="utf-8")), json.loads(payload_path.read_text(encoding="utf-8"))


with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    loop_dir = td_path / "loop" / "loop-20260305T000000Z-issue-23"
    transition_log = td_path / "transition-log.ndjson"
    output_path = td_path / "verify.json"
    payload_path = td_path / "payload.json"
    sync_summary = td_path / "sync-summary.json"

    write_json(loop_dir / "intake-check.json", {"result": "ok"})
    write(loop_dir / "simulation-report.md", "# simulation")
    write(loop_dir / "patch-summary.md", "# patch")
    write_json(sync_summary, {"status": "ok"})

    evidence = base_execution_evidence()
    write_json(loop_dir / "execution-attempts.json", evidence)
    write_json(
        loop_dir / "verification-report.json",
        {
            "issue_number": 23,
            "loop_id": "loop-20260305T000000Z-issue-23",
            "verdict": "pass",
            "reason_code": "ok",
            "worker_execution": evidence,
            "artifacts": {
                "sync_summary": str(sync_summary),
            },
        },
    )
    write(
        transition_log,
        json.dumps(
            {
                "transition_id": "loop-20260305T000000Z-issue-23-complete",
                "run_id": "loop-20260305T000000Z-issue-23",
                "card_id": 23,
                "from_state": "In Progress",
                "to_state": "Done",
                "transition_reason": "verification.ok",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": "2026-03-05T00:00:00+00:00",
                "replanning_flag": False,
            },
            ensure_ascii=True,
        )
        + "\n",
    )

    rc_ok, report_ok, payload_ok = run_verify(loop_dir, transition_log, output_path, payload_path)
    assert rc_ok == 0, report_ok
    assert report_ok["verdict"] == "pass", report_ok
    assert payload_ok["last_verdict"] == "pass", payload_ok
    assert payload_ok["reason_code"] == "ok", payload_ok

    # Missing execution-attempt artifact must fail hard gate.
    (loop_dir / "execution-attempts.json").unlink()
    rc_missing, report_missing, payload_missing = run_verify(loop_dir, transition_log, output_path, payload_path)
    assert rc_missing == 1, report_missing
    assert report_missing["verdict"] == "fail", report_missing
    assert report_missing["reason_code"] == "execution_attempt_evidence_invalid", report_missing
    assert payload_missing["last_verdict"] == "fail", payload_missing

    # Malformed execution-attempt artifact must fail hard gate.
    write(loop_dir / "execution-attempts.json", "{invalid-json")
    rc_bad_json, report_bad_json, _ = run_verify(loop_dir, transition_log, output_path, payload_path)
    assert rc_bad_json == 1, report_bad_json
    assert report_bad_json["reason_code"] == "execution_attempt_evidence_invalid", report_bad_json

    # Verdict consistency mismatch must fail even when evidence schema is valid.
    fail_evidence = dict(base_execution_evidence())
    fail_evidence.update(
        {
            "status": "fail",
            "reason_code": "runtime_error_retries_exhausted",
            "final_return_code": 2,
            "stdout_tail": "",
            "stderr_tail": "boom",
            "attempts": [
                {
                    "attempt_index": 1,
                    "timed_out": False,
                    "return_code": 2,
                    "duration_ms": 9,
                    "stdout_tail": "",
                    "stderr_tail": "boom",
                }
            ],
        }
    )
    write_json(loop_dir / "execution-attempts.json", fail_evidence)
    write_json(
        loop_dir / "verification-report.json",
        {
            "issue_number": 23,
            "loop_id": "loop-20260305T000000Z-issue-23",
            "verdict": "pass",
            "reason_code": "ok",
            "worker_execution": fail_evidence,
            "artifacts": {
                "sync_summary": str(sync_summary),
            },
        },
    )
    rc_consistency, report_consistency, _ = run_verify(loop_dir, transition_log, output_path, payload_path)
    assert rc_consistency == 1, report_consistency
    assert report_consistency["reason_code"] == "verdict_consistency_error", report_consistency

print("verify_loop_run hard gate contract tests ok")
PY
