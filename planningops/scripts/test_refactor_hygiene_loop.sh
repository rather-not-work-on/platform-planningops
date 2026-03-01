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
    repo = Path(td)
    src = repo / "src"

    write(
        src / "app/main.py",
        "\n".join(
            [
                "import requests",
                "from core import utils",
                "",
                "def run():",
                "    return utils.answer()",
            ]
        ),
    )
    write(
        src / "core/utils.py",
        "\n".join(
            [
                "from app import main",
                "",
                "def answer():",
                "    return 42",
            ]
        ),
    )
    write(
        src / "legacy/old_worker.py",
        "\n".join(
            [
                "import boto3",
                "",
                "def work():",
                "    return 'ok'",
            ]
        ),
    )

    policy = {
        "scan_roots": ["src"],
        "include_extensions": [".py"],
        "exclude_dirs": ["__pycache__", ".git"],
        "internal_alias_prefixes": [],
        "legacy_markers": ["legacy", "old_"],
        "max_modules_per_cycle": 2,
        "max_files_per_module": 10,
        "checkpoint_every_tasks": 1,
        "internal_dependency_budget": {"max_out_degree": 0},
    }
    write(repo / "policy.json", json.dumps(policy, ensure_ascii=True, indent=2))

    cmd = [
        "python3",
        str(Path.cwd() / "planningops/scripts/refactor_hygiene_loop.py"),
        "--repo-root",
        str(repo),
        "--policy-file",
        str(repo / "policy.json"),
        "--run-id",
        "test-run",
        "--output-root",
        str(repo / "out"),
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True)

    report = json.loads((repo / "out/test-run/report.json").read_text(encoding="utf-8"))

    assert report["scan"]["modules_discovered"] == 3, report["scan"]
    assert report["topology"]["cycle_count"] >= 1, report["topology"]["cycles"]
    assert "requests" in report["topology"]["external_packages"], report["topology"]["external_packages"]
    assert "boto3" in report["topology"]["external_packages"], report["topology"]["external_packages"]

    execution = report["queues"]["execution_order"]
    assert execution, report["queues"]
    first_external_count = len(report["queues"]["external_first"])
    assert first_external_count > 0, report["queues"]
    assert all(task_id.startswith("E") for task_id in execution[:first_external_count]), execution

    summary = (repo / "out/test-run/summary.md").read_text(encoding="utf-8")
    assert "External-First Queue" in summary, summary
    assert "Internal-Next Queue" in summary, summary

print("refactor hygiene loop test ok")
PY
