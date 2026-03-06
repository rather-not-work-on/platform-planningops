#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys


DEFAULT_POLICY = Path("planningops/config/artifact-storage-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/artifact-storage-policy-report.json")
REQUIRED_TIERS = ["git_canonical", "git_optional", "external_only"]
REQUIRED_BACKENDS = ["local", "s3", "oci"]


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description="Validate artifact storage policy contract")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    policy_path = Path(args.policy)
    doc = load_json(policy_path)
    errors = []

    if int(doc.get("policy_version", 0)) < 1:
        errors.append("policy_version must be >= 1")

    default_backend = doc.get("default_external_backend")
    if not isinstance(default_backend, str) or not default_backend:
        errors.append("default_external_backend must be non-empty string")

    pointer_root = doc.get("pointer_manifest_root")
    if not isinstance(pointer_root, str) or not pointer_root.startswith("planningops/artifacts/pointers"):
        errors.append("pointer_manifest_root must start with planningops/artifacts/pointers")

    tiers = doc.get("tiers")
    if not isinstance(tiers, dict):
        errors.append("tiers must be object")
        tiers = {}
    else:
        for tier_name in REQUIRED_TIERS:
            values = tiers.get(tier_name)
            if not isinstance(values, list) or len(values) == 0:
                errors.append(f"tiers.{tier_name} must be non-empty list")
            elif not all(isinstance(v, str) and v for v in values):
                errors.append(f"tiers.{tier_name} entries must be non-empty strings")

    backends = doc.get("backends")
    if not isinstance(backends, dict):
        errors.append("backends must be object")
        backends = {}
    else:
        for backend_name in REQUIRED_BACKENDS:
            cfg = backends.get(backend_name)
            if not isinstance(cfg, dict):
                errors.append(f"backends.{backend_name} must be object")
                continue
            kind = cfg.get("kind")
            if not isinstance(kind, str) or not kind:
                errors.append(f"backends.{backend_name}.kind must be non-empty string")
            if backend_name == "local":
                if not isinstance(cfg.get("base_path"), str) or not cfg.get("base_path"):
                    errors.append("backends.local.base_path must be non-empty string")
            else:
                for key in ["bucket", "prefix", "mock_base_path"]:
                    if not isinstance(cfg.get(key), str) or not cfg.get(key):
                        errors.append(f"backends.{backend_name}.{key} must be non-empty string")

    if isinstance(default_backend, str) and default_backend not in backends:
        errors.append("default_external_backend must reference existing backends key")

    retention = doc.get("retention", {})
    if not isinstance(retention, dict):
        errors.append("retention must be object")
    else:
        for key in ["git_canonical_days", "git_optional_days", "external_only_days"]:
            value = retention.get(key)
            if not isinstance(value, int) or value <= 0:
                errors.append(f"retention.{key} must be positive integer")

    commit_guard = doc.get("commit_guard", {})
    if not isinstance(commit_guard, dict):
        errors.append("commit_guard must be object")
    elif not isinstance(commit_guard.get("forbidden_external_only_in_git"), bool):
        errors.append("commit_guard.forbidden_external_only_in_git must be boolean")

    report = {
        "generated_at_utc": now_utc(),
        "policy_path": str(policy_path),
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out}")
    print(f"error_count={len(errors)} verdict={report['verdict']}")
    if args.strict and errors:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
