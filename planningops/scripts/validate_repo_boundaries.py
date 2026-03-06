#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import re
import sys


DEFAULT_CONFIG = Path("planningops/config/repository-boundary-map.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/repo-boundary-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description="Validate planningops control-plane script boundaries")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    cfg = load_json(Path(args.config))
    layout = cfg.get("script_layout", {})

    scripts_root = Path(layout.get("scripts_root", "planningops/scripts"))
    federation_dir = Path(layout.get("federation_dir", "planningops/scripts/federation"))
    federation_entrypoints = layout.get("federation_entrypoints", [])
    root_wrappers = layout.get("root_wrappers", [])
    pattern_tokens = layout.get("must_live_in_federation_patterns", [])

    violations = []
    infos = []

    if not scripts_root.is_dir():
        violations.append({"type": "MISSING_DIR", "path": str(scripts_root)})
    if not federation_dir.is_dir():
        violations.append({"type": "MISSING_DIR", "path": str(federation_dir)})

    for name in federation_entrypoints:
        entry = federation_dir / name
        if not entry.is_file():
            violations.append(
                {
                    "type": "MISSING_FEDERATION_ENTRYPOINT",
                    "path": str(entry),
                }
            )

    for name in root_wrappers:
        wrapper = scripts_root / name
        if not wrapper.is_file():
            violations.append(
                {
                    "type": "MISSING_ROOT_WRAPPER",
                    "path": str(wrapper),
                }
            )
            continue

        text = wrapper.read_text(encoding="utf-8")
        if "federation" not in text:
            violations.append(
                {
                    "type": "INVALID_WRAPPER_TARGET",
                    "path": str(wrapper),
                    "message": "wrapper must dispatch to scripts/federation",
                }
            )

    root_files = [p for p in scripts_root.glob("*") if p.is_file() and not p.name.startswith("._")]
    for f in root_files:
        if f.name in root_wrappers:
            continue
        for token in pattern_tokens:
            if re.search(token, f.name):
                violations.append(
                    {
                        "type": "MISPLACED_FEDERATION_FILE",
                        "path": str(f),
                        "token": token,
                        "message": "federation-oriented file must live in scripts/federation",
                    }
                )
                break

    infos.append(
        {
            "type": "CHECK_SUMMARY",
            "scripts_root_file_count": len(root_files),
            "federation_entrypoint_count": len(federation_entrypoints),
            "root_wrapper_count": len(root_wrappers),
        }
    )

    report = {
        "generated_at_utc": now_utc(),
        "config_path": str(Path(args.config)),
        "verdict": "pass" if not violations else "fail",
        "violation_count": len(violations),
        "violations": violations,
        "info_count": len(infos),
        "infos": infos,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"violation_count={report['violation_count']} verdict={report['verdict']}")
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
