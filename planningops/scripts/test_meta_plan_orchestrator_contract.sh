#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/meta_plan_orchestrator.py")
spec = importlib.util.spec_from_file_location("meta_plan_orchestrator", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

base_contract = json.loads(Path("planningops/fixtures/meta-plan-graph-sample.json").read_text(encoding="utf-8"))

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    contract_path = td_path / "meta-contract.json"
    graph_path = td_path / "meta-graph.json"
    report_path = td_path / "meta-execution-report.json"

    contract_path.write_text(json.dumps(base_contract, ensure_ascii=True), encoding="utf-8")

    # 1) Dry-run strict path must pass and keep deterministic ready-set selection.
    argv_before = list(sys.argv)
    sys.argv = [
        "meta_plan_orchestrator.py",
        "--meta-graph-contract",
        str(contract_path),
        "--meta-graph-output",
        str(graph_path),
        "--output",
        str(report_path),
        "--mode",
        "dry-run",
        "--strict",
    ]
    rc = mod.main()
    sys.argv = argv_before
    assert rc == 0, rc
    dry_run_report = json.loads(report_path.read_text(encoding="utf-8"))
    assert dry_run_report["verdict"] == "pass", dry_run_report
    assert dry_run_report["ready_set"] == ["pec-track"], dry_run_report
    assert dry_run_report["execution_rows"][0]["node_verdict"] == "simulated", dry_run_report

    # 2) Apply mode success path with monkeypatched command runner.
    calls = []

    def fake_run_ok(cmd):
        calls.append(" ".join(cmd))
        return 0, "ok", ""

    mod.run = fake_run_ok
    argv_before = list(sys.argv)
    sys.argv = [
        "meta_plan_orchestrator.py",
        "--meta-graph-contract",
        str(contract_path),
        "--meta-graph-output",
        str(graph_path),
        "--output",
        str(report_path),
        "--mode",
        "apply",
        "--strict",
    ]
    rc_apply_ok = mod.main()
    sys.argv = argv_before
    assert rc_apply_ok == 0, rc_apply_ok
    apply_ok_report = json.loads(report_path.read_text(encoding="utf-8"))
    assert apply_ok_report["verdict"] == "pass", apply_ok_report
    assert apply_ok_report["failure_count"] == 0, apply_ok_report
    assert len(calls) == 3, calls

    # 3) Apply mode failure path should fail in strict mode.
    idx = {"value": 0}

    def fake_run_fail(cmd):
        idx["value"] += 1
        if idx["value"] == 2:
            return 1, "", "simulated failure"
        return 0, "ok", ""

    mod.run = fake_run_fail
    argv_before = list(sys.argv)
    sys.argv = [
        "meta_plan_orchestrator.py",
        "--meta-graph-contract",
        str(contract_path),
        "--meta-graph-output",
        str(graph_path),
        "--output",
        str(report_path),
        "--mode",
        "apply",
        "--strict",
    ]
    rc_apply_fail = mod.main()
    sys.argv = argv_before
    assert rc_apply_fail == 1, rc_apply_fail
    apply_fail_report = json.loads(report_path.read_text(encoding="utf-8"))
    apply_fail_graph = json.loads(graph_path.read_text(encoding="utf-8"))
    assert apply_fail_report["verdict"] == "fail", apply_fail_report
    assert "node_pipeline_failure" in apply_fail_report["reasons"], apply_fail_report
    assert apply_fail_graph["verdict"] == "fail", apply_fail_graph

    # 4) Cycle graph should fail before pipeline execution.
    cycle_contract = json.loads(json.dumps(base_contract))
    cycle_contract["meta_plan_graph"]["edges"].append(
        {"from": "meta-track", "to": "pec-track", "type": "depends_on"}
    )
    contract_path.write_text(json.dumps(cycle_contract, ensure_ascii=True), encoding="utf-8")
    mod.run = fake_run_ok
    argv_before = list(sys.argv)
    sys.argv = [
        "meta_plan_orchestrator.py",
        "--meta-graph-contract",
        str(contract_path),
        "--meta-graph-output",
        str(graph_path),
        "--output",
        str(report_path),
        "--mode",
        "apply",
        "--strict",
    ]
    rc_cycle = mod.main()
    sys.argv = argv_before
    assert rc_cycle == 1, rc_cycle
    cycle_report = json.loads(report_path.read_text(encoding="utf-8"))
    assert cycle_report["verdict"] == "fail", cycle_report
    assert "meta_graph_cycle_detected" in cycle_report["reasons"], cycle_report

    # 5) Schema-invalid graph should fail strict runtime validation.
    invalid_schema_contract = json.loads(json.dumps(base_contract))
    invalid_schema_contract["meta_plan_graph"]["nodes"][0]["component"] = "invalid_component"
    contract_path.write_text(json.dumps(invalid_schema_contract, ensure_ascii=True), encoding="utf-8")
    mod.run = fake_run_ok
    argv_before = list(sys.argv)
    sys.argv = [
        "meta_plan_orchestrator.py",
        "--meta-graph-contract",
        str(contract_path),
        "--schema-file",
        "planningops/schemas/meta-plan-graph.schema.json",
        "--meta-graph-output",
        str(graph_path),
        "--output",
        str(report_path),
        "--mode",
        "apply",
        "--strict",
    ]
    rc_schema = mod.main()
    sys.argv = argv_before
    assert rc_schema == 1, rc_schema
    schema_report = json.loads(report_path.read_text(encoding="utf-8"))
    assert schema_report["verdict"] == "fail", schema_report
    assert any("invalid enum value: invalid_component" in err for err in schema_report["validation_errors"]), schema_report

print("meta_plan_orchestrator contract tests ok")
PY
