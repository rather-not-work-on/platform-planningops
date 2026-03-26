#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_manifest_path() -> Path:
    return repo_root() / "planningops/config/plain-python-compat-manifest.json"


def repo_roots(root_dir: Path) -> Dict[str, Path]:
    workspace_dir = root_dir.parent
    return {
        "planningops": root_dir,
        "monday": workspace_dir / "monday",
        "platform-observability-gateway": workspace_dir / "platform-observability-gateway",
    }


def load_manifest(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_entrypoints(manifest: Dict[str, Any], root_dir: Path) -> List[Dict[str, Any]]:
    roots = repo_roots(root_dir)
    resolved: List[Dict[str, Any]] = []
    ids = set()
    for entry in manifest.get("entrypoints", []):
        entry_id = entry["id"]
        if entry_id in ids:
            raise SystemExit(f"duplicate plain-python compat manifest id: {entry_id}")
        ids.add(entry_id)

        repo = entry["repo"]
        if repo not in roots:
            raise SystemExit(f"unsupported repo in plain-python compat manifest: {repo}")

        resolved_path = (roots[repo] / entry["path"]).resolve()
        if not resolved_path.is_file():
            raise SystemExit(f"plain-python compat entrypoint missing: {resolved_path}")

        resolved_entry = dict(entry)
        resolved_entry["resolved_path"] = str(resolved_path)
        resolved.append(resolved_entry)
    return resolved


def resolve_sequence(
    manifest: Dict[str, Any],
    resolved_entrypoints: List[Dict[str, Any]],
) -> Dict[str, Any]:
    entrypoints_by_id = {entry["id"]: entry for entry in resolved_entrypoints}
    sequence = manifest.get("runtime_stack_sequence")
    if not isinstance(sequence, dict):
        raise SystemExit("plain-python compat manifest missing runtime_stack_sequence")

    issue_id = sequence.get("issue_driven_entrypoint_id")
    local_id = sequence.get("local_entrypoint_id")
    if issue_id not in entrypoints_by_id:
        raise SystemExit(f"unknown issue_driven_entrypoint_id: {issue_id}")
    if local_id not in entrypoints_by_id:
        raise SystemExit(f"unknown local_entrypoint_id: {local_id}")
    if issue_id == local_id:
        raise SystemExit("runtime stack sequence entrypoints must differ")

    issue_entry = entrypoints_by_id[issue_id]
    local_entry = entrypoints_by_id[local_id]
    if issue_entry["repo"] != "planningops" or local_entry["repo"] != "planningops":
        raise SystemExit("runtime stack sequence must resolve to planningops entrypoints")

    return {
        "issue_driven_entrypoint_id": issue_id,
        "issue_driven_resolved_path": issue_entry["resolved_path"],
        "local_entrypoint_id": local_id,
        "local_resolved_path": local_entry["resolved_path"],
    }


def resolve_loop_guardrails_chain(manifest: Dict[str, Any]) -> List[Dict[str, Any]]:
    chain = manifest.get("loop_guardrails_chain")
    if not isinstance(chain, list):
        raise SystemExit("plain-python compat manifest missing loop_guardrails_chain")

    resolved_chain: List[Dict[str, Any]] = []
    ids = set()
    for step in chain:
        if not isinstance(step, dict):
            raise SystemExit("plain-python compat manifest loop_guardrails_chain entries must be objects")

        step_id = step.get("id")
        local_command = step.get("local_matrix_command")
        workflow_command = step.get("workflow_command")

        if not isinstance(step_id, str) or not step_id.strip():
            raise SystemExit("plain-python compat manifest loop_guardrails_chain ids must be non-empty strings")
        if step_id in ids:
            raise SystemExit(f"duplicate plain-python compat loop_guardrails_chain id: {step_id}")
        if not isinstance(local_command, str) or not local_command.strip():
            raise SystemExit(
                f"plain-python compat loop_guardrails_chain local_matrix_command missing for step: {step_id}"
            )
        if not isinstance(workflow_command, str) or not workflow_command.strip():
            raise SystemExit(
                f"plain-python compat loop_guardrails_chain workflow_command missing for step: {step_id}"
            )

        ids.add(step_id)
        resolved_chain.append(
            {
                "id": step_id,
                "local_matrix_command": local_command,
                "workflow_command": workflow_command,
            }
        )

    return resolved_chain


def build_report(manifest_path: Path, root_dir: Path) -> Dict[str, Any]:
    manifest = load_manifest(manifest_path)
    resolved_entrypoints = resolve_entrypoints(manifest, root_dir)
    return {
        "manifest_path": str(manifest_path.resolve()),
        "entrypoint_count": len(resolved_entrypoints),
        "entrypoints": resolved_entrypoints,
        "runtime_stack_sequence": resolve_sequence(manifest, resolved_entrypoints),
        "loop_guardrails_chain": resolve_loop_guardrails_chain(manifest),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve the canonical plain-python compatibility manifest into absolute entrypoints."
    )
    parser.add_argument(
        "--manifest-file",
        default=str(default_manifest_path()),
        help="Path to plain-python-compat-manifest.json",
    )
    parser.add_argument(
        "--mode",
        choices=("entrypoints", "sequence", "guardrails"),
        default="entrypoints",
        help="Output either the full resolved manifest, just the runtime stack sequence, or the canonical loop-guardrails chain.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root_dir = repo_root()
    report = build_report(Path(args.manifest_file), root_dir)
    payload: Dict[str, Any]
    if args.mode == "sequence":
        payload = report["runtime_stack_sequence"]
    elif args.mode == "guardrails":
        payload = report["loop_guardrails_chain"]
    else:
        payload = report
    print(json.dumps(payload, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
