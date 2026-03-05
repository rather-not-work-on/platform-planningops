#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/verify_plan_projection.py")
spec = importlib.util.spec_from_file_location("verify_plan_projection", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def build_contract():
    return {
        "execution_contract": {
            "plan_id": "projection-test",
            "plan_revision": 1,
            "source_of_truth": "docs/workbench/unified-personal-agent-platform/plans/2026-03-03-plan-auto-executable-plans-contract-and-runner-plan.md",
            "items": [
                {
                    "plan_item_id": "sample-001",
                    "execution_order": 1,
                    "title": "sample",
                    "target_repo": "rather-not-work-on/platform-planningops",
                    "component": "planningops",
                    "workflow_state": "ready_contract",
                    "loop_profile": "l1_contract_clarification",
                    "depends_on": [],
                    "primary_output": "planningops/contracts/plan-execution-contract-v1.md",
                }
            ],
        }
    }


def build_snapshot(workflow_state="ready-contract", loop_profile="L1 Contract-Clarification", status="Todo"):
    return {
        "items": [
            {
                "id": "PVTI_sample",
                "initiative": "unified-personal-agent-platform",
                "target_repo": "rather-not-work-on/platform-planningops",
                "component": "planningops",
                "workflow_state": workflow_state,
                "loop_profile": loop_profile,
                "status": status,
                "execution_order": 1,
                "content": {
                    "type": "Issue",
                    "number": 9991,
                    "url": "https://github.com/rather-not-work-on/platform-planningops/issues/9991",
                    "repository": "rather-not-work-on/platform-planningops",
                    "body": "## Planning Context\n- plan_item_id: `sample-001`\n",
                },
            }
        ]
    }


with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    contract_path = td_path / "contract.json"
    snapshot_path = td_path / "snapshot.json"
    output_path = td_path / "projection-report.json"

    contract_path.write_text(json.dumps(build_contract(), ensure_ascii=True), encoding="utf-8")
    snapshot_path.write_text(json.dumps(build_snapshot(), ensure_ascii=True), encoding="utf-8")

    argv_before = list(sys.argv)
    sys.argv = [
        "verify_plan_projection.py",
        "--contract-file",
        str(contract_path),
        "--snapshot-file",
        str(snapshot_path),
        "--strict",
        "--output",
        str(output_path),
    ]
    rc = mod.main()
    sys.argv = argv_before
    assert rc == 0, rc
    report = json.loads(output_path.read_text(encoding="utf-8"))
    assert report["verdict"] == "pass", report
    assert report["mismatch_count"] == 0, report
    assert report["missing_count"] == 0, report

    # workflow mismatch must fail in strict mode.
    snapshot_path.write_text(
        json.dumps(build_snapshot(workflow_state="in-progress", status="In Progress"), ensure_ascii=True),
        encoding="utf-8",
    )
    argv_before = list(sys.argv)
    sys.argv = [
        "verify_plan_projection.py",
        "--contract-file",
        str(contract_path),
        "--snapshot-file",
        str(snapshot_path),
        "--strict",
        "--output",
        str(output_path),
    ]
    rc_mismatch = mod.main()
    sys.argv = argv_before
    assert rc_mismatch == 1, rc_mismatch
    mismatch_report = json.loads(output_path.read_text(encoding="utf-8"))
    assert mismatch_report["verdict"] == "fail", mismatch_report
    assert mismatch_report["mismatch_count"] >= 1, mismatch_report
    assert "projection_field_mismatch" in mismatch_report["reasons"], mismatch_report

    # missing item must fail in strict mode.
    snapshot_path.write_text(json.dumps({"items": []}, ensure_ascii=True), encoding="utf-8")
    argv_before = list(sys.argv)
    sys.argv = [
        "verify_plan_projection.py",
        "--contract-file",
        str(contract_path),
        "--snapshot-file",
        str(snapshot_path),
        "--strict",
        "--output",
        str(output_path),
    ]
    rc_missing = mod.main()
    sys.argv = argv_before
    assert rc_missing == 1, rc_missing
    missing_report = json.loads(output_path.read_text(encoding="utf-8"))
    assert missing_report["verdict"] == "fail", missing_report
    assert missing_report["missing_count"] == 1, missing_report
    assert "projection_item_missing" in missing_report["reasons"], missing_report

print("verify_plan_projection contract tests ok")
PY
