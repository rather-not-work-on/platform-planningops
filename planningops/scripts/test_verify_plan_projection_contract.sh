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
                    "plan_lane": "m1_contract_freeze",
                    "depends_on": [],
                    "primary_output": "planningops/contracts/plan-execution-contract-v1.md",
                }
            ],
        }
    }


def build_snapshot(
    workflow_state="ready-contract",
    loop_profile="L1 Contract-Clarification",
    plan_lane="m1-contract-freeze",
    status="Todo",
    body=None,
):
    issue_body = body or "## Planning Context\n- plan_item_id: `sample-001`\n"
    return {
        "items": [
            {
                "id": "PVTI_sample",
                "initiative": "unified-personal-agent-platform",
                "target_repo": "rather-not-work-on/platform-planningops",
                "component": "planningops",
                "workflow_state": workflow_state,
                "loop_profile": loop_profile,
                "plan_lane": plan_lane,
                "status": status,
                "execution_order": 1,
                "content": {
                    "type": "Issue",
                    "number": 9991,
                    "url": "https://github.com/rather-not-work-on/platform-planningops/issues/9991",
                    "repository": "rather-not-work-on/platform-planningops",
                    "body": issue_body,
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

    # plan_lane mismatch must fail in strict mode.
    snapshot_path.write_text(
        json.dumps(build_snapshot(plan_lane="m2-sync-core"), ensure_ascii=True),
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
    rc_lane = mod.main()
    sys.argv = argv_before
    assert rc_lane == 1, rc_lane
    lane_report = json.loads(output_path.read_text(encoding="utf-8"))
    assert any(row["field"] == "plan_lane" for row in lane_report["mismatches"]), lane_report

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

    # ready_implementation item must carry blueprint refs.
    ready_contract = build_contract()
    ready_contract["execution_contract"]["items"][0]["workflow_state"] = "ready_implementation"
    contract_path.write_text(json.dumps(ready_contract, ensure_ascii=True), encoding="utf-8")
    snapshot_path.write_text(
        json.dumps(
            build_snapshot(
                workflow_state="ready-implementation",
                body="## Planning Context\n- plan_item_id: `sample-001`\n",
            ),
            ensure_ascii=True,
        ),
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
    rc_ready_missing = mod.main()
    sys.argv = argv_before
    assert rc_ready_missing == 1, rc_ready_missing
    ready_missing_report = json.loads(output_path.read_text(encoding="utf-8"))
    assert any(row["field"] == "blueprint_complete" for row in ready_missing_report["mismatches"]), ready_missing_report

    snapshot_path.write_text(
        json.dumps(
            build_snapshot(
                workflow_state="ready-implementation",
                body="\n".join(
                    [
                        "## Planning Context",
                        "- plan_item_id: `sample-001`",
                        "",
                        "## Implementation Blueprint Refs",
                        "interface_contract_refs: planningops/contracts/requirements-contract.md",
                        "package_topology_ref: planningops/README.md",
                        "dependency_manifest_ref: planningops/config/runtime-profiles.json",
                        "file_plan_ref: docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave17-blueprint-projection-alignment-issue-pack.md",
                    ]
                )
                + "\n",
            ),
            ensure_ascii=True,
        ),
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
    rc_ready_ok = mod.main()
    sys.argv = argv_before
    assert rc_ready_ok == 0, rc_ready_ok
    ready_ok_report = json.loads(output_path.read_text(encoding="utf-8"))
    assert ready_ok_report["verdict"] == "pass", ready_ok_report

print("verify_plan_projection contract tests ok")
PY
