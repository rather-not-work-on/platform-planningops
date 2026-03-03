#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


REQUIRED_ARTIFACTS = {
    "issue_52_monday_target_ux_freeze": "docs/workbench/unified-personal-agent-platform/brainstorms/monday-target-ux-scenarios.md",
    "issue_53_infra_profile_boundary_map": "docs/workbench/unified-personal-agent-platform/audits/infra-profile-boundary-map.md",
    "issue_54_langfuse_boundary_map": "docs/workbench/unified-personal-agent-platform/audits/langfuse-boundary-map.md",
    "issue_55_nanoclaw_fit_assessment": "docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md",
    "issue_56_track2_readiness_packet": "docs/workbench/unified-personal-agent-platform/plans/track2-implementation-readiness-packet.md",
    "issue_57_replan_policy_automation_report": "docs/workbench/unified-personal-agent-platform/audits/replan-policy-automation-report.md",
}

REQUIRED_FRONTMATTER_KEYS = [
    "title",
    "type",
    "date",
    "initiative",
    "lifecycle",
    "status",
    "summary",
]

DOC_REFERENCE_RULES = {
    "docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md": [
        "docs/workbench/unified-personal-agent-platform/brainstorms/monday-target-ux-scenarios.md",
        "docs/workbench/unified-personal-agent-platform/audits/infra-profile-boundary-map.md",
        "docs/workbench/unified-personal-agent-platform/audits/langfuse-boundary-map.md",
    ],
    "docs/workbench/unified-personal-agent-platform/plans/track2-implementation-readiness-packet.md": [
        "docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md",
        "planningops/contracts/implementation-readiness-gate-contract.md",
        "planningops/config/runtime-profiles.json",
    ],
    "docs/workbench/unified-personal-agent-platform/audits/replan-policy-automation-report.md": [
        "planningops/contracts/escalation-gate-contract.md",
        "planningops/scripts/issue_loop_runner.py",
        "planningops/scripts/test_escalation_gate.sh",
    ],
}


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "command": " ".join(cmd),
        "rc": cp.returncode,
        "pass": cp.returncode == 0,
        "stdout": cp.stdout.strip()[:8000],
        "stderr": cp.stderr.strip()[:4000],
    }


def parse_frontmatter(text):
    if not text.startswith("---\n"):
        return None
    lines = text.splitlines()
    if len(lines) < 3:
        return None
    result = {}
    idx = 1
    while idx < len(lines):
        line = lines[idx]
        if line.strip() == "---":
            return result
        if ":" in line:
            key, value = line.split(":", 1)
            result[key.strip()] = value.strip()
        idx += 1
    return None


def check_artifact(path_text):
    path = Path(path_text)
    row = {
        "path": path_text,
        "exists": path.exists(),
        "frontmatter": {
            "present": False,
            "missing_keys": list(REQUIRED_FRONTMATTER_KEYS),
        },
    }
    if not path.exists():
        return row

    body = path.read_text(encoding="utf-8")
    meta = parse_frontmatter(body)
    if meta is not None:
        missing = [k for k in REQUIRED_FRONTMATTER_KEYS if not meta.get(k)]
        row["frontmatter"] = {
            "present": True,
            "missing_keys": missing,
        }
    return row


def check_reference_rules():
    results = []
    for path_text, required_tokens in DOC_REFERENCE_RULES.items():
        path = Path(path_text)
        row = {
            "path": path_text,
            "exists": path.exists(),
            "required_tokens": required_tokens,
            "missing_tokens": [],
            "pass": False,
        }
        if path.exists():
            text = path.read_text(encoding="utf-8")
            row["missing_tokens"] = [token for token in required_tokens if token not in text]
            row["pass"] = len(row["missing_tokens"]) == 0
        results.append(row)
    return results


def main():
    parser = argparse.ArgumentParser(description="Validate Track2 contract-pack artifacts and checks")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/track2-contract-pack-report.json",
        help="output report json path",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="return non-zero on any failed check",
    )
    args = parser.parse_args()

    artifact_checks = {}
    for key, path_text in REQUIRED_ARTIFACTS.items():
        artifact_checks[key] = check_artifact(path_text)

    reference_checks = check_reference_rules()

    command_checks = {
        "uap_docs_profile_all": run(
            [
                "bash",
                "docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh",
                "check",
                "--profile",
                "all",
            ]
        ),
        "project_field_schema_validation": run(
            [
                "python3",
                "planningops/scripts/validate_project_field_schema.py",
                "--fail-on-mismatch",
            ]
        ),
        "module_readme_contract": run(
            ["bash", "planningops/scripts/test_module_readme_contract.sh"]
        ),
        "escalation_gate_contract": run(
            ["bash", "planningops/scripts/test_escalation_gate.sh"]
        ),
        "ready_implementation_blueprint_normalize": run(
            [
                "python3",
                "planningops/scripts/normalize_ready_implementation_blueprint_refs.py",
                "--fail-on-missing",
            ]
        ),
    }

    missing_artifacts = []
    bad_frontmatter = []
    for key, row in artifact_checks.items():
        if not row["exists"]:
            missing_artifacts.append({"artifact_key": key, "path": row["path"]})
            continue
        if row["frontmatter"]["missing_keys"]:
            bad_frontmatter.append(
                {
                    "artifact_key": key,
                    "path": row["path"],
                    "missing_keys": row["frontmatter"]["missing_keys"],
                }
            )

    failed_references = [row for row in reference_checks if not row["pass"]]
    failed_commands = [name for name, row in command_checks.items() if not row["pass"]]

    reasons = []
    if missing_artifacts:
        reasons.append("artifact.missing")
    if bad_frontmatter:
        reasons.append("artifact.frontmatter_invalid")
    if failed_references:
        reasons.append("artifact.reference_missing")
    if failed_commands:
        reasons.append("command.check_failed")

    verdict = "pass" if not reasons else "fail"
    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "checks": {
            "artifacts": artifact_checks,
            "reference_rules": reference_checks,
            "commands": command_checks,
        },
        "summary": {
            "missing_artifact_count": len(missing_artifacts),
            "frontmatter_violation_count": len(bad_frontmatter),
            "reference_violation_count": len(failed_references),
            "failed_command_count": len(failed_commands),
        },
        "missing_artifacts": missing_artifacts,
        "bad_frontmatter": bad_frontmatter,
        "failed_references": failed_references,
        "failed_commands": failed_commands,
        "verdict": verdict,
        "reasons": reasons,
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))

    if args.strict and verdict != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
