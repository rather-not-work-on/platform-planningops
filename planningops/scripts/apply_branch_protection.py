#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_POLICY = Path("planningops/config/repository-governance-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/branch-protection-apply-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd, input_text=None):
    cp = subprocess.run(cmd, input=input_text, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def merged_policy_row(defaults: dict, repo_row: dict, default_branch: str):
    merged = dict(defaults)
    merged.update(repo_row)
    if "branch_pattern" not in merged:
        merged["branch_pattern"] = default_branch
    return merged


def load_snapshot(snapshot_path: Path):
    doc = load_json(snapshot_path)
    repos = doc.get("repositories")
    if not isinstance(repos, list):
        raise ValueError("snapshot file must include 'repositories' array")

    parsed = {}
    for row in repos:
        if not isinstance(row, dict):
            continue
        name = row.get("name")
        if not isinstance(name, str) or not name:
            continue
        parsed[name] = {
            "name": name,
            "default_branch": (row.get("default_branch") or "main"),
        }
    return parsed


def fetch_repo_snapshot(owner: str, repo_name: str):
    rc, out, err = run(
        [
            "gh",
            "api",
            f"repos/{owner}/{repo_name}",
            "-H",
            "Accept: application/vnd.github+json",
        ]
    )
    if rc != 0:
        raise RuntimeError(err or out or "repository fetch failed")

    doc = json.loads(out)
    default_branch = (doc.get("default_branch") or "main").strip() or "main"
    return {
        "name": doc.get("name") or repo_name,
        "default_branch": default_branch,
    }


def normalize_contexts(values):
    seen = []
    for value in values:
        if isinstance(value, str):
            ctx = value.strip()
            if ctx and ctx not in seen:
                seen.append(ctx)
    return seen


def required_contexts(policy_row: dict):
    required_all = normalize_contexts(policy_row.get("required_status_checks_all") or [])
    required_any = normalize_contexts(policy_row.get("required_status_checks_any") or [])

    if required_any and not required_all:
        raise ValueError("branch protection apply requires 'required_status_checks_all'; 'required_status_checks_any' is audit-only")

    if bool(policy_row.get("require_status_checks")) and not required_all:
        raise ValueError("required status checks enabled but no concrete 'required_status_checks_all' contexts are configured")

    return required_all


def build_payload(policy_row: dict):
    payload = {
        "enforce_admins": bool(policy_row.get("enforce_admins")),
        "restrictions": None,
        "allow_force_pushes": bool(policy_row.get("allow_force_pushes")),
        "allow_deletions": bool(policy_row.get("allow_deletions")),
        "required_conversation_resolution": bool(policy_row.get("require_conversation_resolution")),
    }

    if "require_linear_history" in policy_row:
        payload["required_linear_history"] = bool(policy_row.get("require_linear_history"))

    if bool(policy_row.get("require_status_checks")):
        payload["required_status_checks"] = {
            "strict": bool(policy_row.get("require_strict_status_checks")),
            "contexts": required_contexts(policy_row),
        }
    else:
        payload["required_status_checks"] = None

    if bool(policy_row.get("require_approving_reviews")):
        payload["required_pull_request_reviews"] = {
            "dismiss_stale_reviews": False,
            "require_code_owner_reviews": False,
            "required_approving_review_count": int(policy_row.get("min_approving_review_count", 1) or 1),
            "require_last_push_approval": False,
        }
    else:
        payload["required_pull_request_reviews"] = None

    return payload


def apply_payload(owner: str, repo_name: str, branch_name: str, payload: dict):
    rc, out, err = run(
        [
            "gh",
            "api",
            f"repos/{owner}/{repo_name}/branches/{branch_name}/protection",
            "--method",
            "PUT",
            "-H",
            "Accept: application/vnd.github+json",
            "--input",
            "-",
        ],
        input_text=json.dumps(payload, ensure_ascii=True),
    )
    if rc != 0:
        raise RuntimeError(err or out or "branch protection apply failed")

    doc = json.loads(out)
    required_checks = ((doc.get("required_status_checks") or {}).get("contexts") or [])
    required_reviews = (doc.get("required_pull_request_reviews") or {}).get("required_approving_review_count")

    return {
        "url": doc.get("url"),
        "required_status_checks": required_checks,
        "required_approving_review_count": required_reviews,
        "allow_force_pushes": bool((doc.get("allow_force_pushes") or {}).get("enabled")),
        "allow_deletions": bool((doc.get("allow_deletions") or {}).get("enabled")),
        "required_conversation_resolution": bool((doc.get("required_conversation_resolution") or {}).get("enabled")),
        "enforce_admins": bool((doc.get("enforce_admins") or {}).get("enabled")),
    }


def main():
    parser = argparse.ArgumentParser(description="Apply default-branch protection baseline from governance policy")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--snapshot-file", default=None, help="Optional repo metadata snapshot JSON path")
    parser.add_argument("--apply", action="store_true", help="Apply GitHub mutations (default: dry-run)")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--repos", default="", help="Comma-separated repo names to limit apply scope")
    args = parser.parse_args()

    policy_path = Path(args.policy)
    output_path = Path(args.output)
    policy = load_json(policy_path)

    owner = policy.get("owner")
    default_branch = (policy.get("default_branch") or "main").strip() or "main"
    defaults = policy.get("defaults") if isinstance(policy.get("defaults"), dict) else {}
    repos = [r for r in (policy.get("repos") or []) if isinstance(r, dict)]
    repo_filter = {x.strip() for x in args.repos.split(",") if x.strip()}

    if not isinstance(owner, str) or not owner:
        print("invalid policy: owner is required", file=sys.stderr)
        return 2

    snapshots = {}
    if args.snapshot_file:
        snapshots = load_snapshot(Path(args.snapshot_file))
    else:
        for repo_row in repos:
            repo_name = repo_row.get("name")
            if repo_filter and repo_name not in repo_filter:
                continue
            if not isinstance(repo_name, str) or not repo_name:
                continue
            snapshots[repo_name] = fetch_repo_snapshot(owner, repo_name)

    results = []
    errors = []

    for repo_row in repos:
        repo_name = repo_row.get("name")
        if repo_filter and repo_name not in repo_filter:
            continue
        if not isinstance(repo_name, str) or not repo_name:
            continue

        snapshot = snapshots.get(repo_name)
        if not snapshot:
            errors.append({"repo": repo_name, "message": "snapshot not available"})
            continue

        branch_name = (snapshot.get("default_branch") or default_branch).strip() or default_branch
        merged = merged_policy_row(defaults, repo_row, branch_name)

        try:
            payload = build_payload(merged)
            row = {
                "repo": repo_name,
                "branch": branch_name,
                "mode": "apply" if args.apply else "dry-run",
                "required_status_checks": ((payload.get("required_status_checks") or {}).get("contexts") or []),
                "payload": payload,
            }
            if args.apply:
                row["response"] = apply_payload(owner, repo_name, branch_name, payload)
            results.append(row)
        except Exception as exc:  # noqa: BLE001
            errors.append({"repo": repo_name, "message": str(exc)})

    verdict = "pass" if not errors else "fail"
    report = {
        "generated_at_utc": now_utc(),
        "mode": "apply" if args.apply else "dry-run",
        "policy_path": str(policy_path),
        "owner": owner,
        "repo_count": len(repos if not repo_filter else [r for r in repos if r.get("name") in repo_filter]),
        "repo_evaluated_count": len(results),
        "error_count": len(errors),
        "results": results,
        "errors": errors,
        "verdict": verdict,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(f"report written: {output_path}")
    print(
        f"repo_evaluated_count={report['repo_evaluated_count']} error_count={report['error_count']} verdict={report['verdict']}"
    )

    if args.strict and errors:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
