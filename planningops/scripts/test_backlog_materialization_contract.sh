#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from pathlib import Path
from types import SimpleNamespace

module_path = Path("planningops/scripts/core/backlog/materialize.py")
spec = importlib.util.spec_from_file_location("backlog_materialize_core", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    contract_path = td_path / "execution-contract.json"
    contract_path.write_text(
        json.dumps(
            {
                "execution_contract": {
                    "plan_id": "uap-backlog-wave26",
                    "plan_revision": 1,
                    "source_of_truth": "docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md",
                    "items": [
                        {
                            "plan_item_id": "A60",
                            "execution_order": 60,
                            "title": "Add recurring backlog materialization runner",
                            "target_repo": "rather-not-work-on/platform-planningops",
                            "component": "planningops",
                            "workflow_state": "ready_implementation",
                            "loop_profile": "l4_integration_reconcile",
                            "plan_lane": "m3_guardrails",
                            "depends_on": [],
                            "primary_output": "planningops/scripts/core/backlog/materialize.py",
                        }
                    ],
                }
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )

    execution_contract = mod.load_execution_contract(contract_path)
    assert execution_contract["plan_id"] == "uap-backlog-wave26", execution_contract

    dry_args = SimpleNamespace(
        contract_file=str(contract_path),
        repo="rather-not-work-on/platform-planningops",
        initiative="unified-personal-agent-platform",
        manifest_repos="rather-not-work-on/platform-planningops,rather-not-work-on/monday",
        source_plan=None,
        compile_config="planningops/config/project-field-ids.json",
        blueprint_defaults_config="planningops/config/ready-implementation-blueprint-defaults.json",
        compile_output=str(td_path / "compile.json"),
        label_output=str(td_path / "labels.json"),
        manifest_output=str(td_path / "manifest.json"),
        manifest_report=str(td_path / "manifest-report.json"),
        quality_output=str(td_path / "quality.json"),
        projected_issues_output=str(td_path / "projected-issues.json"),
        output=str(td_path / "materialize.json"),
        apply=False,
        allow_reopen_closed=False,
    )
    projected_issues = mod.build_projected_issues(
        execution_contract,
        repo=dry_args.repo,
        source_plan_override=dry_args.source_plan,
    )
    projected_issues_path = Path(dry_args.projected_issues_output)
    projected_issues_path.write_text(json.dumps(projected_issues, ensure_ascii=True, indent=2), encoding="utf-8")
    assert len(projected_issues) == 1, projected_issues
    assert projected_issues[0]["number"] == 60, projected_issues[0]
    assert "depends_on: `-`" in projected_issues[0]["body"], projected_issues[0]["body"]

    dry_steps = mod.build_steps(dry_args, execution_contract, projected_issues_file=str(projected_issues_path))
    assert [step["name"] for step in dry_steps] == [
        "compile_plan_to_backlog",
        "backfill_issue_labels",
        "build_program_manifest",
        "validate_issue_quality",
    ], dry_steps
    assert "--apply" not in dry_steps[0]["command"], dry_steps[0]
    assert "--apply" in dry_steps[1]["command"], dry_steps[1]
    assert "--issues-file" in dry_steps[1]["command"], dry_steps[1]
    assert "--write-updated-issues-file" in dry_steps[1]["command"], dry_steps[1]
    assert "--plan-item-regex" in dry_steps[2]["command"], dry_steps[2]
    assert "^(?:A60)$" in dry_steps[2]["command"], dry_steps[2]
    assert "docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md" in dry_steps[2]["command"], dry_steps[2]
    assert "--issues-file" in dry_steps[2]["command"], dry_steps[2]
    assert "--strict" in dry_steps[2]["command"], dry_steps[2]
    assert "--issues-file" in dry_steps[3]["command"], dry_steps[3]
    assert "--strict" in dry_steps[3]["command"], dry_steps[3]

    apply_args = SimpleNamespace(**{**dry_args.__dict__, "apply": True, "allow_reopen_closed": True})
    apply_steps = mod.build_steps(apply_args, execution_contract)
    assert "--apply" in apply_steps[0]["command"], apply_steps[0]
    assert "--allow-reopen-closed" in apply_steps[0]["command"], apply_steps[0]
    assert "--apply" in apply_steps[1]["command"], apply_steps[1]

    seen = []

    def fake_run(cmd):
        seen.append(cmd)
        if "backfill_issue_labels.py" in cmd[1]:
            return 1, "", "label-backfill-failed"
        return 0, "ok", ""

    results, verdict = mod.execute_steps(apply_steps, run_fn=fake_run)
    assert verdict == "fail", results
    assert len(results) == 2, results
    assert results[0]["name"] == "compile_plan_to_backlog", results
    assert results[1]["name"] == "backfill_issue_labels", results
    assert results[1]["stderr"] == "label-backfill-failed", results[1]

    violations = mod.collect_closed_match_violations(
        {
            "results": [
                {
                    "plan_item_id": "A60",
                    "execution_order": 60,
                    "closed_match_detected": True,
                    "closed_match_issue_number": 901,
                    "reused_closed_issue": False,
                }
            ]
        }
    )
    assert violations == [{"plan_item_id": "A60", "execution_order": 60, "closed_match_issue_number": 901}], violations

    preflight_args = SimpleNamespace(
        contract_file=str(contract_path),
        compile_config="planningops/config/project-field-ids.json",
        blueprint_defaults_config="planningops/config/ready-implementation-blueprint-defaults.json",
        compile_output=str(td_path / "compile-preflight.json"),
        allow_reopen_closed=False,
    )

    def fake_preflight_run(cmd):
        Path(preflight_args.compile_output).write_text(
            json.dumps(
                {
                    "results": [
                        {
                            "plan_item_id": "A60",
                            "execution_order": 60,
                            "closed_match_detected": True,
                            "closed_match_issue_number": 901,
                            "reused_closed_issue": False,
                        }
                    ]
                },
                ensure_ascii=True,
                indent=2,
            ),
            encoding="utf-8",
        )
        return 0, "ok", ""

    preflight = mod.run_apply_preflight(preflight_args, run_fn=fake_preflight_run)
    assert preflight["rc"] == 0, preflight
    assert preflight["closed_match_violations"] == violations, preflight

print("backlog materialization contract ok")
PY
