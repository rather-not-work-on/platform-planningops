#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH="planningops/artifacts/validation/script-role-report.test.json"
python3 - <<'PY'
import json
from pathlib import Path
import subprocess

report_path = Path("planningops/artifacts/validation/script-role-report.test.json")
metadata_probe = Path("planningops/scripts/._bootstrap_two_track_backlog.py")
metadata_probe.write_text("# metadata probe\n", encoding="utf-8")
try:
    subprocess.run(
        ["python3", "planningops/scripts/validate_script_roles.py", "--output", str(report_path)],
        check=True,
    )
    report = json.loads(report_path.read_text(encoding="utf-8"))
finally:
    if metadata_probe.exists():
        metadata_probe.unlink()

assert report["verdict"] == "pass", report
assert report["violation_count"] == 0, report
for violation in report.get("violations", []):
    assert "._bootstrap_two_track_backlog.py" not in violation.get("path", ""), report
print("script role contract ok")
PY
