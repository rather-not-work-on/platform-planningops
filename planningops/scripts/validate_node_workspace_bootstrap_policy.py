#!/usr/bin/env python3

import argparse
import json
import re
import sys
from pathlib import Path


DEFAULT_POLICY = Path("planningops/config/node-workspace-bootstrap-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/node-workspace-bootstrap-policy-report.json")
REQUIRED_ROOT_FILES = ["package.json", "pnpm-workspace.yaml", "tsconfig.base.json"]
REQUIRED_SCRIPTS = ["typecheck"]
REQUIRED_DEV_DEPS = ["typescript"]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def starts_with_prefix(command: list[str], prefix: list[str]) -> bool:
    return command[: len(prefix)] == prefix


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate node workspace bootstrap policy")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    policy_path = Path(args.policy)
    doc = load_json(policy_path)
    errors = []

    if int(doc.get("policy_version", 0)) < 1:
        errors.append("policy_version must be >= 1")

    package_manager = doc.get("package_manager") or {}
    if package_manager.get("name") != "pnpm":
        errors.append("package_manager.name must be pnpm")

    version = str(package_manager.get("version", ""))
    if not re.match(r"^[0-9]+\.[0-9]+\.[0-9]+$", version):
        errors.append("package_manager.version must be pinned semver")

    invocation_prefix = package_manager.get("invocation_prefix") or []
    expected_prefix = ["npm", "exec", "--yes", f"pnpm@{version}", "--"] if version else []
    if invocation_prefix != expected_prefix:
        errors.append("package_manager.invocation_prefix must pin the same pnpm version")

    root_files = doc.get("root_files") or []
    for item in REQUIRED_ROOT_FILES:
        if item not in root_files:
            errors.append(f"missing required root file policy: {item}")

    scripts = doc.get("required_root_scripts") or []
    for item in REQUIRED_SCRIPTS:
        if item not in scripts:
            errors.append(f"missing required root script policy: {item}")

    dev_deps = doc.get("required_root_dev_dependencies") or []
    for item in REQUIRED_DEV_DEPS:
        if item not in dev_deps:
            errors.append(f"missing required root dev dependency policy: {item}")

    lockfile = doc.get("lockfile") or {}
    if lockfile.get("path") != "pnpm-lock.yaml":
        errors.append("lockfile.path must be pnpm-lock.yaml")
    if lockfile.get("committed") is not True:
        errors.append("lockfile.committed must be true")

    commands = doc.get("commands") or {}
    for key in ["local_install", "ci_install", "typecheck"]:
        command = commands.get(key) or []
        if not command:
            errors.append(f"commands.{key} is required")
            continue
        if not starts_with_prefix(command, invocation_prefix):
            errors.append(f"commands.{key} must start with package_manager.invocation_prefix")

    ci_install = commands.get("ci_install") or []
    if "--frozen-lockfile" not in ci_install:
        errors.append("commands.ci_install must include --frozen-lockfile")

    typecheck = commands.get("typecheck") or []
    if not typecheck or typecheck[-1] != "typecheck":
        errors.append("commands.typecheck must end with typecheck")

    report = {
        "policy_path": str(policy_path),
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"verdict={report['verdict']} error_count={report['error_count']}")
    if errors and args.strict:
        return 1
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
