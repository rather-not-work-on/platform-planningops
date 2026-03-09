#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


CONTROL_REPO = "rather-not-work-on/platform-planningops"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[4]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidates = [
        (planningops_repo / raw_workspace_root).resolve(),
        planningops_repo,
        planningops_repo.parent,
    ]
    for candidate in candidates:
        if (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def run(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_issue_from_file(path: Path) -> dict:
    doc = load_json(path)
    if not isinstance(doc, dict):
        raise ValueError("issue fixture must be object")
    return doc


def load_issue_from_github(repo: str, issue_number: int, cwd: Path) -> dict:
    rc, out, err = run(
        [
            "gh",
            "issue",
            "view",
            str(issue_number),
            "--repo",
            repo,
            "--json",
            "number,title,body,url,state",
        ],
        cwd,
    )
    if rc != 0:
        raise ValueError(err or out or f"failed to load issue {repo}#{issue_number}")
    return json.loads(out)


def first_problem_statement_line(body: str) -> str:
    lines = body.splitlines()
    in_section = False
    collected: list[str] = []

    for raw_line in lines:
        line = raw_line.rstrip()
        heading = re.match(r"^\s{0,3}#{1,6}\s+(.*)$", line)
        if heading:
            title = heading.group(1).strip().lower()
            if title == "problem statement":
                in_section = True
                continue
            if in_section:
                break
        if not in_section:
            continue
        stripped = re.sub(r"^\s*[-*]\s*", "", line).strip()
        stripped = re.sub(r"^`|`$", "", stripped)
        if stripped:
            collected.append(stripped)

    return collected[0] if collected else ""


def slugify(value: str) -> str:
    normalized = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return normalized or "mission"


def build_mission(issue_doc: dict) -> dict:
    issue_number = int(issue_doc.get("number") or 0)
    title = str(issue_doc.get("title") or "").strip()
    body = str(issue_doc.get("body") or "")
    objective = first_problem_statement_line(body) or title or f"Resolve planningops issue {issue_number}."
    slug = slugify(title)[:48]
    mission_id = f"issue-{issue_number}-{slug}" if issue_number > 0 else f"issue-fixture-{slug}"
    return {
        "missionId": mission_id,
        "objective": objective,
    }


def resolve_component_repo(workspace_root: Path, repo_dir: str) -> Path:
    path = Path(repo_dir)
    if path.is_absolute():
        return path
    return (workspace_root / path).resolve()


def summarize_report(path: Path, keys: list[str]) -> dict | None:
    if not path.exists():
        return None
    doc = load_json(path)
    return {key: doc.get(key) for key in keys}


def main() -> int:
    parser = argparse.ArgumentParser(description="Run monday local runtime smoke from a planningops issue context")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--repo", default=CONTROL_REPO, help="Issue repository to load when using --issue-number")
    parser.add_argument("--issue-number", type=int, default=None, help="GitHub issue number to load")
    parser.add_argument("--issue-file", default=None, help="Offline issue fixture JSON path")
    parser.add_argument("--profile", default="local", help="Runtime profile forwarded to monday")
    parser.add_argument(
        "--run-id",
        default=f"issue-driven-mission-smoke-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
        help="Runner execution id",
    )
    parser.add_argument("--monday-repo-dir", default="monday", help="monday repo directory relative to workspace root")
    parser.add_argument("--monday-python", default="python3", help="Python interpreter used to invoke monday smoke")
    parser.add_argument("--monday-script", default="scripts/run_local_runtime_smoke.py", help="monday smoke script path")
    parser.add_argument(
        "--output",
        default=None,
        help="Output report path. Defaults to planningops/runtime-artifacts/local/issue-mission-smoke/<run_id>.json",
    )
    args = parser.parse_args()

    if bool(args.issue_number) == bool(args.issue_file):
        raise SystemExit("exactly one of --issue-number or --issue-file is required")

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    monday_repo = resolve_component_repo(workspace_root, args.monday_repo_dir)

    if args.issue_file:
        issue_path = Path(args.issue_file)
        if not issue_path.is_absolute():
            issue_path = (planningops_repo / issue_path).resolve()
        issue_doc = load_issue_from_file(issue_path)
        issue_source = {"kind": "fixture", "path": str(issue_path)}
    else:
        issue_doc = load_issue_from_github(args.repo, int(args.issue_number), planningops_repo)
        issue_source = {"kind": "github", "repo": args.repo, "number": int(args.issue_number)}

    mission = build_mission(issue_doc)
    run_dir = planningops_repo / "planningops" / "runtime-artifacts" / "local" / "issue-mission-smoke" / args.run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    mission_file = run_dir / "mission.json"
    mission_file.write_text(json.dumps(mission, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    monday_report = run_dir / "monday-report.json"
    monday_command = [
        args.monday_python,
        args.monday_script,
        "--mission-file",
        str(mission_file),
        "--profile",
        args.profile,
        "--run-id",
        f"{args.run_id}-monday",
        "--output",
        str(monday_report),
    ]
    rc, out, err = run(monday_command, monday_repo)
    monday_summary = summarize_report(
        monday_report,
        ["verdict", "reason_code", "runtime_run_id", "mission_source", "mission", "requested_mission"],
    )

    if rc == 0 and monday_summary and monday_summary.get("verdict") == "pass":
        verdict = "pass"
        reason_code = "issue_mission_smoke_ok"
    elif rc == 0 and monday_summary and monday_summary.get("verdict") == "skip":
        verdict = "skip"
        reason_code = "issue_mission_smoke_degraded"
    else:
        verdict = "fail"
        reason_code = "issue_mission_smoke_failed"

    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "issue_source": issue_source,
        "source_issue": {
            "number": issue_doc.get("number"),
            "title": issue_doc.get("title"),
            "url": issue_doc.get("url"),
            "state": issue_doc.get("state"),
        },
        "mission": mission,
        "mission_file": str(mission_file),
        "monday_repo": str(monday_repo),
        "monday_command": monday_command,
        "monday_report_path": str(monday_report),
        "monday_report_exists": monday_report.exists(),
        "monday_report_summary": monday_summary,
        "monday_exit_code": rc,
        "monday_stdout_tail": out[-1000:],
        "monday_stderr_tail": err[-1000:],
        "verdict": verdict,
        "reason_code": reason_code,
    }

    output_path = (
        Path(args.output)
        if args.output
        else planningops_repo / "planningops" / "runtime-artifacts" / "local" / "issue-mission-smoke" / f"{args.run_id}.json"
    )
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"verdict={verdict} reason_code={reason_code}")
    return 0 if verdict in {"pass", "skip"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
