#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/build_meta_plan_graph.py")
spec = importlib.util.spec_from_file_location("build_meta_plan_graph", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

base_contract = json.loads(Path("planningops/fixtures/meta-plan-graph-sample.json").read_text(encoding="utf-8"))
schema_doc = json.loads(Path("planningops/schemas/meta-plan-graph.schema.json").read_text(encoding="utf-8"))
assert mod.validate_meta_graph(base_contract) == []
assert mod.validate_meta_graph_schema(base_contract, schema_doc) == []

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    contract_path = td_path / "meta-contract.json"
    out_path = td_path / "meta-graph.json"

    contract_path.write_text(json.dumps(base_contract, ensure_ascii=True), encoding="utf-8")

    argv_before = list(sys.argv)
    sys.argv = [
        "build_meta_plan_graph.py",
        "--contract-file",
        str(contract_path),
        "--strict",
        "--output",
        str(out_path),
    ]
    rc = mod.main()
    sys.argv = argv_before
    assert rc == 0, rc
    report = json.loads(out_path.read_text(encoding="utf-8"))
    assert report["verdict"] == "pass", report
    assert report["ready_set"] == ["pec-track"], report

    cycle_contract = json.loads(json.dumps(base_contract))
    cycle_contract["meta_plan_graph"]["edges"].append(
        {"from": "meta-track", "to": "pec-track", "type": "depends_on"}
    )
    contract_path.write_text(json.dumps(cycle_contract, ensure_ascii=True), encoding="utf-8")
    argv_before = list(sys.argv)
    sys.argv = [
        "build_meta_plan_graph.py",
        "--contract-file",
        str(contract_path),
        "--strict",
        "--output",
        str(out_path),
    ]
    rc_cycle = mod.main()
    sys.argv = argv_before
    assert rc_cycle == 1, rc_cycle
    cycle_report = json.loads(out_path.read_text(encoding="utf-8"))
    assert cycle_report["verdict"] == "fail", cycle_report
    assert "meta_graph_cycle_detected" in cycle_report["reasons"], cycle_report

    invalid_schema_contract = json.loads(json.dumps(base_contract))
    invalid_schema_contract["meta_plan_graph"]["nodes"][0]["target_repo"] = "invalid_target_repo"
    contract_path.write_text(json.dumps(invalid_schema_contract, ensure_ascii=True), encoding="utf-8")
    argv_before = list(sys.argv)
    sys.argv = [
        "build_meta_plan_graph.py",
        "--contract-file",
        str(contract_path),
        "--schema-file",
        "planningops/schemas/meta-plan-graph.schema.json",
        "--strict",
        "--output",
        str(out_path),
    ]
    rc_schema = mod.main()
    sys.argv = argv_before
    assert rc_schema == 1, rc_schema
    schema_report = json.loads(out_path.read_text(encoding="utf-8"))
    assert schema_report["verdict"] == "fail", schema_report
    assert any("target_repo does not match pattern" in err for err in schema_report["validation_errors"]), schema_report

print("build_meta_plan_graph contract tests ok")
PY
