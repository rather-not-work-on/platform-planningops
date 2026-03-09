#!/usr/bin/env python3

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", required=False, default="local")
    parser.add_argument("--launcher-mode", required=False, default="dry-run")
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report = {
        "verdict": "pass",
        "reason_code": "ok",
        "profile": args.profile,
        "scenario": "primary_success",
        "launcher_mode_requested": args.launcher_mode,
        "run_id": args.run_id,
    }
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
