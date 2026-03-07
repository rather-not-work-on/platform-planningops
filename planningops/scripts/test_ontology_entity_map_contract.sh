#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

python3 planningops/scripts/validate_ontology_entity_map.py \
  --map planningops/config/ontology-entity-map.json \
  --contract planningops/contracts/control-tower-ontology-contract.md \
  --output "$tmp_dir/ontology-entity-map.valid.json" \
  --strict

python3 - "$tmp_dir/ontology-entity-map.valid.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["entity_count"] >= 6, report
assert report["relation_count"] >= 8, report
assert report["repository_role_count"] >= 6, report
PY

python3 - <<'PY'
import json
from pathlib import Path

doc = json.loads(Path("planningops/config/ontology-entity-map.json").read_text(encoding="utf-8"))
doc["relations"] = [r for r in doc["relations"] if r["name"] != "targets"]
Path("/tmp/ontology-entity-map.invalid.json").write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")
PY

set +e
python3 planningops/scripts/validate_ontology_entity_map.py \
  --map /tmp/ontology-entity-map.invalid.json \
  --contract planningops/contracts/control-tower-ontology-contract.md \
  --output "$tmp_dir/ontology-entity-map.invalid.report.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid ontology entity map"
  exit 1
fi

echo "ontology entity map contract test ok"
