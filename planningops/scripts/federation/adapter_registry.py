#!/usr/bin/env python3

from __future__ import annotations

from typing import Dict, List


ADAPTER_REASON_CODES = {"contract", "permission", "context", "runtime", "feedback_failed"}


def classify_adapter_error(message: str) -> str:
    msg = (message or "").lower()
    if any(token in msg for token in ["permission", "auth", "token", "forbidden"]):
        return "permission"
    if any(token in msg for token in ["context", "depends_on", "dependency", "input"]):
        return "context"
    if any(token in msg for token in ["missing", "invalid", "schema", "contract", "required"]):
        return "contract"
    if "feedback" in msg:
        return "feedback_failed"
    return "runtime"


class RepoExecutionAdapter:
    def __init__(self, adapter_id: str, target_repo: str, component: str):
        self.adapter_id = adapter_id
        self.target_repo = target_repo
        self.component = component

    def before_loop(self, context: Dict) -> Dict:
        return {
            "status": "ok",
            "phase": "before_loop",
            "adapter": self.adapter_id,
            "target_repo": self.target_repo,
            "reason_code": "runtime",
            "message": f"{self.adapter_id} pre-hook baseline executed",
            "emitted_artifacts": [],
            "details": {
                "component": self.component,
                "issue_number": context.get("issue_number"),
                "workflow_state": context.get("workflow_state"),
            },
        }

    def after_loop(self, context: Dict, payload: Dict) -> Dict:
        return {
            "status": "ok",
            "phase": "after_loop",
            "adapter": self.adapter_id,
            "target_repo": self.target_repo,
            "reason_code": "runtime",
            "message": f"{self.adapter_id} post-hook baseline executed",
            "emitted_artifacts": [],
            "details": {
                "component": self.component,
                "issue_number": context.get("issue_number"),
                "last_verdict": payload.get("last_verdict"),
            },
        }


class GenericRepoAdapter(RepoExecutionAdapter):
    pass


class ContractsAdapter(RepoExecutionAdapter):
    pass


class ProviderGatewayAdapter(RepoExecutionAdapter):
    pass


class ObservabilityGatewayAdapter(RepoExecutionAdapter):
    pass


class RuntimeAdapter(RepoExecutionAdapter):
    pass


ADAPTERS: Dict[str, RepoExecutionAdapter] = {
    "rather-not-work-on/platform-contracts": ContractsAdapter(
        adapter_id="contracts-adapter",
        target_repo="rather-not-work-on/platform-contracts",
        component="contracts",
    ),
    "rather-not-work-on/platform-provider-gateway": ProviderGatewayAdapter(
        adapter_id="provider-gateway-adapter",
        target_repo="rather-not-work-on/platform-provider-gateway",
        component="provider-gateway",
    ),
    "rather-not-work-on/platform-observability-gateway": ObservabilityGatewayAdapter(
        adapter_id="observability-gateway-adapter",
        target_repo="rather-not-work-on/platform-observability-gateway",
        component="observability-gateway",
    ),
    "rather-not-work-on/monday": RuntimeAdapter(
        adapter_id="runtime-adapter",
        target_repo="rather-not-work-on/monday",
        component="runtime",
    ),
    "rather-not-work-on/platform-planningops": GenericRepoAdapter(
        adapter_id="planningops-adapter",
        target_repo="rather-not-work-on/platform-planningops",
        component="planningops",
    ),
}


def resolve_execution_adapter(target_repo: str) -> RepoExecutionAdapter:
    if target_repo in ADAPTERS:
        return ADAPTERS[target_repo]
    return GenericRepoAdapter(
        adapter_id="generic-adapter",
        target_repo=target_repo,
        component="unknown",
    )


def ensure_result_shape(result: Dict) -> Dict:
    shaped = {
        "status": result.get("status", "error"),
        "phase": result.get("phase", "before_loop"),
        "adapter": result.get("adapter", "unknown-adapter"),
        "target_repo": result.get("target_repo", ""),
        "reason_code": result.get("reason_code", "runtime"),
        "message": result.get("message", ""),
        "emitted_artifacts": result.get("emitted_artifacts", []),
        "details": result.get("details", {}),
    }
    if shaped["reason_code"] not in ADAPTER_REASON_CODES:
        shaped["reason_code"] = "runtime"
    if shaped["status"] not in {"ok", "error"}:
        shaped["status"] = "error"
    if not isinstance(shaped["emitted_artifacts"], list):
        shaped["emitted_artifacts"] = []
    return shaped


def invoke_adapter_hook(adapter: RepoExecutionAdapter, phase: str, context: Dict, payload: Dict | None = None) -> Dict:
    try:
        if phase == "before_loop":
            result = adapter.before_loop(context)
        elif phase == "after_loop":
            result = adapter.after_loop(context, payload or {})
        else:
            raise ValueError(f"unsupported adapter phase: {phase}")
    except Exception as exc:  # noqa: BLE001
        return {
            "status": "error",
            "phase": phase,
            "adapter": getattr(adapter, "adapter_id", "unknown-adapter"),
            "target_repo": getattr(adapter, "target_repo", context.get("target_repo", "")),
            "reason_code": classify_adapter_error(str(exc)),
            "message": f"adapter hook error: {exc}",
            "emitted_artifacts": [],
            "details": {"error_type": exc.__class__.__name__},
        }
    return ensure_result_shape(result)


def supported_repositories() -> List[str]:
    return sorted(ADAPTERS.keys())
