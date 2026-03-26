#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
VALIDATION_REPORT="${TMP_DIR}/plain-python-compat-manifest-validation.json"

python3 "${ROOT_DIR}/planningops/scripts/validate_plain_python_compat_manifest.py" \
  --output "${VALIDATION_REPORT}" \
  --strict >/dev/null

python3 - <<'PY' "$ROOT_DIR" "$VALIDATION_REPORT"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
validation_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

script_docs = "\n".join(
    (
        root / "planningops/contracts/plain-python-compat-manifest-contract.md",
        root / "planningops/scripts/README.md",
        root / "planningops/scripts/federation/README.md",
    )[i].read_text(encoding="utf-8")
    for i in range(3)
)
schema_docs = "\n".join(
    (
        root / "planningops/contracts/plain-python-compat-manifest-contract.md",
        root / "planningops/schemas/README.md",
    )[i].read_text(encoding="utf-8")
    for i in range(2)
)


def iter_surface_files(directory: Path, pattern: str):
    for path in sorted(directory.glob(pattern)):
        if not path.is_file():
            continue
        if path.name.startswith("."):
            continue
        yield path


script_paths = list(iter_surface_files(root / "planningops/scripts", "*plain_python_compat_manifest*"))
schema_paths = list(
    iter_surface_files(root / "planningops/schemas", "plain-python-compat-manifest*.schema.json")
)
guardrail_script_paths = [
    Path(path).resolve().relative_to(root).as_posix()
    for path in validation_report.get("resolved_guardrail_script_paths", [])
]

empty_paths = [path for path in [*script_paths, *schema_paths] if path.stat().st_size == 0]
assert not empty_paths, "empty plain-python compat surfaces: " + ", ".join(
    str(path.relative_to(root)) for path in empty_paths
)

missing_scripts = [path.name for path in script_paths if path.name not in script_docs]
missing_schemas = [path.name for path in schema_paths if path.name not in schema_docs]
missing_guardrail_scripts = [path for path in guardrail_script_paths if path not in script_docs]

assert not missing_scripts, "undocumented plain-python compat scripts: " + ", ".join(missing_scripts)
assert not missing_schemas, "undocumented plain-python compat schemas: " + ", ".join(missing_schemas)
assert not missing_guardrail_scripts, "undocumented manifest-backed guardrail scripts: " + ", ".join(
    missing_guardrail_scripts
)
PY

echo "plain python compat manifest surface inventory ok"
