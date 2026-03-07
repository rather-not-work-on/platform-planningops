#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys


REPO_RULES = {
    "platform-provider-gateway": {
        "required_strings": [
            (".gitignore", "runtime-artifacts/"),
            ("scripts/litellm_gateway_smoke.py", 'default="runtime-artifacts/smoke"'),
            ("scripts/validate_provider_smoke_evidence.py", "runtime-artifacts/validation/provider-smoke-evidence-report.json"),
            ("scripts/validate_contract_pin.py", "runtime-artifacts/validation/contract-pin-report.json"),
            ("scripts/litellm_profile_drill.py", "runtime-artifacts/launcher/"),
        ],
        "forbidden_strings": [
            "artifacts/smoke",
            "artifacts/launcher",
            "artifacts/validation",
        ],
        "forbidden_paths_prefixes": ["artifacts/"],
    },
    "platform-observability-gateway": {
        "required_strings": [
            (".gitignore", "runtime-artifacts/"),
            ("scripts/langfuse_ingest_smoke.py", 'default="runtime-artifacts/ingest"'),
            ("scripts/validate_ingest_smoke_evidence.py", "runtime-artifacts/validation/ingest-smoke-evidence-report.json"),
            ("scripts/validate_contract_pin.py", "runtime-artifacts/validation/contract-pin-report.json"),
            ("scripts/langfuse_stack_launcher.sh", "runtime-artifacts/launcher"),
        ],
        "forbidden_strings": [
            "artifacts/ingest",
            "artifacts/launcher",
            "artifacts/validation",
        ],
        "forbidden_paths_prefixes": ["artifacts/"],
    },
    "monday": {
        "required_strings": [
            (".gitignore", "runtime-artifacts/"),
            ("scripts/validate_handoff_mapping.py", "runtime-artifacts/interface/handoff-smoke-report.json"),
            ("scripts/scheduler_queue.py", "runtime-artifacts/scheduler/run-report.json"),
            ("scripts/scheduler_queue.py", "runtime-artifacts/transition-log/scheduler.ndjson"),
            ("scripts/integrate_planningops_handoff.py", "runtime-artifacts/integration/"),
            ("scripts/validate_runtime_evidence.py", "runtime-artifacts/validation/runtime-evidence-report.json"),
            ("scripts/validate_contract_pin.py", "runtime-artifacts/validation/contract-pin-report.json"),
        ],
        "forbidden_strings": [
            "artifacts/interface",
            "artifacts/scheduler",
            "artifacts/integration",
            "artifacts/transition-log",
            "artifacts/validation",
        ],
        "forbidden_paths_prefixes": ["artifacts/"],
        "allowed_prefixes": ["planningops/artifacts/"],
    },
}

SCAN_SUFFIXES = (".md", ".py", ".sh", ".yml", ".yaml", ".json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[3]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidates = [
        (planningops_repo / raw_workspace_root).resolve(),
        planningops_repo,
        planningops_repo.parent,
    ]
    for candidate in candidates:
        if (candidate / "platform-provider-gateway").exists() and (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def iter_repo_files(repo_root: Path):
    for path in repo_root.rglob("*"):
        if not path.is_file():
            continue
        if any(part == ".git" for part in path.parts):
            continue
        if path.name.startswith("._") or path.name == ".DS_Store":
            continue
        if path.suffix not in SCAN_SUFFIXES:
            continue
        yield path


def line_has_allowed_prefix(line: str, allowed_prefixes: list[str]):
    return any(prefix in line for prefix in allowed_prefixes)


def validate_repo(repo_root: Path, rule: dict):
    required_errors = []
    forbidden_refs = []
    forbidden_paths = []

    for rel_path, snippet in rule["required_strings"]:
        path = repo_root / rel_path
        if not path.exists():
            required_errors.append({"path": rel_path, "reason": "file_missing", "snippet": snippet})
            continue
        text = path.read_text(encoding="utf-8")
        if snippet not in text:
            required_errors.append({"path": rel_path, "reason": "snippet_missing", "snippet": snippet})

    allowed_prefixes = rule.get("allowed_prefixes", [])
    for path in iter_repo_files(repo_root):
        rel_path = str(path.relative_to(repo_root))
        if any(rel_path.startswith(prefix) for prefix in rule.get("forbidden_paths_prefixes", [])):
            forbidden_paths.append(rel_path)
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for lineno, line in enumerate(text.splitlines(), start=1):
            for forbidden in rule["forbidden_strings"]:
                if forbidden not in line:
                    continue
                if f"runtime-{forbidden}" in line:
                    continue
                if line_has_allowed_prefix(line, allowed_prefixes):
                    continue
                forbidden_refs.append(
                    {
                        "path": rel_path,
                        "line": lineno,
                        "forbidden": forbidden,
                        "text": line.strip(),
                    }
                )

    verdict = "pass" if not required_errors and not forbidden_refs and not forbidden_paths else "fail"
    return {
        "repo": repo_root.name,
        "required_errors": required_errors,
        "forbidden_refs": forbidden_refs,
        "forbidden_paths": forbidden_paths,
        "verdict": verdict,
    }


def main():
    parser = argparse.ArgumentParser(description="Validate federated rollout of execution-repo external-only artifact defaults")
    parser.add_argument("--workspace-root", default="..")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/federated-artifact-policy-rollout-report.json",
    )
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)

    repos = []
    for repo_name, rule in REPO_RULES.items():
        repo_root = workspace_root / repo_name
        if not repo_root.exists():
            repos.append({"repo": repo_name, "verdict": "fail", "required_errors": [{"path": ".", "reason": "repo_missing"}], "forbidden_refs": [], "forbidden_paths": []})
            continue
        repos.append(validate_repo(repo_root, rule))

    verdict = "pass" if all(repo["verdict"] == "pass" for repo in repos) else "fail"
    report = {
        "generated_at_utc": now_utc(),
        "workspace_root": str(workspace_root),
        "contract_ref": "planningops/contracts/federated-artifact-storage-contract.md",
        "repo_results": repos,
        "verdict": verdict,
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"repo_count={len(repos)} verdict={verdict}")
    return 0 if verdict == "pass" or not args.strict else 1


if __name__ == "__main__":
    sys.exit(main())
