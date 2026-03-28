#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
CORE_GOALS_DIR = SCRIPT_DIR.parent / "core" / "goals"
if str(CORE_GOALS_DIR) not in sys.path:
    sys.path.insert(0, str(CORE_GOALS_DIR))

from resolve_active_goal import build_resolved_payload, load_json as load_goal_json, resolve_active_goal, validate_registry


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[4]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidates = [
        (planningops_repo / raw_workspace_root).resolve(),
        planningops_repo,
        planningops_repo.parent,
    ]
    for candidate in candidates:
        if (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def resolve_component_repo(workspace_root: Path, repo_dir: str) -> Path:
    path = Path(repo_dir)
    if path.is_absolute():
        return path
    return (workspace_root / path).resolve()


def resolve_repo_path(repo_root: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path
    return (repo_root / path).resolve()


def resolve_input_path(planningops_repo: Path, workspace_root: Path, monday_repo: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    candidates: list[Path] = []
    if path.is_absolute():
        candidates.append(path)
    else:
        candidates.extend(
            [
                (planningops_repo / path).resolve(),
                (workspace_root / path).resolve(),
                (monday_repo / path).resolve(),
                path.resolve(),
            ]
        )
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"input not found: {raw_path}")


def resolve_output_path(planningops_repo: Path, raw_path: str | None, default_path: Path) -> Path:
    if raw_path is None:
        return default_path
    path = Path(raw_path)
    if path.is_absolute():
        return path
    return (planningops_repo / path).resolve()


def normalize_repo_path(repo_root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(repo_root.resolve()))
    except ValueError:
        return str(path.resolve())


def normalize_workspace_path(workspace_root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(workspace_root.resolve()))
    except ValueError:
        return str(path.resolve())


def normalize_monday_runtime_ref(workspace_root: Path, monday_repo: Path, raw_ref: str | None) -> str:
    text = str(raw_ref or "").strip()
    if not text or text == "-":
        return "-"
    path_text, separator, suffix = text.partition("#")
    path = Path(path_text)
    if not path.is_absolute():
        path = (monday_repo / path).resolve()
    normalized = normalize_workspace_path(workspace_root, path)
    return f"{normalized}{separator}{suffix}" if separator else normalized


def normalize_cross_repo_path(planningops_repo: Path, monday_repo: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(planningops_repo.resolve()))
    except ValueError:
        try:
            return str(path.resolve().relative_to(monday_repo.resolve()))
        except ValueError:
            return str(path.resolve())


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def parse_json_doc(raw: str) -> dict | None:
    text = (raw or "").strip()
    if not text:
        return None
    try:
        doc = json.loads(text)
    except json.JSONDecodeError:
        return None
    return doc if isinstance(doc, dict) else None


def require_string(doc: dict, key: str) -> str:
    value = doc.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{key} must be a non-empty string")
    return value.strip()


def write_report(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def derive_single_queue_value(queue_doc: dict, key: str) -> str:
    values = {str(item.get(key) or "").strip() for item in queue_doc.get("queue_items", []) if str(item.get(key) or "").strip()}
    if len(values) != 1:
        raise ValueError(f"queue seed must provide exactly one {key}; got {sorted(values)}")
    return next(iter(values))


def resolve_goal_context(registry_path: Path, repo_root: Path, goal_key: str | None) -> tuple[dict | None, list[str]]:
    if not registry_path.exists():
        return None, [f"active goal registry not found: {registry_path}"]
    registry = load_goal_json(registry_path)
    errors = validate_registry(registry, repo_root=repo_root)
    if errors:
        return None, [f"active goal registry invalid: {error}" for error in errors]
    try:
        goal = build_resolved_payload(resolve_active_goal(registry, goal_key=goal_key))
    except RuntimeError as exc:
        return None, [str(exc)]
    return goal, []


def run_cmd(command: list[str], cwd: Path, env: dict[str, str]) -> tuple[int, str, str]:
    completed = subprocess.run(command, cwd=str(cwd), capture_output=True, text=True, env=env)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def build_stage_report(stage: str, command: list[str], cwd: Path, rc: int, out: str, err: str, artifact_path: Path) -> dict:
    return {
        "stage": stage,
        "command": command,
        "cwd": str(cwd),
        "exit_code": rc,
        "stdout_tail": out[-1000:],
        "stderr_tail": err[-1000:],
        "artifact_path": str(artifact_path),
        "artifact_exists": artifact_path.exists(),
        "verdict": "pass" if rc == 0 else "fail",
    }
