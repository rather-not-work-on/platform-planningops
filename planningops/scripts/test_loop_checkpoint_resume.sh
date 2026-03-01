#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/issue_loop_runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as td:
    checkpoint_dir = Path(td) / "checkpoints"
    mod.CHECKPOINT_DIR = checkpoint_dir

    issue_number = 501
    mod.save_checkpoint(issue_number, "pre_hook", {"adapter_pre_hook": {"status": "ok"}})
    cp1 = mod.load_checkpoint(issue_number)
    assert cp1["issue_number"] == issue_number, cp1
    assert cp1["stage"] == "pre_hook", cp1
    assert cp1["adapter_pre_hook"]["status"] == "ok", cp1

    mod.save_checkpoint(
        issue_number,
        "loop_executed",
        {
            "loop_dir": "planningops/artifacts/loops/2026-03-01/loop-test-issue-501",
            "date_part": "2026-03-01",
            "loop_id": "loop-test-issue-501",
        },
    )
    cp2 = mod.load_checkpoint(issue_number)
    assert cp2["stage"] == "loop_executed", cp2
    assert cp2["loop_id"] == "loop-test-issue-501", cp2
    assert cp2["loop_dir"].endswith("loop-test-issue-501"), cp2

    # Resume simulation: checkpoint exists and indicates loop artifacts are reusable.
    assert cp2["stage"] in {"loop_executed", "verified", "feedback_applied"}, cp2

    mod.clear_checkpoint(issue_number)
    assert not mod.checkpoint_path(issue_number).exists(), mod.checkpoint_path(issue_number)

print("loop checkpoint resume contract smoke ok")
PY
