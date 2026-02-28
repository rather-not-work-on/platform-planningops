#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone


def utc_now():
    return datetime.now(timezone.utc)


def write_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def append_ndjson(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=True) + "\n")


def run_cmd(args):
    completed = subprocess.run(args, capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def main():
    parser = argparse.ArgumentParser(description="Local Ralph Loop harness")
    parser.add_argument("--issue-number", type=int, required=True)
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--ecp-ref",
        default="planningops/templates/ecp-template.md",
        help="ECP reference path",
    )
    args = parser.parse_args()

    now = utc_now()
    date_str = now.strftime("%Y-%m-%d")
    loop_id = f"loop-{now.strftime('%Y%m%dT%H%M%SZ')}-issue-{args.issue_number}"

    base = Path(f"planningops/artifacts/loops/{date_str}/{loop_id}")
    intake_path = base / "intake-check.json"
    simulation_path = base / "simulation-report.md"
    verification_path = base / "verification-report.json"
    patch_summary_path = base / "patch-summary.md"
    transition_log_path = Path(f"planningops/artifacts/transition-log/{date_str}.ndjson")

    # Step 1: intake
    if args.issue_number <= 0:
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "intake",
                "executed_at_utc": now.isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-intake-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "Todo",
                "to_state": "Blocked",
                "transition_reason": "context.missing_input",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": now.isoformat(),
                "replanning_flag": True,
            },
        )
        print("loop failed at intake: missing_input")
        return 1

    write_json(
        intake_path,
        {
            "issue_number": args.issue_number,
            "loop_id": loop_id,
            "mode": args.mode,
            "ecp_ref": args.ecp_ref,
            "checked_at_utc": now.isoformat(),
            "result": "ok",
        },
    )

    # Step 2: context load
    ecp_path = Path(args.ecp_ref)
    if not ecp_path.exists():
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "context_load",
                "executed_at_utc": utc_now().isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-context-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "In Progress",
                "to_state": "Blocked",
                "transition_reason": "context.missing_ecp",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": utc_now().isoformat(),
                "replanning_flag": True,
            },
        )
        print("loop failed at context load: missing ecp")
        return 1

    # Step 3: execute (parser/diff pipeline)
    rc, out, err = run_cmd(
        [
            "python3",
            "planningops/scripts/parser_diff_dry_run.py",
            "--run-id",
            loop_id,
            "--mode",
            args.mode,
        ]
    )

    simulation_path.parent.mkdir(parents=True, exist_ok=True)
    simulation_path.write_text(
        "\n".join(
            [
                f"# Simulation Report ({loop_id})",
                "",
                f"- mode: {args.mode}",
                f"- issue_number: {args.issue_number}",
                "- execute command: parser_diff_dry_run",
                "",
                "## Output",
                "```text",
                out,
                err,
                "```",
            ]
        ),
        encoding="utf-8",
    )

    if rc != 0:
        reason = "runtime_error"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "execute",
                "executed_at_utc": utc_now().isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-execute-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "In Progress",
                "to_state": "Blocked",
                "transition_reason": "runtime.execute_error",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": utc_now().isoformat(),
                "replanning_flag": True,
            },
        )
        print("loop failed at execute")
        return 1

    # Step 4: verify
    summary_path = Path(f"planningops/artifacts/sync-summary/{loop_id}.json")
    verdict = "pass" if summary_path.exists() else "inconclusive"
    reason = "ok" if summary_path.exists() else "missing_artifact"

    write_json(
        verification_path,
        {
            "issue_number": args.issue_number,
            "loop_id": loop_id,
            "verdict": verdict,
            "reason_code": reason,
            "artifacts": {
                "intake_check": str(intake_path),
                "simulation_report": str(simulation_path),
                "verification_report": str(verification_path),
                "transition_log": str(transition_log_path),
                "sync_summary": str(summary_path),
            },
            "executed_at_utc": utc_now().isoformat(),
        },
    )

    # Step 5: report
    patch_summary_path.write_text(
        "\n".join(
            [
                f"# Patch Summary ({loop_id})",
                "",
                f"- issue_number: {args.issue_number}",
                f"- mode: {args.mode}",
                f"- verdict: {verdict}",
                f"- reason_code: {reason}",
                "",
                "No code patch is applied by this local harness baseline."
                if args.mode == "dry-run"
                else "Apply mode executed pipeline and produced artifacts.",
            ]
        ),
        encoding="utf-8",
    )

    append_ndjson(
        transition_log_path,
        {
            "transition_id": f"{loop_id}-complete",
            "run_id": loop_id,
            "card_id": args.issue_number,
            "from_state": "In Progress",
            "to_state": "Done" if verdict == "pass" else "Blocked",
            "transition_reason": f"verification.{reason}",
            "actor_type": "agent",
            "actor_id": "ralph-loop-local",
            "decided_at_utc": utc_now().isoformat(),
            "replanning_flag": verdict != "pass",
        },
    )

    print(f"loop completed: verdict={verdict} reason={reason} loop_id={loop_id}")
    print(f"artifacts root: {base}")
    return 0 if verdict == "pass" else 2


if __name__ == "__main__":
    sys.exit(main())
