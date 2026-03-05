#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import subprocess
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/backlog_stock_replenishment_guard.py")
spec = importlib.util.spec_from_file_location("backlog_stock_replenishment_guard", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

policy = mod.load_json(Path("planningops/config/backlog-stock-policy.json"), {})
items = mod.load_json(Path("planningops/fixtures/backlog-stock-items-sample.json"), [])
rows = [mod.normalize_item(x) for x in items]
rows = [x for x in rows if x]
mod.hydrate_dependency_counts(rows, offline=True)
stock = mod.evaluate_stock(rows, policy)
assert stock["breach_count"] == 0, stock

high_value = mod.select_high_value_ready(stock["class_rows"])
assert high_value is not None, high_value
assert high_value["issue_number"] == 101, high_value
assert high_value["reason"] == "high_value_ready_first", high_value

invalid_candidates = [
    {
        "candidate_id": "bad-1",
        "title": "Missing fields example",
        "depends_on": ["#101"],
    }
]
candidate_validation = mod.validate_replenishment_candidates(invalid_candidates, policy["candidate_requirements"])
assert candidate_validation["violation_count"] == 1, candidate_validation
assert "evidence_refs is required and must be non-empty" in candidate_validation["violations"][0]["errors"], candidate_validation
assert "acceptance_criteria must be a list" in candidate_validation["violations"][0]["errors"], candidate_validation

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    pass_report = td_path / "report-pass.json"
    pass_rc = subprocess.run(
        [
            "python3",
            "planningops/scripts/backlog_stock_replenishment_guard.py",
            "--stock-policy-file",
            "planningops/config/backlog-stock-policy.json",
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--candidate-file",
            "planningops/fixtures/backlog-replenishment-candidates-sample.json",
            "--offline",
            "--output",
            str(pass_report),
        ],
        check=False,
    ).returncode
    assert pass_rc == 0, pass_rc
    pass_doc = json.loads(pass_report.read_text(encoding="utf-8"))
    assert pass_doc["verdict"] == "pass", pass_doc

    bad_candidates_path = td_path / "bad-candidates.json"
    bad_candidates_path.write_text(
        json.dumps(
            {
                "candidates": [
                    {
                        "candidate_id": "bad-2",
                        "title": "No evidence refs",
                        "depends_on": [101],
                        "acceptance_criteria": [],
                    }
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    fail_report = td_path / "report-fail.json"
    fail_rc = subprocess.run(
        [
            "python3",
            "planningops/scripts/backlog_stock_replenishment_guard.py",
            "--stock-policy-file",
            "planningops/config/backlog-stock-policy.json",
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--candidate-file",
            str(bad_candidates_path),
            "--offline",
            "--output",
            str(fail_report),
        ],
        check=False,
    ).returncode
    assert fail_rc == 1, fail_rc
    fail_doc = json.loads(fail_report.read_text(encoding="utf-8"))
    assert fail_doc["verdict"] == "fail", fail_doc
    assert fail_doc["candidate_validation"]["violation_count"] == 1, fail_doc

print("backlog stock/replenishment contract tests ok")
PY
