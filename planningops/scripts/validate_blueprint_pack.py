#!/usr/bin/env python3

import argparse
import json
import re
import sys
from pathlib import Path


REQUIRED_SECTIONS = [
    "Interface Contract Refs",
    "Target Package Topology",
    "Dependency Manifest",
    "File Plan",
    "Verification Plan",
    "Module README Deltas",
]


def has_section(text: str, title: str) -> bool:
    pattern = rf"(?m)^##\s+{re.escape(title)}\s*$"
    return re.search(pattern, text) is not None


def validate_doc(path: Path) -> dict:
    if not path.exists():
        return {
            "path": str(path),
            "exists": False,
            "missing_sections": REQUIRED_SECTIONS[:],
            "verdict": "fail",
        }

    text = path.read_text(encoding="utf-8")
    missing = [section for section in REQUIRED_SECTIONS if not has_section(text, section)]
    return {
        "path": str(path),
        "exists": True,
        "missing_sections": missing,
        "verdict": "pass" if not missing else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate ready-implementation blueprint pack documents")
    parser.add_argument("--doc", action="append", default=[], help="Blueprint pack markdown path")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/blueprint-pack-report.json",
        help="Output report path",
    )
    args = parser.parse_args()

    if not args.doc:
        raise SystemExit("--doc is required at least once")

    rows = [validate_doc(Path(raw)) for raw in args.doc]
    bad = [row for row in rows if row["verdict"] != "pass"]
    report = {
        "docs_checked": len(rows),
        "violation_count": len(bad),
        "required_sections": REQUIRED_SECTIONS,
        "rows": rows,
        "verdict": "pass" if not bad else "fail",
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
