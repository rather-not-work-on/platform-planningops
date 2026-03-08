#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any


REQUIREMENTS_RELATIVE_PATHS = [
    "platform-contracts/requirements-dev.txt",
    "platform-provider-gateway/requirements-dev.txt",
    "platform-observability-gateway/requirements-dev.txt",
    "monday/requirements-dev.txt",
]
DEFAULT_BOOTSTRAP_ROOT = Path("planningops/runtime-artifacts/tooling/federated-conformance")
MANIFEST_VERSION = 1
MANIFEST_FILENAME = "managed-python-manifest.json"
ENV_MANAGED_PYTHON = "PLANNINGOPS_FEDERATED_PYTHON"
ENV_MANAGED_ROOT = "PLANNINGOPS_FEDERATED_PYTHON_ROOT"


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[3]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidates = [
        (planningops_repo / raw_workspace_root).resolve(),
        planningops_repo,
        planningops_repo.parent,
    ]
    for candidate in candidates:
        if (candidate / "platform-contracts").exists() and (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def resolve_bootstrap_root(planningops_repo: Path, raw_bootstrap_root: str | None) -> Path:
    path = Path(raw_bootstrap_root) if raw_bootstrap_root else DEFAULT_BOOTSTRAP_ROOT
    if path.is_absolute():
        return path
    return (planningops_repo / path).resolve()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def parse_requirement_lines(path: Path) -> list[str]:
    rows: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        rows.append(line)
    return rows


def requirement_import_name(requirement_line: str) -> str:
    token = re.split(r"[<>=!~;\[]", requirement_line, maxsplit=1)[0].strip()
    return token.replace("-", "_")


def managed_python_path(venv_dir: Path) -> Path:
    if os.name == "nt":
        return venv_dir / "Scripts" / "python.exe"
    return venv_dir / "bin" / "python"


def build_bootstrap_plan(planningops_repo: Path, workspace_root: Path, bootstrap_root: Path) -> dict[str, Any]:
    requirement_files = [workspace_root / rel for rel in REQUIREMENTS_RELATIVE_PATHS]
    requirement_entries: list[dict[str, Any]] = []
    missing_requirement_files: list[str] = []
    import_names: list[str] = []
    fingerprint_rows: list[dict[str, Any]] = []

    for path in requirement_files:
        relative_path = path.resolve().relative_to(workspace_root.resolve()).as_posix()
        if not path.exists():
            missing_requirement_files.append(relative_path)
            continue
        lines = parse_requirement_lines(path)
        requirement_entries.append({
            "path": relative_path,
            "absolute_path": str(path),
            "lines": lines,
        })
        fingerprint_rows.append({"path": relative_path, "lines": lines})
        for line in lines:
            import_name = requirement_import_name(line)
            if import_name and import_name not in import_names:
                import_names.append(import_name)

    fingerprint_payload = json.dumps(
        {
            "manifest_version": MANIFEST_VERSION,
            "python_version": f"{sys.version_info.major}.{sys.version_info.minor}",
            "requirements": fingerprint_rows,
        },
        ensure_ascii=True,
        sort_keys=True,
    )
    requirements_hash = hashlib.sha256(fingerprint_payload.encode("utf-8")).hexdigest()
    venv_dir = bootstrap_root / f"py{sys.version_info.major}{sys.version_info.minor}"
    managed_python = managed_python_path(venv_dir)

    return {
        "planningops_repo": str(planningops_repo),
        "workspace_root": str(workspace_root),
        "bootstrap_root": str(bootstrap_root),
        "venv_dir": str(venv_dir),
        "managed_python": str(managed_python),
        "manifest_path": str(bootstrap_root / MANIFEST_FILENAME),
        "python_version": f"{sys.version_info.major}.{sys.version_info.minor}",
        "requirements_hash": requirements_hash,
        "requirements": requirement_entries,
        "import_names": import_names,
        "missing_requirement_files": missing_requirement_files,
    }


def load_manifest(plan: dict[str, Any]) -> dict[str, Any] | None:
    path = Path(plan["manifest_path"])
    if not path.exists():
        return None
    try:
        return load_json(path)
    except Exception:  # noqa: BLE001
        return None


def manifest_is_current(plan: dict[str, Any], manifest: dict[str, Any] | None) -> bool:
    if not isinstance(manifest, dict):
        return False
    return (
        manifest.get("manifest_version") == MANIFEST_VERSION
        and manifest.get("requirements_hash") == plan["requirements_hash"]
        and manifest.get("python_version") == plan["python_version"]
        and manifest.get("managed_python") == plan["managed_python"]
        and Path(plan["managed_python"]).exists()
    )


def detect_missing_modules(import_names: list[str]) -> list[str]:
    missing: list[str] = []
    for name in import_names:
        try:
            importlib.import_module(name)
        except Exception:  # noqa: BLE001
            missing.append(name)
    return missing


def create_managed_venv(plan: dict[str, Any]) -> tuple[bool, list[dict[str, Any]]]:
    bootstrap_root = Path(plan["bootstrap_root"])
    venv_dir = Path(plan["venv_dir"])
    managed_python = Path(plan["managed_python"])
    manifest_path = Path(plan["manifest_path"])

    commands: list[dict[str, Any]] = []
    if venv_dir.exists():
        shutil.rmtree(venv_dir)
    bootstrap_root.mkdir(parents=True, exist_ok=True)

    create_cmd = [sys.executable, "-m", "venv", str(venv_dir)]
    commands.append({"command": create_cmd})
    subprocess.run(create_cmd, check=True)

    upgrade_pip_cmd = [str(managed_python), "-m", "pip", "install", "--upgrade", "pip"]
    commands.append({"command": upgrade_pip_cmd})
    subprocess.run(upgrade_pip_cmd, check=True)

    install_cmd = [str(managed_python), "-m", "pip", "install"]
    for entry in plan["requirements"]:
        install_cmd.extend(["-r", entry["absolute_path"]])
    commands.append({"command": install_cmd})
    subprocess.run(install_cmd, check=True)

    write_json(
        manifest_path,
        {
            "manifest_version": MANIFEST_VERSION,
            "requirements_hash": plan["requirements_hash"],
            "python_version": plan["python_version"],
            "managed_python": plan["managed_python"],
            "requirements": [entry["path"] for entry in plan["requirements"]],
        },
    )
    return True, commands


def ensure_bootstrap_environment(plan: dict[str, Any], mode: str) -> dict[str, Any]:
    manifest = load_manifest(plan)
    missing_modules_current = detect_missing_modules(plan["import_names"])
    current_python = str(Path(sys.executable).absolute())
    managed_python = str(Path(plan["managed_python"]).absolute())
    using_managed_python = current_python == managed_python
    manifest_current = manifest_is_current(plan, manifest)

    result: dict[str, Any] = {
        "mode": mode,
        "current_python": current_python,
        "managed_python": plan["managed_python"],
        "bootstrap_root": plan["bootstrap_root"],
        "requirements_hash": plan["requirements_hash"],
        "requirements_files": [entry["path"] for entry in plan["requirements"]],
        "missing_requirement_files": list(plan["missing_requirement_files"]),
        "import_names": list(plan["import_names"]),
        "missing_modules_current": missing_modules_current,
        "using_managed_python": using_managed_python,
        "manifest_current": manifest_current,
        "preferred_python": current_python,
        "venv_rebuilt": False,
        "reexec_required": False,
        "bootstrap_commands": [],
    }

    if mode == "off" or plan["missing_requirement_files"]:
        return result

    if mode == "auto" and not missing_modules_current:
        return result

    rebuilt = False
    commands: list[dict[str, Any]] = []
    if not manifest_current or not Path(plan["managed_python"]).exists():
        rebuilt, commands = create_managed_venv(plan)
        manifest = load_manifest(plan)
        manifest_current = manifest_is_current(plan, manifest)

    result["managed_python"] = str(Path(plan["managed_python"]).absolute())
    result["preferred_python"] = result["managed_python"]
    result["manifest_current"] = manifest_current
    result["venv_rebuilt"] = rebuilt
    result["bootstrap_commands"] = commands
    result["reexec_required"] = current_python != result["managed_python"]
    return result


def build_managed_env(result: dict[str, Any]) -> dict[str, str]:
    env = dict(os.environ)
    managed_python = Path(result["managed_python"]).absolute()
    env[ENV_MANAGED_PYTHON] = str(managed_python)
    env[ENV_MANAGED_ROOT] = str(Path(result["bootstrap_root"]).absolute())
    env["PYTHON_BIN"] = str(managed_python)
    env["PATH"] = f"{managed_python.parent}{os.pathsep}{env.get('PATH', '')}"
    return env


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage a deterministic local Python env for federated planningops checks")
    parser.add_argument("--workspace-root", default="..")
    parser.add_argument("--bootstrap-root", default=str(DEFAULT_BOOTSTRAP_ROOT))
    parser.add_argument("--mode", choices=["auto", "off", "require"], default="auto")
    parser.add_argument("--plan-only", action="store_true")
    parser.add_argument("--print-python-path", action="store_true")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    bootstrap_root = resolve_bootstrap_root(planningops_repo, args.bootstrap_root)
    plan = build_bootstrap_plan(planningops_repo, workspace_root, bootstrap_root)
    result = ensure_bootstrap_environment(plan, args.mode) if not args.plan_only else {
        "mode": args.mode,
        "plan_only": True,
        "current_python": str(Path(sys.executable).resolve()),
        "managed_python": plan["managed_python"],
        "bootstrap_root": plan["bootstrap_root"],
        "requirements_hash": plan["requirements_hash"],
        "requirements_files": [entry["path"] for entry in plan["requirements"]],
        "missing_requirement_files": list(plan["missing_requirement_files"]),
        "import_names": list(plan["import_names"]),
        "preferred_python": str(Path(sys.executable).resolve()),
    }
    result["workspace_root"] = plan["workspace_root"]

    if args.output:
        write_json(Path(args.output), result)

    if args.print_python_path:
        print(result["preferred_python"])
    elif not args.output:
        print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
