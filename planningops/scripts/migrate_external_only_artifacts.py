#!/usr/bin/env python3

import argparse
from fnmatch import fnmatch
import json
from datetime import datetime, timezone
from pathlib import Path
import subprocess
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from artifact_sink import ArtifactSink


DEFAULT_POLICY = Path("planningops/config/artifact-storage-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/artifact-migration-report.json")
METADATA_FILENAMES = {".DS_Store", "Thumbs.db", "desktop.ini"}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def is_metadata_path(path: Path):
    return path.name.startswith("._") or path.name in METADATA_FILENAMES


def git_tracked_files():
    cp = subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True)
    return [Path(line.strip()) for line in cp.stdout.splitlines() if line.strip()]


def collect_external_only_files(policy_doc: dict):
    tiers = policy_doc.get("tiers", {}) if isinstance(policy_doc.get("tiers"), dict) else {}
    patterns = tiers.get("external_only", []) if isinstance(tiers.get("external_only"), list) else []
    files = []
    for pattern in patterns:
        if not isinstance(pattern, str) or not pattern:
            continue
        files.extend([p for p in Path(".").glob(pattern) if p.is_file()])
    return sorted({p for p in files if not is_metadata_path(p)})


def collect_tracked_external_only_files(policy_doc: dict):
    tiers = policy_doc.get("tiers", {}) if isinstance(policy_doc.get("tiers"), dict) else {}
    patterns = tiers.get("external_only", []) if isinstance(tiers.get("external_only"), list) else []
    files = []
    for path in git_tracked_files():
        if is_metadata_path(path):
            continue
        logical_path = path.as_posix()
        if any(isinstance(pattern, str) and pattern and fnmatch(logical_path, pattern) for pattern in patterns):
            files.append(path)
    return sorted(set(files))


def main():
    parser = argparse.ArgumentParser(description="Migrate external-only artifact files to configured sink backend")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--backend", default=None, help="Override backend name (`local|s3|oci`)")
    parser.add_argument("--apply", action="store_true", help="Apply migration and remove local source files")
    parser.add_argument(
        "--scope",
        choices=["filesystem", "tracked"],
        default="filesystem",
        help="Migrate all matching filesystem files or only currently tracked Git files",
    )
    args = parser.parse_args()

    sink = ArtifactSink(policy_path=args.policy, backend_override=args.backend, local_cache_external=False)
    policy_doc = sink.policy
    candidates = (
        collect_tracked_external_only_files(policy_doc)
        if args.scope == "tracked"
        else collect_external_only_files(policy_doc)
    )
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
        "scope": args.scope,
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
