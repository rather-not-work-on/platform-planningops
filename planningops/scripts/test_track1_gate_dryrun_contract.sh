#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/run_track1_gate_dryrun.py")
spec = importlib.util.spec_from_file_location("run_track1_gate_dryrun", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
real_evaluate_kpi = mod.evaluate_kpi

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    kpi_path = td_path / "kpi-ci.json"
    kpi_path.write_text(
        json.dumps(
            {
                "metrics": {
                    "loop_success_rate": 0.95,
                    "replan_without_evidence": 0,
                    "schema_drift_recovery_time_p95_hours": 8,
                }
            },
            ensure_ascii=True,
        ),
        encoding="utf-8",
    )
    mod.VALIDATION_DIR = td_path / "validation"
    mod.CHAIN_REPORT_PATH = mod.VALIDATION_DIR / "track1-validation-chain-report.json"
    mod.KPI_PATH = mod.VALIDATION_DIR / "track1-kpi-baseline.json"
    mod.DRYRUN_REPORT_PATH = mod.VALIDATION_DIR / "track1-gate-dryrun-report.json"
    mod.TRANSITION_LOG_PATH = mod.VALIDATION_DIR / "transition-log.ndjson"
    mod.SCHEMA_REPORT_PATH = mod.VALIDATION_DIR / "project-field-schema-report.json"

    def fake_run(cmd):
        cmd_str = " ".join(cmd)
        if "uap-docs.sh" in cmd_str:
            return 0, "docs-pass", ""
        if "validate_project_field_schema.py" in cmd_str:
            return 0, "schema-pass", ""
        raise AssertionError(f"unexpected command: {cmd}")

    def fake_read_json(path):
        if path == mod.SCHEMA_REPORT_PATH:
            return {"violation_count": 0}
        return {}

    mod.run = fake_run
    mod.read_json = fake_read_json

    mod.evaluate_kpi = lambda _kpi_path: {
        "pass": False,
        "missing_only": True,
        "reasons": ["kpi.loop_success_rate.missing"],
        "metrics": {},
    }

    sys.argv = ["run_track1_gate_dryrun.py"]
    rc = mod.main()
    assert rc == 0, rc

    chain_report = json.loads(mod.CHAIN_REPORT_PATH.read_text(encoding="utf-8"))
    dryrun_report = json.loads(mod.DRYRUN_REPORT_PATH.read_text(encoding="utf-8"))

    assert dryrun_report["final_verdict"] == "inconclusive", dryrun_report
    assert chain_report["overall_gate_verdict"] == dryrun_report["final_verdict"], chain_report
    assert chain_report["verdict"] == dryrun_report["final_verdict"], chain_report
    assert chain_report["checks"]["kpi_gate_validation"]["pass"] is False, chain_report

    sys.argv = ["run_track1_gate_dryrun.py", "--strict"]
    rc_strict = mod.main()
    assert rc_strict == 1, rc_strict

    mod.evaluate_kpi = lambda _kpi_path: {
        "pass": True,
        "missing_only": False,
        "reasons": [],
        "metrics": {
            "loop_success_rate": 0.95,
            "replan_without_evidence": 0,
            "schema_drift_recovery_time_p95_hours": 8,
        },
    }

    sys.argv = ["run_track1_gate_dryrun.py", "--strict"]
    rc_strict_pass = mod.main()
    assert rc_strict_pass == 0, rc_strict_pass

    original_evaluate_kpi = mod.evaluate_kpi
    mod.evaluate_kpi = real_evaluate_kpi
    mod.read_json = lambda path: (
        {"violation_count": 0}
        if path == mod.SCHEMA_REPORT_PATH
        else json.loads(path.read_text(encoding="utf-8"))
    )
    sys.argv = ["run_track1_gate_dryrun.py", "--strict", "--kpi-path", str(kpi_path)]
    rc_custom_kpi = mod.main()
    assert rc_custom_kpi == 0, rc_custom_kpi
    dryrun_report_custom = json.loads(mod.DRYRUN_REPORT_PATH.read_text(encoding="utf-8"))
    assert dryrun_report_custom["kpi_source_path"].endswith("kpi-ci.json"), dryrun_report_custom
    mod.evaluate_kpi = original_evaluate_kpi

print("track1 gate dryrun contract tests ok")
PY
