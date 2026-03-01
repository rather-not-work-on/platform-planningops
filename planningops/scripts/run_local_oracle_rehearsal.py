#!/usr/bin/env python3

import argparse
import copy
import json
import statistics
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path
import sys


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run_cmd(cmd):
    started = time.perf_counter()
    cp = subprocess.run(cmd, capture_output=True, text=True)
    elapsed_ms = int((time.perf_counter() - started) * 1000)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip(), elapsed_ms


def mean(values):
    return round(statistics.mean(values), 2) if values else 0.0


def percentile_95(values):
    if not values:
        return 0.0
    ordered = sorted(values)
    idx = int(0.95 * (len(ordered) - 1))
    return float(ordered[idx])


def estimate_cost(profile_name: str, run_count: int):
    # deterministic rough estimate for rehearsal comparison only
    unit = 0.002 if profile_name == "local" else 0.007
    return round(unit * run_count, 4)


def main():
    parser = argparse.ArgumentParser(description="Run 7-cycle local-first pilot with oracle partial migration rehearsal")
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--start-issue", type=int, default=3100)
    parser.add_argument("--runtime-profile-file", default="planningops/config/runtime-profiles.json")
    parser.add_argument(
        "--output-dir",
        default="planningops/artifacts/pilot",
    )
    parser.add_argument("--run-id", default=f"pilot-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    runtime_profile_path = Path(args.runtime_profile_file)
    runtime_doc = json.loads(runtime_profile_path.read_text(encoding="utf-8"))
    temp_runtime_doc = copy.deepcopy(runtime_doc)

    oracle_days = [d for d in range(1, args.days + 1) if d % 2 == 0]
    for day in oracle_days:
        task_key = f"pilot-day-{day}"
        temp_runtime_doc.setdefault("task_overrides", {})[task_key] = {
            "runtime_profile": "oracle_cloud",
            "provider_policy": {
                "model": "pilot-oracle",
                "fallback_models": ["pilot-oracle-fallback"],
                "max_retries": 2,
                "timeout_ms": 60000,
            },
        }

    temp_runtime_path = output_dir / f"{args.run_id}-runtime-profiles.json"
    temp_runtime_path.write_text(json.dumps(temp_runtime_doc, ensure_ascii=True, indent=2), encoding="utf-8")

    runs = []
    for day in range(1, args.days + 1):
        issue_number = args.start_issue + day
        task_key = f"pilot-day-{day}"
        profile = "oracle_cloud" if day in oracle_days else "local"
        cmd = [
            "python3",
            "planningops/scripts/ralph_loop_local.py",
            "--issue-number",
            str(issue_number),
            "--mode",
            "dry-run",
            "--runtime-profile-file",
            str(temp_runtime_path),
            "--task-key",
            task_key,
        ]
        rc, out, err, elapsed_ms = run_cmd(cmd)
        runs.append(
            {
                "day": day,
                "issue_number": issue_number,
                "task_key": task_key,
                "profile": profile,
                "exit_code": rc,
                "elapsed_ms": elapsed_ms,
                "stdout_tail": out[-800:],
                "stderr_tail": err[-800:],
                "verdict": "pass" if rc == 0 else "fail",
                "hard_stop": rc not in {0, 2},
            }
        )

    local_runs = [r for r in runs if r["profile"] == "local"]
    oracle_runs = [r for r in runs if r["profile"] == "oracle_cloud"]

    local_latencies = [r["elapsed_ms"] for r in local_runs]
    oracle_latencies = [r["elapsed_ms"] for r in oracle_runs]
    local_fail_rate = 0.0 if not local_runs else round(sum(1 for r in local_runs if r["verdict"] != "pass") / len(local_runs), 4)
    oracle_fail_rate = (
        0.0 if not oracle_runs else round(sum(1 for r in oracle_runs if r["verdict"] != "pass") / len(oracle_runs), 4)
    )
    hard_stops = [r for r in runs if r["hard_stop"]]

    rollback_triggered = (
        oracle_fail_rate > local_fail_rate + 0.1
        or (oracle_latencies and local_latencies and percentile_95(oracle_latencies) > percentile_95(local_latencies) * 2)
        or len(hard_stops) > 0
    )

    rollback_reasons = []
    if oracle_fail_rate > local_fail_rate + 0.1:
        rollback_reasons.append("oracle_fail_rate_regression")
    if oracle_latencies and local_latencies and percentile_95(oracle_latencies) > percentile_95(local_latencies) * 2:
        rollback_reasons.append("oracle_latency_regression")
    if hard_stops:
        rollback_reasons.append("hard_stop_detected")

    summary = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "days": args.days,
        "runs": runs,
        "profiles": {
            "local": {
                "run_count": len(local_runs),
                "mean_latency_ms": mean(local_latencies),
                "p95_latency_ms": percentile_95(local_latencies),
                "fail_rate": local_fail_rate,
                "estimated_cost": estimate_cost("local", len(local_runs)),
            },
            "oracle_cloud": {
                "run_count": len(oracle_runs),
                "mean_latency_ms": mean(oracle_latencies),
                "p95_latency_ms": percentile_95(oracle_latencies),
                "fail_rate": oracle_fail_rate,
                "estimated_cost": estimate_cost("oracle_cloud", len(oracle_runs)),
            },
        },
        "hard_stop_count": len(hard_stops),
        "hard_stop_taxonomy": [
            {
                "day": r["day"],
                "issue_number": r["issue_number"],
                "exit_code": r["exit_code"],
                "profile": r["profile"],
            }
            for r in hard_stops
        ],
        "rollback_trigger": {
            "triggered": rollback_triggered,
            "reasons": rollback_reasons,
        },
        "next_wave_proposals": [
            "Keep local-first as default and keep oracle_cloud to scoped workloads until fail-rate parity is stable.",
            "Promote federated CI required checks as branch protection after 2 consecutive green rehearsal runs.",
            "Add per-issue token usage capture to replace estimated cost with measured cost in next pilot.",
        ],
    }

    json_out = output_dir / f"{args.run_id}.json"
    json_out.write_text(json.dumps(summary, ensure_ascii=True, indent=2), encoding="utf-8")

    md_lines = [
        f"# 7-cycle Local-first Pilot and Oracle Partial Rehearsal ({args.run_id})",
        "",
        f"- generated_at_utc: {summary['generated_at_utc']}",
        f"- days: {args.days}",
        "",
        "## Profile Comparison",
        "",
        "| Profile | Runs | Mean Latency (ms) | p95 Latency (ms) | Fail Rate | Estimated Cost |",
        "|---|---:|---:|---:|---:|---:|",
        f"| local | {summary['profiles']['local']['run_count']} | {summary['profiles']['local']['mean_latency_ms']} | {summary['profiles']['local']['p95_latency_ms']} | {summary['profiles']['local']['fail_rate']} | {summary['profiles']['local']['estimated_cost']} |",
        f"| oracle_cloud | {summary['profiles']['oracle_cloud']['run_count']} | {summary['profiles']['oracle_cloud']['mean_latency_ms']} | {summary['profiles']['oracle_cloud']['p95_latency_ms']} | {summary['profiles']['oracle_cloud']['fail_rate']} | {summary['profiles']['oracle_cloud']['estimated_cost']} |",
        "",
        "## Rollback Trigger",
        f"- triggered: {summary['rollback_trigger']['triggered']}",
        f"- reasons: {', '.join(summary['rollback_trigger']['reasons']) if summary['rollback_trigger']['reasons'] else 'none'}",
        "",
        "## Hard-stop Taxonomy",
        f"- hard_stop_count: {summary['hard_stop_count']}",
    ]
    if summary["hard_stop_taxonomy"]:
        md_lines.extend(
            [
                "",
                "| Day | Issue | Exit Code | Profile |",
                "|---|---:|---:|---|",
            ]
        )
        for row in summary["hard_stop_taxonomy"]:
            md_lines.append(f"| {row['day']} | {row['issue_number']} | {row['exit_code']} | {row['profile']} |")
    else:
        md_lines.append("- no hard-stop detected")

    md_lines.extend(
        [
            "",
            "## Next Wave Proposals",
        ]
    )
    for item in summary["next_wave_proposals"]:
        md_lines.append(f"- {item}")

    md_out = output_dir / f"{args.run_id}.md"
    md_out.write_text("\n".join(md_lines), encoding="utf-8")

    print(f"report written: {json_out}")
    print(f"report written: {md_out}")
    print(f"rollback_triggered={summary['rollback_trigger']['triggered']} hard_stop_count={summary['hard_stop_count']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
