#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from artifact_sink import ArtifactSink


def main():
    parser = argparse.ArgumentParser(description="Rehydrate artifact payload from pointer manifest")
    parser.add_argument("--policy", default="planningops/config/artifact-storage-policy.json")
    parser.add_argument("--pointer", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    sink = ArtifactSink(policy_path=args.policy)
    result = sink.rehydrate_from_pointer(args.pointer, args.output)
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
