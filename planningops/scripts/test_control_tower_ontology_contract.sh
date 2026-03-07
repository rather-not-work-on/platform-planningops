#!/usr/bin/env bash
set -euo pipefail

contract="planningops/contracts/control-tower-ontology-contract.md"

if [[ ! -f "$contract" ]]; then
  echo "missing ontology contract: $contract"
  exit 1
fi

python3 - "$contract" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")

required_headings = [
    "# Control-Tower Ontology Contract",
    "## Purpose",
    "## Scope",
    "## Entity Types",
    "## Canonical Relations",
    "## Repository Role Classification",
    "## Identifier and Path Rules",
    "## Ontology Invariants",
    "## Verification",
]
required_entities = [
    "`Initiative`",
    "`PlanItem`",
    "`Contract`",
    "`RepositoryRole`",
    "`RuntimeArtifact`",
    "`MemoryRecord`",
]
required_relations = [
    "`contains`",
    "`references`",
    "`targets`",
    "`owns`",
    "`emits`",
    "`evidences`",
    "`validates`",
    "`compacts`",
]
required_terms = [
    "repo-root-relative",
    "target_repo",
    "component",
    "workflow_state",
    "rather-not-work-on/platform-planningops",
    "rather-not-work-on/platform-contracts",
    "rather-not-work-on/platform-provider-gateway",
    "rather-not-work-on/platform-observability-gateway",
    "rather-not-work-on/monday",
]

missing = []
for item in required_headings + required_entities + required_relations + required_terms:
    if item not in text:
        missing.append(item)

if missing:
    raise SystemExit("missing required ontology contract content: " + ", ".join(missing))

print("control tower ontology contract test ok")
PY
