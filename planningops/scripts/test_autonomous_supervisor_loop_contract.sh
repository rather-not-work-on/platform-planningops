#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import tempfile
from pathlib import Path


def run_supervisor(args):
    cp = subprocess.run(args, check=False, capture_output=True, text=True)
    return cp.returncode, cp.stdout, cp.stderr


with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)

    # 1) continue-on-experiment should allow multi-cycle run and converge.
    out_converged = td_path / "supervisor-converged.json"
    rc_converged, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--convergence-pass-streak",
            "2",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            "planningops/fixtures/supervisor-loop-sequence-sample.json",
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--output",
            str(out_converged),
        ]
    )
    assert rc_converged == 0, rc_converged
    converged = json.loads(out_converged.read_text(encoding="utf-8"))
    assert converged["supervisor_verdict"] == "pass", converged
    assert converged["stop_reason"] == "converged", converged
    assert converged["executed_cycles"] == 2, converged
    assert converged["cycles"][0]["experiment_trigger"]["triggered"] is True, converged
    assert converged["cycles"][1]["replenishment_candidates_count"] == 0, converged

    # 2) default behavior should stop when experiment trigger is detected.
    out_exp_stop = td_path / "supervisor-experiment-stop.json"
    rc_exp_stop, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--loop-result-sequence-file",
            "planningops/fixtures/supervisor-loop-sequence-sample.json",
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--output",
            str(out_exp_stop),
        ]
    )
    assert rc_exp_stop == 1, rc_exp_stop
    exp_stop = json.loads(out_exp_stop.read_text(encoding="utf-8"))
    assert exp_stop["supervisor_verdict"] == "inconclusive", exp_stop
    assert exp_stop["stop_reason"] == "experiment_triggered", exp_stop
    assert exp_stop["executed_cycles"] == 1, exp_stop

    # 3) explicit fail verdict must stop as quality gate failure.
    fail_sequence = td_path / "fail-sequence.json"
    fail_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 1,
                        "loop_result": {
                            "selected_issue": 303,
                            "last_verdict": "fail",
                            "reason_code": "verdict_consistency_error",
                            "auto_paused": False,
                            "replenishment_candidates_count": 1,
                            "replenishment_candidates_path": "planningops/fixtures/backlog-replenishment-candidates-sample.json",
                            "selection_trace": {"selected": {"uncertainty_level": "low", "simulation_required": False}},
                            "final_loop_profile": "L3 Implementation-TDD",
                        },
                    }
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_fail = td_path / "supervisor-fail.json"
    rc_fail, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(fail_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--output",
            str(out_fail),
        ]
    )
    assert rc_fail == 1, rc_fail
    fail_doc = json.loads(out_fail.read_text(encoding="utf-8"))
    assert fail_doc["supervisor_verdict"] == "fail", fail_doc
    assert fail_doc["stop_reason"] == "quality_gate_fail", fail_doc
    assert fail_doc["cycles"][0]["reason_code"] == "verdict_consistency_error", fail_doc

print("autonomous supervisor loop contract tests ok")
PY
