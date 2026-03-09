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


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    base = (planningops_repo / raw_workspace_root).resolve()
    if base.exists():
        return base
    sibling_root = planningops_repo.parent
    if (sibling_root / "monday").exists() and (sibling_root / "platform-provider-gateway").exists():
        return sibling_root
    return base


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run(cmd: list[str]) -> tuple[int, str, str]:
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def issue_state(repo: str, number: int) -> dict:
    rc, out, err = run(["gh", "issue", "view", str(number), "--repo", repo, "--json", "number,state,title,url"])
    if rc != 0:
        return {
            "number": number,
            "state": "UNKNOWN",
            "title": "",
            "url": "",
            "verdict": "fail",
            "message": err or out or "gh issue view failed",
        }
    doc = json.loads(out)
    verdict = "pass" if doc.get("state") == "CLOSED" else "fail"
    return {
        "number": doc.get("number"),
        "state": doc.get("state"),
        "title": doc.get("title"),
        "url": doc.get("url"),
        "verdict": verdict,
        "message": "" if verdict == "pass" else "issue not closed",
    }


def substring_check(path: Path, markers: list[str]) -> dict:
    if not path.exists():
        return {
            "path": str(path),
            "exists": False,
            "missing_markers": markers,
            "verdict": "fail",
        }

    text = path.read_text(encoding="utf-8")
    missing = [marker for marker in markers if marker not in text]
    return {
        "path": str(path),
        "exists": True,
        "missing_markers": missing,
        "verdict": "pass" if not missing else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Review cross-repo interface adoption against a wave spec")
    parser.add_argument("--spec", required=True, help="Spec JSON describing required closed issues and file markers")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--output", required=True, help="Output report path")
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)

    spec_path = Path(args.spec)
    if not spec_path.is_absolute():
        spec_path = planningops_repo / spec_path
    spec = load_json(spec_path)

    issues_repo = str(spec.get("issues_repo") or "rather-not-work-on/platform-planningops")
    issue_checks = [issue_state(issues_repo, int(number)) for number in spec.get("required_closed_issues") or []]

    gap_checks = []
    for row in spec.get("gap_checks") or []:
        path = planningops_repo / str(row.get("path") or "")
        gap_checks.append(substring_check(path, list(row.get("must_contain") or [])))

    file_checks = []
    for row in spec.get("file_checks") or []:
        repo_dir = workspace_root / str(row.get("repo_dir") or "")
        path = repo_dir / str(row.get("path") or "")
        file_report = substring_check(path, list(row.get("must_contain") or []))
        file_report["repo"] = str(row.get("repo") or "")
        file_checks.append(file_report)

    failures = [row for row in issue_checks if row["verdict"] != "pass"]
    failures.extend(row for row in gap_checks if row["verdict"] != "pass")
    failures.extend(row for row in file_checks if row["verdict"] != "pass")

    report = {
        "generated_at_utc": now_utc(),
        "wave_id": str(spec.get("wave_id") or ""),
        "spec": str(spec_path),
        "workspace_root": str(workspace_root),
        "issue_checks": issue_checks,
        "gap_checks": gap_checks,
        "file_checks": file_checks,
        "check_count": len(issue_checks) + len(gap_checks) + len(file_checks),
        "failure_count": len(failures),
        "verdict": "pass" if not failures else "fail",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
