#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

output_path="$tmp_dir/wave14-oracle-rehearsal.json"

python3 "${ROOT_DIR}/scripts/federation/run_wave14_oracle_rehearsal.py" \
  --workspace-root "${ROOT_DIR}/.." \
  --run-id "wave14-oracle-rehearsal-contract" \
  --output "$output_path" \
  --bootstrap-mode auto

python3 - <<'PY' "$output_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["default_profile_preserved"] is True, report
assert report["oracle_rehearsal_only"] is True, report
assert report["profiles"]["local"] == "local", report
assert report["profiles"]["oracle"] == "oracle_cloud", report
assert report["portability_gap_count"] == 0, report
assert sorted(report["rehearsal_supported_components"]) == ["monday", "provider"], report
assert report["shared_profile_components"] == ["observability"], report
components = {row["component"]: row for row in report["component_comparison"]}
assert sorted(components) == ["monday", "observability", "provider"], report
assert components["monday"]["profile_sensitive"] is True, report
assert components["provider"]["profile_sensitive"] is True, report
assert components["observability"]["profile_sensitive"] is False, report
for key in ["local", "oracle"]:
    assert report["runs"][key]["report_exists"] is True, report
    assert report["runs"][key]["report"]["verdict"] == "pass", report
PY

echo "wave14 oracle rehearsal contract ok"
