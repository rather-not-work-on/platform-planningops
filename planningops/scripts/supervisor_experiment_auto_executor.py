#!/usr/bin/env python3

import argparse
import json
import os
import re
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(args, cwd=None):
    cp = subprocess.run(args, capture_output=True, text=True, cwd=cwd)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def sanitize_fragment(value: str):
    lowered = re.sub(r"[^a-zA-Z0-9._-]+", "-", value.strip().lower())
    return re.sub(r"-+", "-", lowered).strip("-") or "unknown"


def parse_options(raw: str):
    items = [x.strip() for x in raw.split(",") if x.strip()]
    return items if items else ["option-a", "option-b"]


def score_option(final_rc: int, executed_commands: int):
    correctness = 5 if final_rc == 0 else 2
    complexity = 4 if executed_commands <= 3 else 3
    maintainability = 4 if final_rc == 0 else 2
    rollback = 4 if final_rc == 0 else 3
    weighted_total = (
        correctness * 0.40
        + complexity * 0.20
        + maintainability * 0.20
        + rollback * 0.20
    )
    return {
        "correctness_safety": correctness,
        "implementation_complexity": complexity,
        "maintainability_drift_risk": maintainability,
        "rollback_cost": rollback,
        "weighted_total": round(weighted_total, 3),
    }


def choose_option(option_reports):
    eligible = []
    for report in option_reports:
        scores = report.get("scores") or {}
        if int(scores.get("correctness_safety") or 0) < 3:
            continue
        eligible.append(report)
    if not eligible:
        return None
    eligible.sort(
        key=lambda x: (
            float((x.get("scores") or {}).get("weighted_total") or 0.0),
            x.get("option", ""),
        ),
        reverse=True,
    )
    # Reverse + option alpha tie-break is handled by secondary key; enforce deterministic tie resolution.
    max_score = float((eligible[0].get("scores") or {}).get("weighted_total") or 0.0)
    top = [row for row in eligible if float((row.get("scores") or {}).get("weighted_total") or 0.0) == max_score]
    top.sort(key=lambda x: x.get("option", ""))
    return top[0]


def run_validation_pack(commands, worktree_path: Path):
    records = []
    final_rc = 0
    for row in commands:
        row_id = str(row.get("id") or "command")
        cmd = row.get("command")
        if not isinstance(cmd, list) or not cmd:
            records.append(
                {
                    "id": row_id,
                    "command": cmd,
                    "rc": 1,
                    "duration_ms": 0,
                    "stdout_tail": "",
                    "stderr_tail": "invalid command shape",
                }
            )
            final_rc = 1
            break

        start = time.time()
        rc, out, err = run(cmd, cwd=str(worktree_path))
        duration_ms = int((time.time() - start) * 1000)
        records.append(
            {
                "id": row_id,
                "command": cmd,
                "rc": rc,
                "duration_ms": duration_ms,
                "stdout_tail": out[-1200:],
                "stderr_tail": err[-1200:],
            }
        )
        if rc != 0:
            final_rc = rc
            break
    return final_rc, records


def write_decision_record(path: Path, selected, option_reports):
    rows = []
    for report in option_reports:
        scores = report.get("scores") or {}
        rows.append(
            "| {opt} | {rc} | {cs} | {ic} | {md} | {rb} | {wt:.3f} |".format(
                opt=report.get("option"),
                rc=report.get("rc"),
                cs=int(scores.get("correctness_safety") or 0),
                ic=int(scores.get("implementation_complexity") or 0),
                md=int(scores.get("maintainability_drift_risk") or 0),
                rb=int(scores.get("rollback_cost") or 0),
                wt=float(scores.get("weighted_total") or 0.0),
            )
        )
    rejected = [r.get("option") for r in option_reports if not selected or r.get("option") != selected.get("option")]
    selected_option = selected.get("option") if selected else "none"

    content = [
        "# Supervisor Experiment Decision Record",
        "",
        f"- generated_at_utc: {now_utc()}",
        f"- selected_option: {selected_option}",
        f"- rejected_options: {', '.join(rejected) if rejected else '(none)'}",
        "",
        "## Score Table",
        "| option | rc | correctness/safety | implementation complexity | maintainability/drift risk | rollback cost | weighted_total |",
        "|---|---:|---:|---:|---:|---:|---:|",
        *rows,
        "",
        "## Safety Gate Notes",
        "- Safety threshold: correctness/safety >= 3 required.",
        "",
        "## Rollback Plan",
        "- Remove option branch/worktree artifacts and keep only selected option decision record.",
        "",
        "## Follow-Up Tasks",
        "- If selected option is `none`, create recovery backlog item with failing command evidence.",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(content), encoding="utf-8")


def parse_args():
    parser = argparse.ArgumentParser(description="Execute supervisor-triggered comparative experiment automatically")
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--experiment-id", required=True)
    parser.add_argument("--topic", required=True)
    parser.add_argument("--options", default="option-a,option-b")
    parser.add_argument(
        "--validation-pack-file",
        default="planningops/config/supervisor-experiment-validation-pack.json",
    )
    parser.add_argument("--artifacts-root", default="planningops/artifacts/experiments")
    parser.add_argument("--worktree-root", default="/tmp/planningops-supervisor-experiments")
    parser.add_argument("--base-ref", default="HEAD")
    parser.add_argument("--keep-worktrees", action="store_true")
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def main():
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    experiment_id = sanitize_fragment(args.experiment_id)
    options = parse_options(args.options)
    validation_pack = load_json(Path(args.validation_pack_file), {})
    commands = validation_pack.get("commands", [])
    if not isinstance(commands, list) or not commands:
        print("validation pack must include non-empty commands list")
        return 1

    artifacts_root = Path(args.artifacts_root)
    experiment_dir = artifacts_root / experiment_id
    experiment_dir.mkdir(parents=True, exist_ok=True)

    worktree_root = Path(args.worktree_root).resolve()
    worktree_root.mkdir(parents=True, exist_ok=True)

    option_reports = []
    manifest = {
        "generated_at_utc": now_utc(),
        "experiment_id": experiment_id,
        "topic": args.topic,
        "trigger": "supervisor_experiment_auto_executor",
        "repo_root": str(repo_root),
        "base_ref": args.base_ref,
        "validation_pack_file": str(Path(args.validation_pack_file)),
        "validation_pack_id": validation_pack.get("pack_id", "unknown"),
        "options": options,
        "validation_commands": commands,
    }
    save_json(experiment_dir / "manifest.json", manifest)

    failures = []
    created_worktrees = []
    created_branches = []
    for option in options:
        option_id = sanitize_fragment(option)
        branch_name = sanitize_fragment(f"exp-{experiment_id}-{option_id}")
        worktree_path = worktree_root / f"{experiment_id}-{option_id}"

        rc_add, out_add, err_add = run(
            ["git", "-C", str(repo_root), "worktree", "add", "-b", branch_name, str(worktree_path), args.base_ref]
        )
        if rc_add != 0:
            report = {
                "generated_at_utc": now_utc(),
                "option": option_id,
                "branch": branch_name,
                "worktree": str(worktree_path),
                "rc": rc_add,
                "commands": [],
                "summary": "worktree_add_failed",
                "errors": [err_add or out_add],
                "scores": score_option(1, 0),
                "artifacts": {},
            }
            option_reports.append(report)
            failures.append(f"worktree_add_failed:{option_id}")
            save_json(experiment_dir / f"option-{option_id}-report.json", report)
            continue

        created_worktrees.append(worktree_path)
        created_branches.append(branch_name)
        final_rc, command_records = run_validation_pack(commands, worktree_path)
        scores = score_option(final_rc, len(command_records))
        report = {
            "generated_at_utc": now_utc(),
            "option": option_id,
            "branch": branch_name,
            "worktree": str(worktree_path),
            "rc": final_rc,
            "commands": command_records,
            "summary": "pass" if final_rc == 0 else "fail",
            "errors": [] if final_rc == 0 else [row.get("stderr_tail", "") for row in command_records if row.get("rc") != 0],
            "scores": scores,
            "artifacts": {
                "option_report": str(experiment_dir / f"option-{option_id}-report.json"),
            },
        }
        option_reports.append(report)
        save_json(experiment_dir / f"option-{option_id}-report.json", report)

        if final_rc != 0:
            failures.append(f"validation_failed:{option_id}")

    selected = choose_option(option_reports)
    decision_record_path = experiment_dir / "decision-record.md"
    write_decision_record(decision_record_path, selected, option_reports)

    cleanup = {
        "keep_worktrees": bool(args.keep_worktrees),
        "removed_worktrees": [],
        "removed_branches": [],
        "cleanup_errors": [],
    }
    if not args.keep_worktrees:
        for worktree_path in created_worktrees:
            rc_rm, out_rm, err_rm = run(["git", "-C", str(repo_root), "worktree", "remove", "--force", str(worktree_path)])
            if rc_rm == 0:
                cleanup["removed_worktrees"].append(str(worktree_path))
            else:
                cleanup["cleanup_errors"].append(err_rm or out_rm)
        for branch_name in created_branches:
            rc_bd, out_bd, err_bd = run(["git", "-C", str(repo_root), "branch", "-D", branch_name])
            if rc_bd == 0:
                cleanup["removed_branches"].append(branch_name)
            else:
                cleanup["cleanup_errors"].append(err_bd or out_bd)

    verdict = "pass" if selected is not None else "fail"
    output_doc = {
        "generated_at_utc": now_utc(),
        "experiment_id": experiment_id,
        "topic": args.topic,
        "verdict": verdict,
        "selected_option": selected.get("option") if selected else None,
        "rejected_options": [row.get("option") for row in option_reports if not selected or row.get("option") != selected.get("option")],
        "option_reports": option_reports,
        "decision_record": str(decision_record_path),
        "manifest": str(experiment_dir / "manifest.json"),
        "failures": failures,
        "cleanup": cleanup,
    }
    output_path = Path(args.output) if args.output else experiment_dir / "executor-report.json"
    save_json(output_path, output_doc)
    print(json.dumps(output_doc, ensure_ascii=True, indent=2))

    if verdict == "fail":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
