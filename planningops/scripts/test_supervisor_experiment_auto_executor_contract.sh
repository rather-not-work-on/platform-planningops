#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import tempfile
from pathlib import Path


def run_cmd(args, cwd=None):
    cp = subprocess.run(args, check=False, capture_output=True, text=True, cwd=cwd)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


script = Path("planningops/scripts/supervisor_experiment_auto_executor.py").resolve()

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    repo = td_path / "repo"
    repo.mkdir(parents=True, exist_ok=True)

    assert run_cmd(["git", "init"], cwd=repo)[0] == 0
    assert run_cmd(["git", "config", "user.email", "pilot@example.com"], cwd=repo)[0] == 0
    assert run_cmd(["git", "config", "user.name", "Pilot Bot"], cwd=repo)[0] == 0
    (repo / "README.md").write_text("# temp repo\n", encoding="utf-8")
    assert run_cmd(["git", "add", "README.md"], cwd=repo)[0] == 0
    assert run_cmd(["git", "commit", "-m", "init"], cwd=repo)[0] == 0

    pass_pack = td_path / "pack-pass.json"
    pass_pack.write_text(
        json.dumps(
            {
                "pack_id": "test-pack-pass",
                "commands": [
                    {"id": "readme_exists", "command": ["bash", "-lc", "test -f README.md"]},
                ],
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )

    pass_output = td_path / "pass-output.json"
    rc_pass, out_pass, err_pass = run_cmd(
        [
            "python3",
            str(script),
            "--repo-root",
            str(repo),
            "--experiment-id",
            "contract-pass",
            "--topic",
            "contract-pass",
            "--validation-pack-file",
            str(pass_pack),
            "--artifacts-root",
            str(td_path / "artifacts"),
            "--worktree-root",
            str(td_path / "worktrees"),
            "--output",
            str(pass_output),
        ]
    )
    assert rc_pass == 0, (rc_pass, out_pass, err_pass)
    pass_doc = json.loads(pass_output.read_text(encoding="utf-8"))
    assert pass_doc["verdict"] == "pass", pass_doc
    assert pass_doc["selected_option"] == "option-a", pass_doc
    assert len(pass_doc["option_reports"]) == 2, pass_doc
    assert Path(pass_doc["decision_record"]).exists(), pass_doc
    assert pass_doc["cleanup"]["removed_worktrees"], pass_doc
    assert pass_doc["cleanup"]["removed_branches"], pass_doc

    fail_pack = td_path / "pack-fail.json"
    fail_pack.write_text(
        json.dumps(
            {
                "pack_id": "test-pack-fail",
                "commands": [
                    {"id": "force_fail", "command": ["bash", "-lc", "exit 1"]},
                ],
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    fail_output = td_path / "fail-output.json"
    rc_fail, out_fail, err_fail = run_cmd(
        [
            "python3",
            str(script),
            "--repo-root",
            str(repo),
            "--experiment-id",
            "contract-fail",
            "--topic",
            "contract-fail",
            "--validation-pack-file",
            str(fail_pack),
            "--artifacts-root",
            str(td_path / "artifacts"),
            "--worktree-root",
            str(td_path / "worktrees"),
            "--output",
            str(fail_output),
        ]
    )
    assert rc_fail == 1, (rc_fail, out_fail, err_fail)
    fail_doc = json.loads(fail_output.read_text(encoding="utf-8"))
    assert fail_doc["verdict"] == "fail", fail_doc
    assert fail_doc["selected_option"] is None, fail_doc

print("supervisor experiment auto executor contract tests ok")
PY
