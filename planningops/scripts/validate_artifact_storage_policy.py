#!/usr/bin/env python3

import argparse
from fnmatch import fnmatch
import json
from datetime import datetime, timezone
from pathlib import Path
import sys


DEFAULT_POLICY = Path("planningops/config/artifact-storage-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/artifact-storage-policy-report.json")
REQUIRED_TIERS = ["git_canonical", "git_optional", "external_only"]
REQUIRED_BACKENDS = ["local", "s3", "oci"]
REQUIRED_EVENT_FAMILY_KEYS = [
    "logical_root",
    "residency",
    "pointer_visibility",
    "default_backend",
    "migration_backends",
    "retention_days",
    "owner_scripts",
]


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def logical_root_covered_by_external_only(logical_root: str, tiers: dict):
    external_patterns = tiers.get("external_only") or []
    probe = logical_root.rstrip("/") + "/__probe__"
    return any(isinstance(pattern, str) and pattern and fnmatch(probe, pattern) for pattern in external_patterns)


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

    portability = doc.get("portability_profile")
    if not isinstance(portability, dict):
        errors.append("portability_profile must be object")
        portability = {}
    else:
        if portability.get("mode") != "local_first":
            errors.append("portability_profile.mode must be local_first")
        portability_default = portability.get("default_backend")
        if portability_default != default_backend:
            errors.append("portability_profile.default_backend must match default_external_backend")
        approved = portability.get("approved_migration_backends")
        if not isinstance(approved, list) or not approved:
            errors.append("portability_profile.approved_migration_backends must be non-empty list")
            approved = []
        elif not all(isinstance(v, str) and v for v in approved):
            errors.append("portability_profile.approved_migration_backends entries must be non-empty strings")
        if any(v == portability_default for v in approved):
            errors.append("portability_profile.approved_migration_backends must exclude default backend")
        if any(v not in backends for v in approved):
            errors.append("portability_profile.approved_migration_backends must reference existing backends")
        targets = portability.get("target_platforms")
        if not isinstance(targets, list) or not targets:
            errors.append("portability_profile.target_platforms must be non-empty list")
        if portability.get("canonical_pointer_strategy") != "git_pointer_only":
            errors.append("portability_profile.canonical_pointer_strategy must be git_pointer_only")

    execution_event_families = doc.get("execution_event_families")
    if not isinstance(execution_event_families, dict) or not execution_event_families:
        errors.append("execution_event_families must be non-empty object")
    else:
        max_external_days = retention.get("external_only_days") if isinstance(retention, dict) else None
        portability_default = portability.get("default_backend") if isinstance(portability, dict) else None
        approved_migrations = set(portability.get("approved_migration_backends") or []) if isinstance(portability, dict) else set()
        for family_name, cfg in execution_event_families.items():
            if not isinstance(cfg, dict):
                errors.append(f"execution_event_families.{family_name} must be object")
                continue
            for key in REQUIRED_EVENT_FAMILY_KEYS:
                if key not in cfg:
                    errors.append(f"execution_event_families.{family_name}.{key} is required")
            logical_root = cfg.get("logical_root")
            if not isinstance(logical_root, str) or not logical_root.startswith("planningops/artifacts/") or not logical_root.endswith("/"):
                errors.append(f"execution_event_families.{family_name}.logical_root must be planningops/artifacts/*/ path")
            elif isinstance(tiers, dict) and not logical_root_covered_by_external_only(logical_root, tiers):
                errors.append(f"execution_event_families.{family_name}.logical_root must be covered by tiers.external_only")

            if cfg.get("residency") != "external_only":
                errors.append(f"execution_event_families.{family_name}.residency must be external_only")
            if cfg.get("pointer_visibility") != "git_pointer_only":
                errors.append(f"execution_event_families.{family_name}.pointer_visibility must be git_pointer_only")
            if cfg.get("default_backend") != portability_default:
                errors.append(f"execution_event_families.{family_name}.default_backend must match portability profile default")

            migrations = cfg.get("migration_backends")
            if not isinstance(migrations, list) or not migrations:
                errors.append(f"execution_event_families.{family_name}.migration_backends must be non-empty list")
                migrations = []
            elif not all(isinstance(v, str) and v for v in migrations):
                errors.append(f"execution_event_families.{family_name}.migration_backends entries must be non-empty strings")
            if any(v not in approved_migrations for v in migrations):
                errors.append(f"execution_event_families.{family_name}.migration_backends must stay within portability profile")

            retention_days = cfg.get("retention_days")
            if not isinstance(retention_days, int) or retention_days <= 0:
                errors.append(f"execution_event_families.{family_name}.retention_days must be positive integer")
            elif isinstance(max_external_days, int) and retention_days > max_external_days:
                errors.append(f"execution_event_families.{family_name}.retention_days exceeds retention.external_only_days")

            owner_scripts = cfg.get("owner_scripts")
            if not isinstance(owner_scripts, list) or not owner_scripts:
                errors.append(f"execution_event_families.{family_name}.owner_scripts must be non-empty list")
                owner_scripts = []
            for script_path in owner_scripts:
                if not isinstance(script_path, str) or not script_path:
                    errors.append(f"execution_event_families.{family_name}.owner_scripts entries must be non-empty strings")
                    continue
                path = Path(script_path)
                if not path.exists():
                    errors.append(f"execution_event_families.{family_name}.owner_script missing: {script_path}")
                    continue
                source = path.read_text(encoding="utf-8")
                if isinstance(logical_root, str) and logical_root.rstrip("/") not in source:
                    errors.append(f"execution_event_families.{family_name}.owner_script missing logical_root reference: {script_path}")

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
