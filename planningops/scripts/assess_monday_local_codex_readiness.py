#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shutil
import socket
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT = REPO_ROOT / "planningops/artifacts/validation/monday-local-codex-readiness-report.json"
LOCAL_PROFILE_NAMES = ("local", "local_ollama", "local_lmstudio")
DIRECT_LOCAL_LLM_PROFILE_NAMES = ("local_ollama", "local_lmstudio")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return REPO_ROOT


def resolve_workspace_root(repo_root: Path, raw_workspace_root: str) -> Path:
    candidates = [
        Path(raw_workspace_root).resolve(),
        (repo_root / raw_workspace_root).resolve(),
        repo_root.parent,
    ]
    for candidate in candidates:
        if (candidate / "monday").exists() and (candidate / "platform-provider-gateway").exists():
            return candidate
    return candidates[0]


def resolve_file(base: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path.resolve()
    return (base / path).resolve()


def normalize_origin(url: str | None) -> str | None:
    if not isinstance(url, str) or not url.strip():
        return None
    parsed = urlparse(url)
    if not parsed.scheme or not parsed.hostname:
        return None
    port = parsed.port
    if port is None:
        port = 443 if parsed.scheme == "https" else 80
    return f"{parsed.scheme}://{parsed.hostname}:{port}"


def probe_endpoint(url: str | None, mode: str) -> dict:
    if mode == "off":
        return {"status": "skipped", "detail": "probe_disabled"}
    if not isinstance(url, str) or not url.strip():
        return {"status": "missing", "detail": "base_url_missing"}

    parsed = urlparse(url)
    if not parsed.hostname:
        return {"status": "invalid", "detail": "hostname_missing"}

    port = parsed.port
    if port is None:
        port = 443 if parsed.scheme == "https" else 80

    try:
        with socket.create_connection((parsed.hostname, port), timeout=1.0):
            return {"status": "reachable", "detail": "tcp_connect_ok"}
    except OSError as exc:
        return {"status": "unreachable", "detail": str(exc)}


def resolve_codex_binary(raw_value: str) -> str | None:
    candidate = Path(raw_value)
    if candidate.is_absolute():
        return str(candidate.resolve()) if candidate.exists() else None
    discovered = shutil.which(raw_value)
    if discovered:
        return str(Path(discovered).resolve())
    return None


def build_profile_summary(name: str, payload: dict, probe_mode: str) -> dict:
    base_url = payload.get("deepagents_base_url")
    probe = probe_endpoint(base_url, probe_mode)
    return {
        "profile_name": name,
        "planner_engine": payload.get("planner_engine"),
        "model_backend": payload.get("deepagents_model_backend"),
        "model": payload.get("deepagents_model"),
        "base_url": base_url,
        "endpoint_probe_status": probe["status"],
        "endpoint_probe_detail": probe["detail"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Assess planningops-owned readiness for running monday locally with local LLM profiles and Codex."
    )
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories.")
    parser.add_argument(
        "--planningops-runtime-profile-file",
        default="planningops/config/runtime-profiles.json",
        help="Path to planningops runtime profile catalog.",
    )
    parser.add_argument(
        "--monday-planner-runtime-file",
        default="monday/config/planner-runtime.json",
        help="Path to monday planner runtime config.",
    )
    parser.add_argument(
        "--probe-endpoints",
        choices=["on", "off"],
        default="on",
        help="Whether to TCP probe configured local endpoints.",
    )
    parser.add_argument("--codex-bin", default="codex", help="Codex CLI name or absolute path.")
    parser.add_argument("--output", default=str(DEFAULT_REPORT), help="Output JSON report path.")
    args = parser.parse_args()

    repo_root = resolve_repo_root()
    workspace_root = resolve_workspace_root(repo_root, args.workspace_root)
    planningops_runtime_path = resolve_file(repo_root, args.planningops_runtime_profile_file)
    monday_runtime_path = resolve_file(workspace_root, args.monday_planner_runtime_file)
    output_path = resolve_file(repo_root, args.output)

    planningops_runtime = load_json(planningops_runtime_path)
    monday_runtime = load_json(monday_runtime_path)

    planningops_profiles = planningops_runtime.get("profiles") or {}
    monday_profiles = monday_runtime.get("profiles") or {}
    planningops_local = planningops_profiles.get("local") or {}
    monday_local = monday_profiles.get("local") or {}

    local_profiles = [
        build_profile_summary(name, monday_profiles[name], args.probe_endpoints)
        for name in LOCAL_PROFILE_NAMES
        if isinstance(monday_profiles.get(name), dict)
    ]
    direct_local_profiles = [row for row in local_profiles if row["profile_name"] in DIRECT_LOCAL_LLM_PROFILE_NAMES]

    codex_binary = resolve_codex_binary(args.codex_bin)
    planningops_local_origin = normalize_origin(planningops_local.get("litellm_base_url"))
    monday_local_origin = normalize_origin(monday_local.get("deepagents_base_url"))

    workspace_components = {
        "monday": {
            "path": str((workspace_root / "monday").resolve()),
            "present": (workspace_root / "monday").exists(),
        },
        "platform_provider_gateway": {
            "path": str((workspace_root / "platform-provider-gateway").resolve()),
            "present": (workspace_root / "platform-provider-gateway").exists(),
        },
        "platform_observability_gateway": {
            "path": str((workspace_root / "platform-observability-gateway").resolve()),
            "present": (workspace_root / "platform-observability-gateway").exists(),
        },
    }

    capabilities = {
        "gateway_first_configured": bool(monday_local) and planningops_local_origin == monday_local_origin,
        "direct_local_llm_configured": bool(direct_local_profiles),
        "codex_cli_available": codex_binary is not None,
        "workspace_components_present": all(row["present"] for row in workspace_components.values()),
        "gateway_endpoint_reachable": any(
            row["profile_name"] == "local" and row["endpoint_probe_status"] == "reachable" for row in local_profiles
        ),
        "direct_local_llm_endpoint_reachable": any(
            row["endpoint_probe_status"] == "reachable" for row in direct_local_profiles
        ),
    }
    capabilities["structural_ready"] = (
        capabilities["gateway_first_configured"]
        and capabilities["direct_local_llm_configured"]
        and capabilities["codex_cli_available"]
        and capabilities["workspace_components_present"]
    )

    blocking_details: list[dict[str, str]] = []
    bootstrap_details: list[dict[str, str]] = []

    for name, component in workspace_components.items():
        if not component["present"]:
            blocking_details.append({"reason_code": "workspace_component_missing", "component": name})

    if not planningops_local:
        blocking_details.append({"reason_code": "planningops_local_profile_missing", "component": "planningops"})
    if not monday_local:
        blocking_details.append({"reason_code": "monday_local_profile_missing", "component": "monday"})
    if planningops_local and monday_local and planningops_local_origin != monday_local_origin:
        blocking_details.append(
            {
                "reason_code": "local_profile_endpoint_mismatch",
                "component": "gateway_first",
            }
        )
    if not direct_local_profiles:
        blocking_details.append({"reason_code": "direct_local_llm_profiles_missing", "component": "monday"})
    if codex_binary is None:
        blocking_details.append({"reason_code": "codex_cli_missing", "component": "codex"})

    if args.probe_endpoints == "on" and not blocking_details:
        gateway_profile = next((row for row in local_profiles if row["profile_name"] == "local"), None)
        if gateway_profile and gateway_profile["endpoint_probe_status"] != "reachable":
            bootstrap_details.append(
                {
                    "reason_code": "gateway_endpoint_unreachable",
                    "component": "platform_provider_gateway",
                }
            )
        if direct_local_profiles and not capabilities["direct_local_llm_endpoint_reachable"]:
            bootstrap_details.append(
                {
                    "reason_code": "direct_local_llm_endpoint_unreachable",
                    "component": "monday",
                }
            )

    if blocking_details:
        assessment_status = "blocked"
    elif bootstrap_details:
        assessment_status = "bootstrap_required"
    else:
        assessment_status = "ready"

    recommended_commands = {
        "planningops_stack_smoke": "python3 planningops/scripts/federation/run_local_runtime_stack_smoke.py --workspace-root .. --profile local --run-id monday-local-stack-smoke",
        "monday_local_gateway_smoke": "python3 scripts/run_local_runtime_smoke.py --profile local --run-id monday-local-gateway-smoke",
        "monday_local_ollama_smoke": "python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-ollama-smoke",
        "monday_local_lmstudio_smoke": "python3 scripts/run_local_runtime_smoke.py --profile local_lmstudio --run-id monday-local-lmstudio-smoke",
        "monday_live_prerequisites": "npm run assess:deepagents-live-prerequisites",
    }

    recommended_next_steps: list[str] = []
    if any(item["reason_code"] == "codex_cli_missing" for item in blocking_details):
        recommended_next_steps.append("Expose the Codex CLI on PATH before attempting monday local operator flows.")
    if any(item["reason_code"] == "direct_local_llm_profiles_missing" for item in blocking_details):
        recommended_next_steps.append("Keep at least one direct local LLM profile (`local_ollama` or `local_lmstudio`) in monday/config/planner-runtime.json.")
    if any(item["reason_code"] == "local_profile_endpoint_mismatch" for item in blocking_details):
        recommended_next_steps.append("Align planningops local LiteLLM endpoint and monday local planner endpoint before smoke execution.")
    if any(item["reason_code"] == "gateway_endpoint_unreachable" for item in bootstrap_details):
        recommended_next_steps.append(
            "Start the provider gateway stack: bash ../platform-provider-gateway/scripts/litellm_stack_launcher.sh --mode start"
        )
    if any(item["reason_code"] == "direct_local_llm_endpoint_unreachable" for item in bootstrap_details):
        recommended_next_steps.append(
            "Start either Ollama on http://127.0.0.1:11434 or LM Studio on http://127.0.0.1:1234/v1, then rerun the readiness check."
        )
    if assessment_status == "ready":
        recommended_next_steps.append(
            "Run the planningops federated local smoke, then run a monday direct profile smoke for the target local LLM profile."
        )

    report = {
        "generated_at_utc": now_utc(),
        "workspace_root": str(workspace_root),
        "planningops_repo_root": str(repo_root),
        "planningops_runtime_profile_file": str(planningops_runtime_path),
        "monday_planner_runtime_file": str(monday_runtime_path),
        "probe_mode": args.probe_endpoints,
        "assessment_status": assessment_status,
        "verdict": "pass" if assessment_status == "ready" else "fail",
        "planningops_runtime": {
            "active_profile": planningops_runtime.get("active_profile"),
            "local_profile_present": bool(planningops_local),
            "local_litellm_base_url": planningops_local.get("litellm_base_url"),
            "local_langfuse_host": planningops_local.get("langfuse_host"),
        },
        "monday_runtime": {
            "active_profile": monday_runtime.get("active_profile"),
            "local_profile_present": bool(monday_local),
            "local_profiles": local_profiles,
        },
        "codex": {
            "configured_bin": args.codex_bin,
            "resolved_bin": codex_binary,
            "available": codex_binary is not None,
        },
        "workspace_components": workspace_components,
        "capabilities": capabilities,
        "blocking_details": blocking_details,
        "bootstrap_details": bootstrap_details,
        "recommended_commands": recommended_commands,
        "recommended_next_steps": recommended_next_steps,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"assessment_status={assessment_status} verdict={report['verdict']}")
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
