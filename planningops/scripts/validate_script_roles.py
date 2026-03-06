#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys

from path_filters import is_metadata_file


DEFAULT_CONFIG = Path("planningops/config/script-role-map.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/script-role-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description="Validate script role separation (core vs oneoff)")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    cfg = load_json(Path(args.config))
    oneoff_dir = Path(cfg.get("oneoff_dir", "planningops/scripts/oneoff"))
    oneoff_entrypoints = cfg.get("oneoff_entrypoints", [])
    wrappers = cfg.get("root_wrappers", {})
    scripts_root = Path("planningops/scripts")

    violations = []
    infos = []
    metadata_ignored_count = 0

    if not oneoff_dir.is_dir():
        violations.append({"type": "MISSING_ONEOFF_DIR", "path": str(oneoff_dir)})

    for name in oneoff_entrypoints:
        path = oneoff_dir / name
        if not path.is_file():
            violations.append({"type": "MISSING_ONEOFF_ENTRYPOINT", "path": str(path)})

    for wrapper_name, target_rel in wrappers.items():
        wrapper_path = scripts_root / wrapper_name
        target_path = scripts_root / target_rel

        if not wrapper_path.is_file():
            violations.append({"type": "MISSING_WRAPPER", "path": str(wrapper_path)})
            continue
        if not target_path.is_file():
            violations.append({"type": "MISSING_WRAPPER_TARGET", "path": str(target_path)})
            continue

        text = wrapper_path.read_text(encoding="utf-8")
        target_name = Path(target_rel).name
        target_dir = str(Path(target_rel).parent)
        if target_name not in text or target_dir not in text:
            violations.append(
                {
                    "type": "INVALID_WRAPPER_TARGET",
                    "path": str(wrapper_path),
                    "expected_target": target_rel,
                }
            )

    # Guard against misplaced one-off files in scripts root.
    for p in scripts_root.glob("*.py"):
        if is_metadata_file(p):
            metadata_ignored_count += 1
            continue
        if p.name.startswith("test_"):
            continue
        if p.name in wrappers:
            continue
        if "bootstrap" in p.name.lower():
            violations.append(
                {
                    "type": "MISPLACED_ONEOFF_SCRIPT",
                    "path": str(p),
                    "message": "bootstrap script must live under scripts/oneoff",
                }
            )

    infos.append(
        {
            "type": "CHECK_SUMMARY",
            "oneoff_entrypoint_count": len(oneoff_entrypoints),
            "wrapper_count": len(wrappers),
            "metadata_ignored_count": metadata_ignored_count,
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
