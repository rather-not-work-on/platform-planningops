#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH="planningops/artifacts/validation/repo-boundary-report.test.json"
python3 - <<'PY'
import json
from pathlib import Path
import subprocess

report_path = Path("planningops/artifacts/validation/repo-boundary-report.test.json")
metadata_probe = Path("planningops/scripts/._github_sync_adapter.py")
metadata_probe.write_text("# metadata probe\n", encoding="utf-8")
try:
    subprocess.run(
        ["python3", "planningops/scripts/validate_repo_boundaries.py", "--output", str(report_path)],
        check=True,
    )
    report = json.loads(report_path.read_text(encoding="utf-8"))
finally:
    if metadata_probe.exists():
        metadata_probe.unlink()

assert report["verdict"] == "pass", report
assert report["violation_count"] == 0, report
assert report["info_count"] >= 1, report
for violation in report.get("violations", []):
    assert "._github_sync_adapter.py" not in violation.get("path", ""), report
print("repo boundary contract ok")
PY
