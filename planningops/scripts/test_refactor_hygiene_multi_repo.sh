#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import tempfile
from pathlib import Path


def write(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


with tempfile.TemporaryDirectory() as td:
    root = Path(td)
    repo_a = root / "repo-a"
    repo_b = root / "repo-b"

    write(
        repo_a / "scripts/main.py",
        "\n".join(
            [
                "import requests",
                "from util import helpers",
                "",
                "def run():",
                "    return helpers.ok()",
            ]
        ),
    )
    write(
        repo_a / "scripts/util/helpers.py",
        "\n".join(
            [
                "def ok():",
                "    return True",
            ]
        ),
    )
    write(
        repo_b / "scripts/worker.py",
        "\n".join(
            [
                "import boto3",
                "",
                "def work():",
                "    return 'ok'",
            ]
        ),
    )

    shared_policy = {
        "scan_roots": ["scripts"],
        "include_extensions": [".py"],
        "exclude_dirs": [".git", "__pycache__"],
        "internal_alias_prefixes": [],
        "legacy_markers": ["legacy", "old_"],
        "max_modules_per_cycle": 3,
        "max_files_per_module": 10,
        "checkpoint_every_tasks": 1,
        "internal_dependency_budget": {"max_out_degree": 2},
    }
    shared_policy_path = root / "shared-policy.json"
    write(shared_policy_path, json.dumps(shared_policy, ensure_ascii=True, indent=2))

    config = {
        "workspace_root": ".",
        "shared_policy_file": str(shared_policy_path),
        "output_root": str(root / "out"),
        "repositories": [
            {"name": "repo-a", "path": "repo-a", "policy_overrides": {"scan_roots": ["scripts"]}},
            {"name": "repo-b", "path": "repo-b", "policy_overrides": {"scan_roots": ["scripts"]}},
        ],
    }
    config_path = root / "multi.json"
    write(config_path, json.dumps(config, ensure_ascii=True, indent=2))

    cmd = [
        "python3",
        str(Path.cwd() / "planningops/scripts/refactor_hygiene_multi_repo.py"),
        "--config-file",
        str(config_path),
        "--workspace-root",
        str(root),
        "--run-id",
        "multi-test",
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True)

    aggregate = json.loads((root / "out/multi-test/aggregate.json").read_text(encoding="utf-8"))
    assert aggregate["repositories_total"] == 2, aggregate
    assert aggregate["repositories_succeeded"] == 2, aggregate
    assert aggregate["repositories_failed"] == 0, aggregate
    assert all(r["status"] == "ok" for r in aggregate["results"]), aggregate["results"]
    assert all(r["execution_order_contract_ok"] for r in aggregate["results"]), aggregate["results"]

    summary = (root / "out/multi-test/summary.md").read_text(encoding="utf-8")
    assert "repo-a: ok" in summary, summary
    assert "repo-b: ok" in summary, summary

print("refactor hygiene multi-repo test ok")
PY
