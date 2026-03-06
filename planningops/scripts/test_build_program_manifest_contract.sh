#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import tempfile
from pathlib import Path


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout, cp.stderr


with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    issues_path = td_path / "issues.json"
    output_path = td_path / "program-manifest.json"
    report_path = td_path / "program-manifest-report.json"

    base_issues = [
        {
            "repo": "rather-not-work-on/platform-planningops",
            "number": 94,
            "state": "open",
            "title": "[PO-CT][A00]",
            "url": "https://github.com/rather-not-work-on/platform-planningops/issues/94",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_item_id: `A00`",
                    "- target_repo: `rather-not-work-on/platform-planningops`",
                    "- component: `orchestrator`",
                    "- workflow_state: `ready-contract`",
                    "- loop_profile: `l1_contract_clarification`",
                    "- execution_order: `1000`",
                    "- depends_on: `none`",
                    "- plan_lane: `M0 Bootstrap`",
                ]
            ),
        },
        {
            "repo": "rather-not-work-on/platform-planningops",
            "number": 95,
            "state": "open",
            "title": "[PO-CT][A10]",
            "url": "https://github.com/rather-not-work-on/platform-planningops/issues/95",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_item_id: `A10`",
                    "- target_repo: `rather-not-work-on/platform-planningops`",
                    "- component: `planningops`",
                    "- workflow_state: `ready-contract`",
                    "- loop_profile: `l1_contract_clarification`",
                    "- execution_order: `1010`",
                    "- depends_on: `A00 (rather-not-work-on/platform-planningops#94)`",
                    "- plan_lane: `M0 Bootstrap`",
                ]
            ),
        },
        {
            "repo": "rather-not-work-on/platform-contracts",
            "number": 2,
            "state": "open",
            "title": "[PO-CT][B10]",
            "url": "https://github.com/rather-not-work-on/platform-contracts/issues/2",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_item_id: `B10`",
                    "- target_repo: `rather-not-work-on/platform-contracts`",
                    "- component: `contracts`",
                    "- workflow_state: `ready-contract`",
                    "- loop_profile: `l1_contract_clarification`",
                    "- execution_order: `2100`",
                    "- depends_on: `A10 (rather-not-work-on/platform-planningops#95)`",
                    "- plan_lane: `M1 Contract Freeze`",
                ]
            ),
        },
    ]

    issues_path.write_text(json.dumps(base_issues, ensure_ascii=True, indent=2), encoding="utf-8")
    rc, out, err = run(
        [
            "python3",
            "planningops/scripts/build_program_manifest.py",
            "--issues-file",
            str(issues_path),
            "--output",
            str(output_path),
            "--report-output",
            str(report_path),
            "--strict",
        ]
    )
    assert rc == 0, (rc, out, err)

    manifest = json.loads(output_path.read_text(encoding="utf-8"))
    report = json.loads(report_path.read_text(encoding="utf-8"))
    assert report["verdict"] == "pass", report
    assert manifest["item_count"] == 3, manifest
    assert [x["plan_item_id"] for x in manifest["items"]] == ["A00", "A10", "B10"], manifest
    assert manifest["items"][1]["depends_on"] == ["A00"], manifest
    assert manifest["items"][2]["depends_on"] == ["A10"], manifest

    # Invalid graph: dependency points to unknown key.
    bad = json.loads(json.dumps(base_issues))
    bad[2]["body"] = bad[2]["body"].replace("A10 (rather-not-work-on/platform-planningops#95)", "A99")
    issues_path.write_text(json.dumps(bad, ensure_ascii=True, indent=2), encoding="utf-8")
    rc_bad, out_bad, err_bad = run(
        [
            "python3",
            "planningops/scripts/build_program_manifest.py",
            "--issues-file",
            str(issues_path),
            "--output",
            str(output_path),
            "--report-output",
            str(report_path),
            "--strict",
        ]
    )
    assert rc_bad == 1, (rc_bad, out_bad, err_bad)
    bad_report = json.loads(report_path.read_text(encoding="utf-8"))
    assert bad_report["verdict"] == "fail", bad_report
    assert any("unknown key: A99" in e for e in bad_report["errors"]), bad_report

print("build_program_manifest contract tests ok")
PY
