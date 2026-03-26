#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 "$ROOT_DIR/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" --require-pass "$@"
