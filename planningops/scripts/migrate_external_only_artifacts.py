#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from artifact_sink import ArtifactSink


DEFAULT_POLICY = Path("planningops/config/artifact-storage-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/artifact-migration-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def collect_external_only_files(policy_doc: dict):
    tiers = policy_doc.get("tiers", {}) if isinstance(policy_doc.get("tiers"), dict) else {}
    patterns = tiers.get("external_only", []) if isinstance(tiers.get("external_only"), list) else []
    files = []
    for pattern in patterns:
        if not isinstance(pattern, str) or not pattern:
            continue
        files.extend([p for p in Path(".").glob(pattern) if p.is_file()])
    return sorted(set(files))


def main():
    parser = argparse.ArgumentParser(description="Migrate external-only artifact files to configured sink backend")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--backend", default=None, help="Override backend name (`local|s3|oci`)")
    parser.add_argument("--apply", action="store_true", help="Apply migration and remove local source files")
    args = parser.parse_args()

    sink = ArtifactSink(policy_path=args.policy, backend_override=args.backend, local_cache_external=False)
    policy_doc = sink.policy
    candidates = collect_external_only_files(policy_doc)
    rows = []
    migrated = 0

    for file_path in candidates:
        if args.apply:
            result = sink.externalize_existing_file(file_path, delete_local=True)
            migrated += 1 if result.get("externalized") else 0
            rows.append(
                {
                    "logical_path": file_path.as_posix(),
                    "externalized": bool(result.get("externalized")),
                    "pointer_path": result.get("pointer_path"),
                    "backend_target_path": result.get("backend_target_path"),
                    "reason": result.get("reason"),
                }
            )
        else:
            rows.append({"logical_path": file_path.as_posix(), "externalized": False, "reason": "dry-run"})

    report = {
        "generated_at_utc": now_utc(),
        "policy_path": str(Path(args.policy)),
        "backend": sink.backend,
        "mode": "apply" if args.apply else "dry-run",
        "candidate_count": len(candidates),
        "migrated_count": migrated,
        "rows": rows,
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(f"report written: {out}")
    print(f"mode={report['mode']} candidate_count={report['candidate_count']} migrated_count={report['migrated_count']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
