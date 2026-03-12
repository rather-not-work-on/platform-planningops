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
            "updated_at": "2026-03-10T12:00:00Z",
            "title": "[PO-CT][A00]",
            "url": "https://github.com/rather-not-work-on/platform-planningops/issues/94",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_doc: `docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md`",
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
            "updated_at": "2026-03-10T13:00:00Z",
            "title": "[PO-CT][A10]",
            "url": "https://github.com/rather-not-work-on/platform-planningops/issues/95",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_doc: `docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md`",
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
            "updated_at": "2026-03-10T14:00:00Z",
            "title": "[PO-CT][B10]",
            "url": "https://github.com/rather-not-work-on/platform-contracts/issues/2",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_doc: `docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md`",
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
    assert report["duplicate_group_count"] == 0, report

    # Duplicate key history should select deterministic winner (open > closed > newest update).
    duplicate_issues = json.loads(json.dumps(base_issues))
    duplicate_issues.extend(
        [
            {
                "repo": "rather-not-work-on/platform-planningops",
                "number": 80,
                "state": "closed",
                "updated_at": "2026-03-10T17:00:00Z",
                "title": "[PO-CT][A10] old",
                "url": "https://github.com/rather-not-work-on/platform-planningops/issues/80",
                "body": duplicate_issues[1]["body"],
            },
            {
                "repo": "rather-not-work-on/platform-planningops",
                "number": 96,
                "state": "open",
                "updated_at": "2026-03-10T15:00:00Z",
                "title": "[PO-CT][A10] newer",
                "url": "https://github.com/rather-not-work-on/platform-planningops/issues/96",
                "body": duplicate_issues[1]["body"],
            },
        ]
    )
    issues_path.write_text(json.dumps(duplicate_issues, ensure_ascii=True, indent=2), encoding="utf-8")
    rc_dup, out_dup, err_dup = run(
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
    assert rc_dup == 0, (rc_dup, out_dup, err_dup)
    dup_manifest = json.loads(output_path.read_text(encoding="utf-8"))
    dup_report = json.loads(report_path.read_text(encoding="utf-8"))
    selected_a10 = [row for row in dup_manifest["items"] if row["plan_item_id"] == "A10"][0]
    assert selected_a10["issue_number"] == 96, dup_manifest
    assert dup_report["duplicate_group_count"] == 1, dup_report
    assert dup_report["duplicate_groups"][0]["winner"]["issue_number"] == 96, dup_report
    assert [row["issue_number"] for row in dup_report["duplicate_groups"][0]["losers"]] == [95, 80], dup_report

    # Source-plan scoping should ignore unrelated wave items with colliding plan_item_id values.
    scoped_issues = json.loads(json.dumps(base_issues))
    scoped_issues.append(
        {
            "repo": "rather-not-work-on/platform-planningops",
            "number": 163,
            "state": "closed",
            "updated_at": "2026-03-11T12:00:00Z",
            "title": "old wave B10",
            "url": "https://github.com/rather-not-work-on/platform-planningops/issues/163",
            "body": "\n".join(
                [
                    "## Planning Context",
                    "- plan_doc: `docs/workbench/unified-personal-agent-platform/plans/runtime-skeleton-wave3-build-baseline-issue-pack.md`",
                    "- plan_item_id: `B10`",
                    "- target_repo: `rather-not-work-on/platform-planningops`",
                    "- component: `planningops`",
                    "- workflow_state: `done`",
                    "- loop_profile: `l4_integration_reconcile`",
                    "- execution_order: `10`",
                    "- depends_on: `-`",
                    "- plan_lane: `M3 Guardrails`",
                ]
            ),
        }
    )
    issues_path.write_text(json.dumps(scoped_issues, ensure_ascii=True, indent=2), encoding="utf-8")
    rc_scoped, out_scoped, err_scoped = run(
        [
            "python3",
            "planningops/scripts/build_program_manifest.py",
            "--issues-file",
            str(issues_path),
            "--source-plan",
            "docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md",
            "--scope-source-plan",
            "--output",
            str(output_path),
            "--report-output",
            str(report_path),
            "--strict",
        ]
    )
    assert rc_scoped == 0, (rc_scoped, out_scoped, err_scoped)
    scoped_manifest = json.loads(output_path.read_text(encoding="utf-8"))
    scoped_report = json.loads(report_path.read_text(encoding="utf-8"))
    assert scoped_report["verdict"] == "pass", scoped_report
    assert scoped_report["filtered_out_count"] == 1, scoped_report
    assert [row["issue_number"] for row in scoped_manifest["items"] if row["plan_item_id"] == "B10"] == [2], scoped_manifest

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
