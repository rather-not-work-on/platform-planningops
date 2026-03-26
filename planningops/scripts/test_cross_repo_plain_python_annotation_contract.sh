#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOLVER="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"

python3 - <<'PY' "$RESOLVER"
import json
import subprocess
import sys
from pathlib import Path

resolver = Path(sys.argv[1]).resolve()
resolved = json.loads(
    subprocess.check_output(
        ["python3", str(resolver), "--mode", "entrypoints"],
        text=True,
    )
)

required_files = [Path(entry["resolved_path"]) for entry in resolved["entrypoints"]]

missing = []
violations = []

for path in required_files:
    if not path.exists():
        missing.append(str(path))
        continue
    header = path.read_text(encoding="utf-8").splitlines()[:8]
    if "from __future__ import annotations" not in header:
        violations.append(str(path))

if missing:
    raise SystemExit("missing required plain-python contract files:\n" + "\n".join(missing))

if violations:
    raise SystemExit(
        "plain-python cross-repo entrypoints must include 'from __future__ import annotations':\n"
        + "\n".join(violations)
    )
PY

echo "cross-repo plain python annotation contract ok"
