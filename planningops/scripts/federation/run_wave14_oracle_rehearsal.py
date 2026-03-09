#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[4]


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run_stack_smoke(
    planningops_repo: Path,
    workspace_root: Path,
    profile: str,
    run_id: str,
    output_path: Path,
    bootstrap_mode: str,
) -> tuple[int, dict]:
    command = [
        sys.executable,
        str(planningops_repo / "planningops/scripts/federation/run_local_runtime_stack_smoke.py"),
        "--workspace-root",
        str(workspace_root),
        "--profile",
        profile,
        "--run-id",
        run_id,
        "--output",
        str(output_path),
        "--bootstrap-mode",
        bootstrap_mode,
    ]
    completed = subprocess.run(command, cwd=str(planningops_repo), capture_output=True, text=True)
    report = load_json(output_path) if output_path.exists() else {}
    return completed.returncode, {
        "profile": profile,
        "command": command,
        "exit_code": completed.returncode,
        "stdout_tail": completed.stdout.strip()[-1000:],
        "stderr_tail": completed.stderr.strip()[-1000:],
        "report_path": str(output_path),
        "report_exists": output_path.exists(),
        "report": report,
        "verdict": "pass" if completed.returncode == 0 else "fail",
    }


def component_index(report: dict) -> dict[str, dict]:
    rows = {}
    for row in report.get("component_runs") or []:
        component = str(row.get("component") or "")
        if component:
            rows[component] = row
    return rows


def compare_components(local_report: dict, oracle_report: dict) -> list[dict]:
    local_components = component_index(local_report)
    oracle_components = component_index(oracle_report)
    names = sorted(set(local_components) | set(oracle_components))
    rows = []
    for name in names:
        local_row = local_components.get(name, {})
        oracle_row = oracle_components.get(name, {})
        local_verdict = str(local_row.get("verdict") or "missing")
        oracle_verdict = str(oracle_row.get("verdict") or "missing")
        profile_sensitive = name in {"monday", "provider"}
        portability_status = "portable"
        if local_verdict == "pass" and oracle_verdict != "pass":
            portability_status = "oracle_regression"
        elif local_verdict != "pass" and oracle_verdict == "pass":
            portability_status = "local_regression"
        elif local_verdict != "pass" and oracle_verdict != "pass":
            portability_status = "both_fail"
        rows.append(
            {
                "component": name,
                "profile_sensitive": profile_sensitive,
                "local_verdict": local_verdict,
                "oracle_verdict": oracle_verdict,
                "portability_status": portability_status,
                "local_report_summary": local_row.get("report_summary"),
                "oracle_report_summary": oracle_row.get("report_summary"),
            }
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Run wave14 local-vs-oracle rehearsal using the wave13 federated stack smoke")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--local-profile", default="local", help="Default local profile that must remain primary")
    parser.add_argument("--oracle-profile", default="oracle_cloud", help="Oracle rehearsal profile")
    parser.add_argument(
        "--run-id",
        default=f"wave14-oracle-rehearsal-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Optional output path. Defaults to planningops/runtime-artifacts/oracle-rehearsal/<run-id>.json",
    )
    parser.add_argument(
        "--bootstrap-mode",
        choices=["auto", "off", "require"],
        default="auto",
        help="Managed Python bootstrap mode passed through to the wave13 runner",
    )
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = (planningops_repo / args.workspace_root).resolve()
    base_dir = planningops_repo / "planningops/runtime-artifacts/oracle-rehearsal"
    local_report_path = base_dir / f"{args.run_id}-{args.local_profile}.json"
    oracle_report_path = base_dir / f"{args.run_id}-{args.oracle_profile}.json"

    local_run_rc, local_summary = run_stack_smoke(
        planningops_repo=planningops_repo,
        workspace_root=workspace_root,
        profile=args.local_profile,
        run_id=f"{args.run_id}-{args.local_profile}",
        output_path=local_report_path,
        bootstrap_mode=args.bootstrap_mode,
    )
    oracle_run_rc, oracle_summary = run_stack_smoke(
        planningops_repo=planningops_repo,
        workspace_root=workspace_root,
        profile=args.oracle_profile,
        run_id=f"{args.run_id}-{args.oracle_profile}",
        output_path=oracle_report_path,
        bootstrap_mode=args.bootstrap_mode,
    )

    component_comparison = compare_components(local_summary.get("report") or {}, oracle_summary.get("report") or {})
    portability_gaps = [row for row in component_comparison if row["portability_status"] != "portable"]
    rehearsal_supported_components = [row["component"] for row in component_comparison if row["profile_sensitive"]]
    shared_profile_components = [row["component"] for row in component_comparison if not row["profile_sensitive"]]

    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "default_profile_preserved": args.local_profile == "local",
        "oracle_rehearsal_only": True,
        "profiles": {
            "local": args.local_profile,
            "oracle": args.oracle_profile,
        },
        "runs": {
            "local": local_summary,
            "oracle": oracle_summary,
        },
        "component_comparison": component_comparison,
        "rehearsal_supported_components": rehearsal_supported_components,
        "shared_profile_components": shared_profile_components,
        "portability_gap_count": len(portability_gaps),
        "portability_gaps": portability_gaps,
        "verdict": "pass" if local_run_rc == 0 and oracle_run_rc == 0 and not portability_gaps else "fail",
        "reason_code": "ok" if local_run_rc == 0 and oracle_run_rc == 0 and not portability_gaps else "oracle_rehearsal_failed",
    }

    output_path = (
        Path(args.output)
        if args.output
        else planningops_repo / "planningops/runtime-artifacts/oracle-rehearsal" / f"{args.run_id}.json"
    )
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"verdict={report['verdict']} portability_gap_count={report['portability_gap_count']}")
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
