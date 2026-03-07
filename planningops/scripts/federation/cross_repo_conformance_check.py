#!/usr/bin/env python3

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


PIN_PATHS = {
    "provider": "platform-provider-gateway/config/contract-pin.json",
    "observability": "platform-observability-gateway/config/contract-pin.json",
    "monday": "monday/contracts/contract-pin.json",
}


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[3]


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def run_cmd(cmd, cwd: Path):
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidates = [
        (planningops_repo / raw_workspace_root).resolve(),
        planningops_repo,
        planningops_repo.parent,
    ]
    for candidate in candidates:
        if (candidate / "platform-contracts").exists() and (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def summarize_report(report_doc: dict | None, keys: list[str]):
    if not isinstance(report_doc, dict):
        return None
    return {key: report_doc.get(key) for key in keys}


def detect_bundle_versions(workspace_root: Path):
    versions = {}
    for consumer, rel_path in PIN_PATHS.items():
        path = workspace_root / rel_path
        if not path.exists():
            versions[consumer] = None
            continue
        try:
            versions[consumer] = load_json(path).get("contract_bundle_version")
        except Exception:  # noqa: BLE001
            versions[consumer] = None

    distinct_versions = sorted({v for v in versions.values() if v})
    return {
        "versions_by_repo": versions,
        "distinct_versions": distinct_versions,
        "resolved_bundle_version": distinct_versions[0] if len(distinct_versions) == 1 else None,
        "verdict": "pass" if len(distinct_versions) == 1 else "fail",
    }


def add_check(checks, check_id: str, cwd: Path, cmd: list[str], expected_exit: int = 0, report_path: Path | None = None, summary_keys: list[str] | None = None):
    rc, out, err = run_cmd(cmd, cwd)
    report_doc = None
    if report_path and report_path.exists():
        report_doc = load_json(report_path)
    check = {
        "check_id": check_id,
        "cwd": str(cwd),
        "command": cmd,
        "expected_exit": expected_exit,
        "exit_code": rc,
        "verdict": "pass" if rc == expected_exit else "fail",
        "stdout_tail": out[-1000:],
        "stderr_tail": err[-1000:],
    }
    if report_path:
        check["report_path"] = str(report_path)
        check["report_exists"] = report_path.exists()
    if summary_keys:
        check["report_summary"] = summarize_report(report_doc, summary_keys)
    checks.append(check)
    return check, report_doc


def main():
    parser = argparse.ArgumentParser(description="Cross-repo execution evidence conformance checks")
    parser.add_argument(
        "--workspace-root",
        default="..",
        help="Workspace root containing sibling repos",
    )
    parser.add_argument(
        "--run-id",
        default=f"cross-repo-conformance-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output report path (default: planningops/artifacts/conformance/<run-id>.json)",
    )
    parser.add_argument(
        "--run-root",
        default=None,
        help="Directory for support artifacts generated during conformance execution",
    )
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    output_path = (
        Path(args.output)
        if args.output
        else planningops_repo / "planningops" / "artifacts" / "conformance" / f"{args.run_id}.json"
    )
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    run_root = (
        Path(args.run_root)
        if args.run_root
        else (
            planningops_repo / "planningops" / "artifacts" / "conformance" / args.run_id
            if str(output_path).startswith(str(planningops_repo / "planningops" / "artifacts" / "conformance"))
            else output_path.parent / args.run_id
        )
    )
    if not run_root.is_absolute():
        run_root = planningops_repo / run_root
    run_root.mkdir(parents=True, exist_ok=True)

    contract_repo = workspace_root / "platform-contracts"
    provider_repo = workspace_root / "platform-provider-gateway"
    o11y_repo = workspace_root / "platform-observability-gateway"
    monday_repo = workspace_root / "monday"

    checks = []

    bundle_version_consistency = detect_bundle_versions(workspace_root)
    bundle_version = bundle_version_consistency["resolved_bundle_version"] or "unknown"

    contracts_dir = run_root / "contracts"
    provider_dir = run_root / "provider"
    o11y_dir = run_root / "observability"
    monday_dir = run_root / "monday"
    contracts_dir.mkdir(parents=True, exist_ok=True)
    provider_dir.mkdir(parents=True, exist_ok=True)
    o11y_dir.mkdir(parents=True, exist_ok=True)
    monday_dir.mkdir(parents=True, exist_ok=True)

    semver_report = contracts_dir / "semver-classification.json"
    contract_bundle_report = contracts_dir / "contract-bundle.json"
    contract_pin_report = contracts_dir / "consumer-contract-pins.json"

    add_check(
        checks,
        "contracts.validate",
        contract_repo,
        ["python3", "scripts/validate_contracts.py", "--root", "."],
        expected_exit=0,
    )
    _, semver_doc = add_check(
        checks,
        "contracts.semver_classification",
        contract_repo,
        [
            "python3",
            "scripts/classify_schema_change.py",
            "--enforce-expected",
            "--report",
            str(semver_report),
            "--output-dir",
            str(semver_report.parent),
        ],
        expected_exit=0,
        report_path=semver_report,
        summary_keys=["result_count", "highest_computed_bump"],
    )
    _, bundle_doc = add_check(
        checks,
        "contracts.publish_bundle",
        contract_repo,
        [
            "python3",
            "scripts/publish_contract_bundle.py",
            "--bundle-version",
            bundle_version,
            "--workspace-root",
            str(workspace_root),
            "--bundle-output",
            str(contract_bundle_report),
            "--pin-output",
            str(contract_pin_report),
            "--strict",
        ],
        expected_exit=0 if bundle_version_consistency["verdict"] == "pass" else 1,
        report_path=contract_bundle_report,
        summary_keys=["bundle_version", "schema_count", "source_repo"],
    )
    contract_pin_doc = load_json(contract_pin_report) if contract_pin_report.exists() else None

    provider_smoke_dir = provider_dir / "smoke"
    provider_smoke_dir.mkdir(parents=True, exist_ok=True)
    provider_primary_report = provider_smoke_dir / f"{args.run_id}-primary_success.json"
    provider_primary_validation = provider_dir / "primary_success.validation.json"
    provider_violation_report = provider_smoke_dir / f"{args.run_id}-contract_violation.json"
    provider_violation_validation = provider_dir / "contract_violation.validation.json"
    provider_pin_validation = provider_dir / "contract-pin-report.json"

    _, provider_primary_doc = add_check(
        checks,
        "provider.primary_success",
        provider_repo,
        [
            "python3",
            "scripts/litellm_gateway_smoke.py",
            "--scenario",
            "primary_success",
            "--run-id",
            args.run_id,
            "--output-dir",
            str(provider_smoke_dir),
        ],
        expected_exit=0,
        report_path=provider_primary_report,
        summary_keys=["verdict", "reason_code", "routing_profile"],
    )
    add_check(
        checks,
        "provider.primary_success_validation",
        provider_repo,
        [
            "python3",
            "scripts/validate_provider_smoke_evidence.py",
            "--report",
            str(provider_primary_report),
            "--output",
            str(provider_primary_validation),
        ],
        expected_exit=0,
        report_path=provider_primary_validation,
        summary_keys=["verdict", "error_count"],
    )
    _, provider_violation_doc = add_check(
        checks,
        "provider.contract_violation_fail_fast",
        provider_repo,
        [
            "python3",
            "scripts/litellm_gateway_smoke.py",
            "--scenario",
            "contract_violation",
            "--run-id",
            args.run_id,
            "--output-dir",
            str(provider_smoke_dir),
        ],
        expected_exit=1,
        report_path=provider_violation_report,
        summary_keys=["verdict", "reason_code", "routing_profile"],
    )
    add_check(
        checks,
        "provider.contract_violation_validation",
        provider_repo,
        [
            "python3",
            "scripts/validate_provider_smoke_evidence.py",
            "--report",
            str(provider_violation_report),
            "--output",
            str(provider_violation_validation),
        ],
        expected_exit=0,
        report_path=provider_violation_validation,
        summary_keys=["verdict", "error_count"],
    )
    add_check(
        checks,
        "provider.contract_pin",
        provider_repo,
        [
            "python3",
            "scripts/validate_contract_pin.py",
            "--output",
            str(provider_pin_validation),
        ],
        expected_exit=0,
        report_path=provider_pin_validation,
        summary_keys=["verdict", "error_count", "warning_count"],
    )

    o11y_ingest_dir = o11y_dir / "ingest"
    o11y_ingest_dir.mkdir(parents=True, exist_ok=True)
    o11y_normal_report = o11y_ingest_dir / f"{args.run_id}-normal.json"
    o11y_normal_validation = o11y_dir / "normal.validation.json"
    o11y_replay_report = o11y_ingest_dir / f"{args.run_id}-delay_and_replay.json"
    o11y_replay_validation = o11y_dir / "delay_and_replay.validation.json"
    o11y_pin_validation = o11y_dir / "contract-pin-report.json"

    add_check(
        checks,
        "o11y.normal",
        o11y_repo,
        [
            "python3",
            "scripts/langfuse_ingest_smoke.py",
            "--scenario",
            "normal",
            "--run-id",
            args.run_id,
            "--output-dir",
            str(o11y_ingest_dir),
        ],
        expected_exit=0,
        report_path=o11y_normal_report,
        summary_keys=["verdict", "reason_code", "ingest_profile"],
    )
    add_check(
        checks,
        "o11y.normal_validation",
        o11y_repo,
        [
            "python3",
            "scripts/validate_ingest_smoke_evidence.py",
            "--report",
            str(o11y_normal_report),
            "--output",
            str(o11y_normal_validation),
        ],
        expected_exit=0,
        report_path=o11y_normal_validation,
        summary_keys=["verdict", "error_count"],
    )
    _, o11y_replay_doc = add_check(
        checks,
        "o11y.delay_and_replay",
        o11y_repo,
        [
            "python3",
            "scripts/langfuse_ingest_smoke.py",
            "--scenario",
            "delay_and_replay",
            "--run-id",
            args.run_id,
            "--output-dir",
            str(o11y_ingest_dir),
        ],
        expected_exit=0,
        report_path=o11y_replay_report,
        summary_keys=["verdict", "reason_code", "ingest_profile"],
    )
    add_check(
        checks,
        "o11y.delay_and_replay_validation",
        o11y_repo,
        [
            "python3",
            "scripts/validate_ingest_smoke_evidence.py",
            "--report",
            str(o11y_replay_report),
            "--output",
            str(o11y_replay_validation),
        ],
        expected_exit=0,
        report_path=o11y_replay_validation,
        summary_keys=["verdict", "error_count"],
    )
    add_check(
        checks,
        "o11y.contract_pin",
        o11y_repo,
        [
            "python3",
            "scripts/validate_contract_pin.py",
            "--output",
            str(o11y_pin_validation),
        ],
        expected_exit=0,
        report_path=o11y_pin_validation,
        summary_keys=["verdict", "error_count", "warning_count"],
    )

    monday_handoff_report = monday_dir / "handoff-smoke-report.json"
    monday_handoff_validation = monday_dir / "handoff.validation.json"
    monday_scheduler_report = monday_dir / "scheduler-run-report.json"
    monday_scheduler_validation = monday_dir / "scheduler.validation.json"
    monday_integration_report = monday_dir / "planningops-handoff-report.json"
    monday_integration_validation = monday_dir / "integration.validation.json"
    monday_queue_out = monday_dir / "queue.from-planningops.json"
    monday_idempotency = monday_dir / "idempotency.json"
    monday_transition_log = monday_dir / "scheduler.ndjson"
    monday_pin_validation = monday_dir / "contract-pin-report.json"

    add_check(
        checks,
        "monday.handoff_mapping",
        monday_repo,
        [
            "python3",
            "scripts/validate_handoff_mapping.py",
            "--run-id",
            args.run_id,
            "--output",
            str(monday_handoff_report),
        ],
        expected_exit=0,
        report_path=monday_handoff_report,
        summary_keys=["verdict", "reason_code", "mismatch_count"],
    )
    add_check(
        checks,
        "monday.handoff_validation",
        monday_repo,
        [
            "python3",
            "scripts/validate_runtime_evidence.py",
            "--kind",
            "handoff",
            "--report",
            str(monday_handoff_report),
            "--output",
            str(monday_handoff_validation),
        ],
        expected_exit=0,
        report_path=monday_handoff_validation,
        summary_keys=["verdict", "error_count"],
    )
    _, monday_integration_doc = add_check(
        checks,
        "monday.integration",
        monday_repo,
        [
            "python3",
            "scripts/integrate_planningops_handoff.py",
            "--planningops-last-run",
            str(planningops_repo / "planningops" / "artifacts" / "loop-runner" / "last-run.json"),
            "--run-id",
            args.run_id,
            "--handoff-report",
            str(monday_handoff_report),
            "--queue-out",
            str(monday_queue_out),
            "--scheduler-report",
            str(monday_scheduler_report),
            "--integration-report",
            str(monday_integration_report),
            "--idempotency",
            str(monday_idempotency),
            "--transition-log",
            str(monday_transition_log),
        ],
        expected_exit=0,
        report_path=monday_integration_report,
        summary_keys=["verdict", "reason_code", "queue_path"],
    )
    add_check(
        checks,
        "monday.scheduler_validation",
        monday_repo,
        [
            "python3",
            "scripts/validate_runtime_evidence.py",
            "--kind",
            "scheduler",
            "--report",
            str(monday_scheduler_report),
            "--output",
            str(monday_scheduler_validation),
        ],
        expected_exit=0,
        report_path=monday_scheduler_validation,
        summary_keys=["verdict", "error_count"],
    )
    add_check(
        checks,
        "monday.integration_validation",
        monday_repo,
        [
            "python3",
            "scripts/validate_runtime_evidence.py",
            "--kind",
            "integration",
            "--report",
            str(monday_integration_report),
            "--output",
            str(monday_integration_validation),
        ],
        expected_exit=0,
        report_path=monday_integration_validation,
        summary_keys=["verdict", "error_count"],
    )
    add_check(
        checks,
        "monday.contract_pin",
        monday_repo,
        [
            "python3",
            "scripts/validate_contract_pin.py",
            "--output",
            str(monday_pin_validation),
        ],
        expected_exit=0,
        report_path=monday_pin_validation,
        summary_keys=["verdict", "error_count", "warning_count"],
    )

    semver_major_present = False
    if isinstance(semver_doc, dict):
        semver_major_present = any(row.get("computed_bump") == "major" for row in semver_doc.get("results", []))

    incompatibility_example = {
        "semver_major_example_present": semver_major_present,
        "provider_fail_fast_example_present": (
            isinstance(provider_violation_doc, dict)
            and provider_violation_doc.get("verdict") == "fail"
            and provider_violation_doc.get("reason_code") == "contract_violation"
        ),
        "provider_fail_fast_report": str(provider_violation_report),
        "verdict": "pass"
        if semver_major_present
        and isinstance(provider_violation_doc, dict)
        and provider_violation_doc.get("verdict") == "fail"
        and provider_violation_doc.get("reason_code") == "contract_violation"
        else "fail",
    }

    evidence_assertions = {
        "bundle_version_consistency": bundle_version_consistency,
        "contract_bundle_published": {
            "report_path": str(contract_bundle_report),
            "verdict": "pass"
            if isinstance(bundle_doc, dict) and bundle_doc.get("schema_count", 0) > 0
            else "fail",
        },
        "consumer_pin_evidence": {
            "report_path": str(contract_pin_report),
            "verdict": "pass"
            if isinstance(contract_pin_doc, dict)
            and all(row.get("verdict") == "pass" for row in contract_pin_doc.get("consumer_results", []))
            else "fail",
        },
        "provider_evidence": {
            "primary_reason_code": provider_primary_doc.get("reason_code") if isinstance(provider_primary_doc, dict) else None,
            "violation_reason_code": provider_violation_doc.get("reason_code") if isinstance(provider_violation_doc, dict) else None,
            "verdict": "pass"
            if isinstance(provider_primary_doc, dict)
            and provider_primary_doc.get("verdict") == "pass"
            and provider_primary_doc.get("reason_code") == "ok"
            and isinstance(provider_violation_doc, dict)
            and provider_violation_doc.get("verdict") == "fail"
            and provider_violation_doc.get("reason_code") == "contract_violation"
            else "fail",
        },
        "observability_evidence": {
            "replay_reason_code": o11y_replay_doc.get("reason_code") if isinstance(o11y_replay_doc, dict) else None,
            "verdict": "pass"
            if isinstance(o11y_replay_doc, dict)
            and o11y_replay_doc.get("verdict") == "pass"
            and o11y_replay_doc.get("reason_code") == "replay_recovered"
            else "fail",
        },
        "runtime_evidence": {
            "integration_reason_code": monday_integration_doc.get("reason_code") if isinstance(monday_integration_doc, dict) else None,
            "verdict": "pass"
            if isinstance(monday_integration_doc, dict)
            and monday_integration_doc.get("verdict") == "pass"
            and monday_integration_doc.get("reason_code") == "ok"
            else "fail",
        },
    }

    any_check_fail = any(c["verdict"] != "pass" for c in checks)
    any_assertion_fail = any(row.get("verdict") != "pass" for row in evidence_assertions.values())
    verdict = "pass" if (not any_check_fail and not any_assertion_fail and incompatibility_example["verdict"] == "pass") else "fail"

    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "run_root": str(run_root),
        "checks": checks,
        "evidence_assertions": evidence_assertions,
        "incompatibility_example": incompatibility_example,
        "verdict": verdict,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(
        " ".join(
            [
                f"check_count={len(checks)}",
                f"assertion_count={len(evidence_assertions)}",
                f"incompatibility_example={incompatibility_example['verdict']}",
                f"verdict={verdict}",
            ]
        )
    )
    return 0 if verdict == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
