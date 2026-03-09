#!/usr/bin/env python3

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mission-file", required=True)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    mission = json.loads(Path(args.mission_file).read_text(encoding="utf-8"))
    report = {
        "verdict": "pass",
        "reason_code": "ok",
        "runtime_run_id": f"{args.run_id}:runtime",
        "mission_source": "mission_file",
        "requested_mission": mission,
        "mission": mission,
        "runtime_profile": {"profileName": args.profile},
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(output_path), "missionId": mission["missionId"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
