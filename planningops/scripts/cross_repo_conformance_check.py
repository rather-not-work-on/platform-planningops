#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


EXPECTED_SOURCE_REPO = "rather-not-work-on/platform-contracts"
PIN_CONSUMERS = [
    ("rather-not-work-on/platform-provider-gateway", "platform-provider-gateway/config/contract-pin.json"),
    ("rather-not-work-on/platform-observability-gateway", "platform-observability-gateway/config/contract-pin.json"),
    ("rather-not-work-on/monday", "monday/contracts/contract-pin.json"),
]


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run_cmd(cmd, cwd: Path):
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def parse_report_path(stdout: str):
    m = re.search(r"report written:\s*(.+)", stdout)
    if not m:
        return None
    return m.group(1).strip()


def validate_pin(workspace_root: Path, consumer_repo: str, rel_path: str):
    pin_path = workspace_root / rel_path
    if not pin_path.exists():
        return {
            "consumer_repo": consumer_repo,
            "pin_path": str(pin_path),
            "verdict": "fail",
            "reason": "pin_file_missing",
        }

    doc = json.loads(pin_path.read_text(encoding="utf-8"))
    errors = []
    if doc.get("source_repo") != EXPECTED_SOURCE_REPO:
        errors.append("source_repo_mismatch")
    if not doc.get("contract_bundle_version"):
        errors.append("contract_bundle_version_missing")
    if not isinstance(doc.get("pinned_contracts"), list) or not doc.get("pinned_contracts"):
        errors.append("pinned_contracts_missing")
    if doc.get("consumer_repo") != consumer_repo:
        errors.append("consumer_repo_mismatch")

    return {
        "consumer_repo": consumer_repo,
        "pin_path": str(pin_path),
        "contract_bundle_version": doc.get("contract_bundle_version"),
        "pinned_contracts": doc.get("pinned_contracts", []),
        "verdict": "pass" if not errors else "fail",
        "errors": errors,
    }


def main():
    parser = argparse.ArgumentParser(description="Cross-repo C1~C8 consumer conformance checks")
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
    args = parser.parse_args()

    planningops_repo = Path(__file__).resolve().parents[2]
    workspace_root = (planningops_repo / args.workspace_root).resolve()

    contract_repo = workspace_root / "platform-contracts"
    provider_repo = workspace_root / "platform-provider-gateway"
    o11y_repo = workspace_root / "platform-observability-gateway"
    monday_repo = workspace_root / "monday"

    checks = []

    def add_check(check_id, cwd: Path, cmd, expected_exit=0):
        rc, out, err = run_cmd(cmd, cwd)
        checks.append(
            {
                "check_id": check_id,
                "cwd": str(cwd),
                "command": cmd,
                "expected_exit": expected_exit,
                "exit_code": rc,
                "verdict": "pass" if rc == expected_exit else "fail",
                "stdout_tail": out[-1000:],
                "stderr_tail": err[-1000:],
            }
        )
        return rc, out, err

    add_check(
        "contracts.validate",
        contract_repo,
        ["python3", "scripts/validate_contracts.py", "--root", "."],
        expected_exit=0,
    )

    _, semver_out, _ = add_check(
        "contracts.semver_classification",
        contract_repo,
        ["python3", "scripts/classify_schema_change.py", "--enforce-expected"],
        expected_exit=0,
    )

    add_check(
        "provider.primary_success",
        provider_repo,
        ["python3", "scripts/litellm_gateway_smoke.py", "--scenario", "primary_success", "--run-id", args.run_id],
        expected_exit=0,
    )

    add_check(
        "provider.contract_violation_fail_fast",
        provider_repo,
        ["python3", "scripts/litellm_gateway_smoke.py", "--scenario", "contract_violation", "--run-id", args.run_id],
        expected_exit=1,
    )

    add_check(
        "o11y.delay_and_replay",
        o11y_repo,
        ["python3", "scripts/langfuse_ingest_smoke.py", "--scenario", "delay_and_replay", "--run-id", args.run_id],
        expected_exit=0,
    )

    add_check(
        "runtime.handoff_mapping",
        monday_repo,
        ["python3", "scripts/validate_handoff_mapping.py"],
        expected_exit=0,
    )

    pin_results = [validate_pin(workspace_root, consumer_repo, rel_path) for consumer_repo, rel_path in PIN_CONSUMERS]

    semver_major_present = False
    semver_report_path = parse_report_path(semver_out)
    if semver_report_path:
        p = contract_repo / semver_report_path
        if p.exists():
            semver_doc = json.loads(p.read_text(encoding="utf-8"))
            semver_major_present = any(r.get("computed_bump") == "major" for r in semver_doc.get("results", []))

    provider_violation_path = provider_repo / f"artifacts/smoke/{args.run_id}-contract_violation.json"
    provider_violation_ok = False
    if provider_violation_path.exists():
        provider_doc = json.loads(provider_violation_path.read_text(encoding="utf-8"))
        provider_violation_ok = (
            provider_doc.get("verdict") == "fail" and provider_doc.get("reason_code") == "contract_violation"
        )

    incompatibility_example = {
        "semver_major_example_present": semver_major_present,
        "provider_fail_fast_example_present": provider_violation_ok,
        "provider_fail_fast_report": str(provider_violation_path),
        "verdict": "pass" if semver_major_present and provider_violation_ok else "fail",
    }

    any_check_fail = any(c["verdict"] != "pass" for c in checks)
    any_pin_fail = any(p["verdict"] != "pass" for p in pin_results)
    verdict = "pass" if (not any_check_fail and not any_pin_fail and incompatibility_example["verdict"] == "pass") else "fail"

    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "checks": checks,
        "pin_results": pin_results,
        "incompatibility_example": incompatibility_example,
        "verdict": verdict,
    }

    output_path = (
        Path(args.output)
        if args.output
        else planningops_repo / "planningops" / "artifacts" / "conformance" / f"{args.run_id}.json"
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"check_count={len(checks)} pin_count={len(pin_results)} verdict={verdict}")
    return 0 if verdict == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
