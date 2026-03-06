#!/usr/bin/env python3

import argparse
import json
import subprocess
from datetime import datetime, timezone
from fnmatch import fnmatch
from pathlib import Path
import sys


DEFAULT_POLICY = Path("planningops/config/repository-governance-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/branch-protection-audit-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def to_bool(value):
    if isinstance(value, bool):
        return value
    return False


def normalize_required_contexts(rule: dict):
    contexts = set()
    raw_contexts = rule.get("requiredStatusCheckContexts")
    if isinstance(raw_contexts, list):
        for row in raw_contexts:
            if isinstance(row, str) and row:
                contexts.add(row)

    raw_checks = rule.get("requiredStatusChecks")
    if isinstance(raw_checks, list):
        for row in raw_checks:
            if isinstance(row, dict):
                ctx = row.get("context")
                if isinstance(ctx, str) and ctx:
                    contexts.add(ctx)
            elif isinstance(row, str) and row:
                contexts.add(row)

    return sorted(contexts)


def select_rule(rules: list, branch_name: str, branch_pattern: str | None):
    if branch_pattern:
        exact = [r for r in rules if (r.get("pattern") or "") == branch_pattern]
        if exact:
            return exact[0]

    exact_branch = [r for r in rules if (r.get("pattern") or "") == branch_name]
    if exact_branch:
        return exact_branch[0]

    matches = [r for r in rules if fnmatch(branch_name, (r.get("pattern") or ""))]
    if not matches:
        return None

    # Prefer the most specific pattern.
    return sorted(matches, key=lambda r: len(r.get("pattern") or ""), reverse=True)[0]


def violation(repo: str, code: str, message: str, field: str | None = None):
    row = {
        "repo": repo,
        "code": code,
        "message": message,
    }
    if field:
        row["field"] = field
    return row


def evaluate_repo(repo_name: str, branch_name: str, policy_row: dict, rules: list):
    violations = []
    branch_pattern = policy_row.get("branch_pattern")
    selected_rule = select_rule(rules, branch_name, branch_pattern)

    if not selected_rule:
        expected = branch_pattern or branch_name
        violations.append(
            violation(
                repo_name,
                "missing_branch_protection_rule",
                f"no branch protection rule matched default branch '{branch_name}' (expected pattern '{expected}')",
                "pattern",
            )
        )
        return {
            "repo": repo_name,
            "default_branch": branch_name,
            "selected_pattern": None,
            "available_status_checks": [],
            "violations": violations,
        }

    available_checks = normalize_required_contexts(selected_rule)
    check_set = set(available_checks)

    require_reviews = policy_row.get("require_approving_reviews")
    min_reviews = int(policy_row.get("min_approving_review_count", 0) or 0)
    require_status_checks = policy_row.get("require_status_checks")
    require_strict = policy_row.get("require_strict_status_checks")
    require_resolution = policy_row.get("require_conversation_resolution")
    allow_force_pushes = policy_row.get("allow_force_pushes")
    allow_deletions = policy_row.get("allow_deletions")
    enforce_admins = policy_row.get("enforce_admins")
    require_linear_history = policy_row.get("require_linear_history")

    if require_reviews is not None and to_bool(selected_rule.get("requiresApprovingReviews")) != bool(require_reviews):
        violations.append(
            violation(
                repo_name,
                "approving_reviews_mismatch",
                f"requiresApprovingReviews expected={bool(require_reviews)} actual={to_bool(selected_rule.get('requiresApprovingReviews'))}",
                "requiresApprovingReviews",
            )
        )

    actual_review_count = int(selected_rule.get("requiredApprovingReviewCount") or 0)
    if bool(require_reviews) and actual_review_count < min_reviews:
        violations.append(
            violation(
                repo_name,
                "insufficient_approving_review_count",
                f"requiredApprovingReviewCount expected>={min_reviews} actual={actual_review_count}",
                "requiredApprovingReviewCount",
            )
        )

    if require_status_checks is not None and to_bool(selected_rule.get("requiresStatusChecks")) != bool(require_status_checks):
        violations.append(
            violation(
                repo_name,
                "status_checks_requirement_mismatch",
                f"requiresStatusChecks expected={bool(require_status_checks)} actual={to_bool(selected_rule.get('requiresStatusChecks'))}",
                "requiresStatusChecks",
            )
        )

    required_all = policy_row.get("required_status_checks_all") or []
    missing_all = [name for name in required_all if isinstance(name, str) and name and name not in check_set]
    if missing_all:
        violations.append(
            violation(
                repo_name,
                "required_status_checks_all_missing",
                "missing required status checks (all): " + ", ".join(sorted(missing_all)),
                "requiredStatusCheckContexts",
            )
        )

    required_any = [name for name in (policy_row.get("required_status_checks_any") or []) if isinstance(name, str) and name]
    if required_any and not check_set.intersection(required_any):
        violations.append(
            violation(
                repo_name,
                "required_status_checks_any_missing",
                "none of required status checks (any) present: " + ", ".join(sorted(required_any)),
                "requiredStatusCheckContexts",
            )
        )

    if require_strict is not None and to_bool(selected_rule.get("requiresStrictStatusChecks")) != bool(require_strict):
        violations.append(
            violation(
                repo_name,
                "strict_status_checks_mismatch",
                f"requiresStrictStatusChecks expected={bool(require_strict)} actual={to_bool(selected_rule.get('requiresStrictStatusChecks'))}",
                "requiresStrictStatusChecks",
            )
        )

    if require_resolution is not None and to_bool(selected_rule.get("requiresConversationResolution")) != bool(require_resolution):
        violations.append(
            violation(
                repo_name,
                "conversation_resolution_mismatch",
                f"requiresConversationResolution expected={bool(require_resolution)} actual={to_bool(selected_rule.get('requiresConversationResolution'))}",
                "requiresConversationResolution",
            )
        )

    if allow_force_pushes is not None and to_bool(selected_rule.get("allowsForcePushes")) != bool(allow_force_pushes):
        violations.append(
            violation(
                repo_name,
                "force_push_policy_mismatch",
                f"allowsForcePushes expected={bool(allow_force_pushes)} actual={to_bool(selected_rule.get('allowsForcePushes'))}",
                "allowsForcePushes",
            )
        )

    if allow_deletions is not None and to_bool(selected_rule.get("allowsDeletions")) != bool(allow_deletions):
        violations.append(
            violation(
                repo_name,
                "deletion_policy_mismatch",
                f"allowsDeletions expected={bool(allow_deletions)} actual={to_bool(selected_rule.get('allowsDeletions'))}",
                "allowsDeletions",
            )
        )

    if enforce_admins is not None and to_bool(selected_rule.get("isAdminEnforced")) != bool(enforce_admins):
        violations.append(
            violation(
                repo_name,
                "admin_enforcement_mismatch",
                f"isAdminEnforced expected={bool(enforce_admins)} actual={to_bool(selected_rule.get('isAdminEnforced'))}",
                "isAdminEnforced",
            )
        )

    if require_linear_history is not None and to_bool(selected_rule.get("requiresLinearHistory")) != bool(require_linear_history):
        violations.append(
            violation(
                repo_name,
                "linear_history_mismatch",
                f"requiresLinearHistory expected={bool(require_linear_history)} actual={to_bool(selected_rule.get('requiresLinearHistory'))}",
                "requiresLinearHistory",
            )
        )

    return {
        "repo": repo_name,
        "default_branch": branch_name,
        "selected_pattern": selected_rule.get("pattern"),
        "available_status_checks": available_checks,
        "violations": violations,
    }


def fetch_repo_snapshot(owner: str, repo_name: str):
    query = (
        "query($owner:String!, $name:String!) { "
        "repository(owner:$owner, name:$name) { "
        "name "
        "defaultBranchRef { name } "
        "branchProtectionRules(first: 100) { "
        "nodes { "
        "pattern "
        "requiresApprovingReviews "
        "requiredApprovingReviewCount "
        "requiresStatusChecks "
        "requiredStatusCheckContexts "
        "requiresStrictStatusChecks "
        "requiresConversationResolution "
        "allowsForcePushes "
        "allowsDeletions "
        "isAdminEnforced "
        "requiresLinearHistory "
        "requiredStatusChecks { context } "
        "} "
        "} "
        "} "
        "}"
    )

    rc, out, err = run(
        [
            "gh",
            "api",
            "graphql",
            "-f",
            f"query={query}",
            "-F",
            f"owner={owner}",
            "-F",
            f"name={repo_name}",
        ]
    )
    if rc != 0:
        raise RuntimeError(err or out or "graphql query failed")

    doc = json.loads(out)
    if doc.get("errors"):
        raise RuntimeError(json.dumps(doc["errors"], ensure_ascii=True))

    repo = ((doc.get("data") or {}).get("repository") or {})
    if not repo:
        raise RuntimeError("repository not found")

    default_branch = (((repo.get("defaultBranchRef") or {}).get("name")) or "main").strip()
    rules = ((repo.get("branchProtectionRules") or {}).get("nodes") or [])
    return {
        "name": repo.get("name") or repo_name,
        "default_branch": default_branch,
        "rules": rules,
    }


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
            "rules": row.get("rules") if isinstance(row.get("rules"), list) else [],
        }
    return parsed


def merged_policy_row(defaults: dict, repo_row: dict, default_branch: str):
    merged = dict(defaults)
    merged.update(repo_row)
    if "branch_pattern" not in merged:
        merged["branch_pattern"] = default_branch
    return merged


def main():
    parser = argparse.ArgumentParser(description="Audit branch protection baseline against repository governance policy")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--snapshot-file", default=None, help="Optional offline snapshot JSON path")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument(
        "--allow-fetch-failure",
        action="store_true",
        help="Treat fetch errors as inconclusive (soft-fail unless strict without this flag)",
    )
    args = parser.parse_args()

    policy_path = Path(args.policy)
    policy = load_json(policy_path)

    owner = policy.get("owner")
    default_branch = policy.get("default_branch") or "main"
    defaults = policy.get("defaults") if isinstance(policy.get("defaults"), dict) else {}
    repos = policy.get("repos") if isinstance(policy.get("repos"), list) else []

    if not isinstance(owner, str) or not owner:
        print("invalid policy: owner is required", file=sys.stderr)
        return 2

    snapshots = {}
    fetch_errors = []
    mode = "live"

    if args.snapshot_file:
        mode = "snapshot"
        snapshots = load_snapshot(Path(args.snapshot_file))
    else:
        for repo_row in repos:
            repo_name = repo_row.get("name") if isinstance(repo_row, dict) else None
            if not isinstance(repo_name, str) or not repo_name:
                continue
            try:
                snapshots[repo_name] = fetch_repo_snapshot(owner, repo_name)
            except Exception as exc:  # noqa: BLE001
                fetch_errors.append(
                    {
                        "repo": repo_name,
                        "message": str(exc),
                    }
                )

    results = []
    violations = []

    for repo_row in repos:
        if not isinstance(repo_row, dict):
            continue
        repo_name = repo_row.get("name")
        if not isinstance(repo_name, str) or not repo_name:
            continue

        snapshot = snapshots.get(repo_name)
        if not snapshot:
            fetch_errors.append({"repo": repo_name, "message": "snapshot not available"})
            continue

        branch_name = (snapshot.get("default_branch") or default_branch).strip() or default_branch
        merged = merged_policy_row(defaults, repo_row, branch_name)
        repo_result = evaluate_repo(repo_name, branch_name, merged, snapshot.get("rules") or [])
        results.append(repo_result)
        violations.extend(repo_result["violations"])

    if violations:
        verdict = "fail"
    elif fetch_errors:
        verdict = "inconclusive"
    else:
        verdict = "pass"

    report = {
        "generated_at_utc": now_utc(),
        "mode": mode,
        "policy_path": str(policy_path),
        "owner": owner,
        "repo_count": len([r for r in repos if isinstance(r, dict)]),
        "repo_evaluated_count": len(results),
        "fetch_error_count": len(fetch_errors),
        "fetch_errors": fetch_errors,
        "violation_count": len(violations),
        "violations": violations,
        "results": results,
        "verdict": verdict,
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out}")
    print(
        f"repo_evaluated_count={report['repo_evaluated_count']} "
        f"fetch_error_count={report['fetch_error_count']} "
        f"violation_count={report['violation_count']} "
        f"verdict={report['verdict']}"
    )

    if args.strict:
        if verdict == "pass":
            return 0
        if verdict == "inconclusive" and args.allow_fetch_failure:
            return 0
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
