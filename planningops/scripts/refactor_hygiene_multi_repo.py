#!/usr/bin/env python3

import argparse
import copy
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_CONFIG_PATH = Path("planningops/config/refactor-hygiene-multi-repo.json")


def utc_now_iso():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def save_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def path_for_manifest(path: Path, base: Path):
    try:
        return str(path.resolve().relative_to(base.resolve()))
    except ValueError:
        return str(path.resolve())


def slugify(value: str):
    return re.sub(r"[^a-zA-Z0-9._-]+", "-", value).strip("-").lower() or "repo"


def parse_args():
    parser = argparse.ArgumentParser(description="Run refactor hygiene loop across multiple repositories")
    parser.add_argument("--config-file", default=str(DEFAULT_CONFIG_PATH))
    parser.add_argument("--workspace-root", default=None)
    parser.add_argument("--run-id", default=None)
    parser.add_argument("--continue-on-error", action="store_true")
    return parser.parse_args()


def merge_policy(base_policy: dict, overrides: dict):
    merged = copy.deepcopy(base_policy)
    for key, value in overrides.items():
        merged[key] = value
    return merged


def build_summary(run_id: str, aggregate: dict):
    lines = [
        f"# Multi-Repo Refactor Hygiene Summary ({run_id})",
        "",
        f"- generated_at_utc: {aggregate['generated_at_utc']}",
        f"- repositories_total: {aggregate['repositories_total']}",
        f"- repositories_succeeded: {aggregate['repositories_succeeded']}",
        f"- repositories_failed: {aggregate['repositories_failed']}",
        "",
        "## Per Repository",
    ]

    for row in aggregate["results"]:
        if row["status"] == "ok":
            lines.append(
                f"- {row['name']}: ok, files={row['files_scanned']}, modules={row['modules_discovered']}, cycles={row['cycle_count']}, queue={','.join(row['execution_order']) or 'none'}"
            )
        else:
            lines.append(f"- {row['name']}: failed, reason={row['reason']}")

    lines.extend(["", "## Next Action"])
    lines.append("- Execute queue items in strict order: external dependency tasks first, then internal dependency tasks.")
    lines.append("- Apply checkpoint cleanup after every configured task group before continuing.")
    return "\n".join(lines) + "\n"


def run_single_repo(
    analyzer_script: Path,
    repo_name: str,
    repo_path: Path,
    policy_doc: dict,
    run_id: str,
    output_root: Path,
):
    slug = slugify(repo_name)
    repo_output_root = output_root / "repos" / slug
    policy_path = output_root / "policies" / f"{slug}.json"
    save_json(policy_path, policy_doc)

    repo_run_id = f"{run_id}-{slug}"
    cmd = [
        sys.executable,
        str(analyzer_script),
        "--repo-root",
        str(repo_path),
        "--policy-file",
        str(policy_path),
        "--run-id",
        repo_run_id,
        "--output-root",
        str(repo_output_root),
    ]
    cp = subprocess.run(cmd, capture_output=True, text=True)

    if cp.returncode != 0:
        return {
            "name": repo_name,
            "path": str(repo_path),
            "status": "failed",
            "reason": "analyzer_error",
            "stdout": cp.stdout[-2000:],
            "stderr": cp.stderr[-2000:],
            "command": cmd,
        }

    report_path = repo_output_root / repo_run_id / "report.json"
    if not report_path.exists():
        return {
            "name": repo_name,
            "path": str(repo_path),
            "status": "failed",
            "reason": "missing_report",
            "stdout": cp.stdout[-2000:],
            "stderr": cp.stderr[-2000:],
            "command": cmd,
        }

    report = load_json(report_path)
    order = report.get("queues", {}).get("execution_order", [])
    ext_count = len(report.get("queues", {}).get("external_first", []))
    order_contract_ok = all(item.startswith("E") for item in order[:ext_count]) and all(
        item.startswith("I") for item in order[ext_count:]
    )

    return {
        "name": repo_name,
        "path": str(repo_path),
        "status": "ok",
        "report": str(report_path),
        "files_scanned": report.get("scan", {}).get("files_scanned", 0),
        "modules_discovered": report.get("scan", {}).get("modules_discovered", 0),
        "cycle_count": report.get("topology", {}).get("cycle_count", 0),
        "external_task_count": ext_count,
        "internal_task_count": len(report.get("queues", {}).get("internal_next", [])),
        "execution_order": order,
        "execution_order_contract_ok": order_contract_ok,
    }


def main():
    args = parse_args()
    repo_root = Path.cwd().resolve()
    config_path = Path(args.config_file).resolve()
    config = load_json(config_path)

    workspace_root = Path(args.workspace_root).resolve() if args.workspace_root else (repo_root / config.get("workspace_root", ".")).resolve()
    shared_policy_path = (repo_root / config["shared_policy_file"]).resolve()
    output_root = (repo_root / config.get("output_root", "planningops/artifacts/refactor-hygiene/multi-repo")).resolve()

    run_id = args.run_id or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = output_root / run_id
    run_dir.mkdir(parents=True, exist_ok=True)

    shared_policy = load_json(shared_policy_path)
    repositories = sorted(config.get("repositories", []), key=lambda x: x.get("name", ""))
    analyzer_script = (Path(__file__).resolve().parent / "refactor_hygiene_loop.py").resolve()

    results = []
    failed = 0
    for repo in repositories:
        name = repo.get("name")
        path_rel = repo.get("path")
        if not name or not path_rel:
            results.append({"name": name or "unknown", "status": "failed", "reason": "invalid_config"})
            failed += 1
            if not args.continue_on_error:
                break
            continue

        repo_path = (workspace_root / path_rel).resolve()
        if not repo_path.exists():
            results.append(
                {
                    "name": name,
                    "path": str(repo_path),
                    "status": "failed",
                    "reason": "repo_not_found",
                }
            )
            failed += 1
            if not args.continue_on_error:
                break
            continue

        merged_policy = merge_policy(shared_policy, repo.get("policy_overrides", {}))
        result = run_single_repo(analyzer_script, name, repo_path, merged_policy, run_id, run_dir)
        results.append(result)
        if result["status"] != "ok":
            failed += 1
            if not args.continue_on_error:
                break

    aggregate = {
        "run_id": run_id,
        "generated_at_utc": utc_now_iso(),
        "workspace_root": str(workspace_root),
        "config_file": str(config_path),
        "shared_policy_file": str(shared_policy_path),
        "repositories_total": len(repositories),
        "repositories_succeeded": len([r for r in results if r.get("status") == "ok"]),
        "repositories_failed": len([r for r in results if r.get("status") != "ok"]),
        "results": results,
    }

    aggregate_path = run_dir / "aggregate.json"
    summary_path = run_dir / "summary.md"
    save_json(aggregate_path, aggregate)
    save_text(summary_path, build_summary(run_id, aggregate))
    save_json(
        output_root / "latest.json",
        {
            "run_id": run_id,
            "generated_at_utc": aggregate["generated_at_utc"],
            "aggregate": path_for_manifest(aggregate_path, repo_root),
            "summary": path_for_manifest(summary_path, repo_root),
        },
    )

    print(
        json.dumps(
            {
                "result": "ok" if failed == 0 else "failed",
                "run_id": run_id,
                "aggregate": str(aggregate_path),
                "failed_count": failed,
            },
            ensure_ascii=True,
        )
    )
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
