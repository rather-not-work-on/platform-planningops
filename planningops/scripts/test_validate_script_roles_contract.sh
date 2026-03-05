#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH="planningops/artifacts/validation/script-role-report.test.json"
python3 planningops/scripts/validate_script_roles.py --output "${REPORT_PATH}"

python3 - <<'PY'
import json
from pathlib import Path

report = json.loads(Path("planningops/artifacts/validation/script-role-report.test.json").read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["violation_count"] == 0, report
print("script role contract ok")
PY
