#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
MONDAY_DIR="${WORKSPACE_DIR}/monday"
O11Y_DIR="${WORKSPACE_DIR}/platform-observability-gateway"
RESOLVER="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"
PLAIN_PYTHON_BIN="${PLAIN_PYTHON_BIN:-python3}"

if [[ ! -d "${MONDAY_DIR}" ]]; then
  echo "missing sibling monday repo at ${MONDAY_DIR}" >&2
  exit 1
fi

if [[ ! -d "${O11Y_DIR}" ]]; then
  echo "missing sibling observability repo at ${O11Y_DIR}" >&2
  exit 1
fi

RESOLVED_MANIFEST="$("${PLAIN_PYTHON_BIN}" "${RESOLVER}" --mode entrypoints)"

python3 - <<'PY' "$PLAIN_PYTHON_BIN" "$RESOLVED_MANIFEST"
import json
import subprocess
import sys

plain_python_bin = sys.argv[1]
manifest = json.loads(sys.argv[2])

for entry in manifest["entrypoints"]:
    resolved = entry["resolved_path"]
    if entry["mode"] == "help":
        subprocess.run(
            [plain_python_bin, resolved, "--help"],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        continue

    if entry["mode"] == "import":
        subprocess.run(
            [
                plain_python_bin,
                "-c",
                (
                    "import importlib.util, pathlib, sys; "
                    "module_path = pathlib.Path(sys.argv[1]).resolve(); "
                    "spec = importlib.util.spec_from_file_location('plain_python_compat', module_path); "
                    "module = importlib.util.module_from_spec(spec); "
                    "assert spec is not None and spec.loader is not None; "
                    "spec.loader.exec_module(module); "
                    f"assert hasattr(module, {entry['symbol']!r})"
                ),
                resolved,
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        continue

    raise AssertionError(f"unsupported manifest mode: {entry['mode']}")
PY

echo "cross-repo plain python compat ok"
