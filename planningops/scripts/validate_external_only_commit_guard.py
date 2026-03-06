#!/usr/bin/env python3

import argparse
import json
import subprocess
from datetime import datetime, timezone
from fnmatch import fnmatch
from pathlib import Path
import sys


DEFAULT_POLICY = Path("planningops/config/artifact-storage-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/external-only-commit-guard-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def changed_files(base_ref: str | None, head_ref: str):
    if base_ref:
        rc, out, err = run(["git", "diff", "--name-only", "--diff-filter=ACMRT", f"{base_ref}...{head_ref}"])
        if rc != 0:
            hint = ""
            text = (err or out).lower()
            if "symmetric difference" in text or "unknown revision" in text:
                hint = " (hint: ensure full git history is available, e.g. actions/checkout fetch-depth: 0)"
            raise RuntimeError(f"git diff failed: {err or out}{hint}")
        return [line.strip() for line in out.splitlines() if line.strip()]

    rc, out, err = run(["git", "status", "--porcelain"])
    if rc != 0:
        raise RuntimeError(f"git status failed: {err or out}")
    files = []
    for line in out.splitlines():
        if len(line) < 4:
            continue
        files.append(line[3:].strip())
    return files


def main():
    parser = argparse.ArgumentParser(description="Fail when external-only artifact paths are changed in Git diff")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--base-ref", default=None)
    parser.add_argument("--head-ref", default="HEAD")
    parser.add_argument("--files-file", default=None, help="Optional newline-delimited file list override")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    policy = load_json(Path(args.policy))
    tiers = policy.get("tiers", {}) if isinstance(policy.get("tiers"), dict) else {}
    patterns = tiers.get("external_only", []) if isinstance(tiers.get("external_only"), list) else []

    if args.files_file:
        files = [line.strip() for line in Path(args.files_file).read_text(encoding="utf-8").splitlines() if line.strip()]
    else:
        files = changed_files(args.base_ref, args.head_ref)

    violations = []
    for file_path in files:
        for pattern in patterns:
            if isinstance(pattern, str) and pattern and fnmatch(file_path, pattern):
                violations.append(file_path)
                break

    report = {
        "generated_at_utc": now_utc(),
        "policy_path": str(Path(args.policy)),
        "base_ref": args.base_ref,
        "head_ref": args.head_ref,
        "changed_file_count": len(files),
        "violation_count": len(violations),
        "violations": sorted(set(violations)),
        "verdict": "pass" if len(violations) == 0 else "fail",
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(f"report written: {out}")
    print(f"changed_file_count={len(files)} violation_count={len(violations)} verdict={report['verdict']}")
    if args.strict and violations:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
