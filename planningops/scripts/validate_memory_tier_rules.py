#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys


DEFAULT_RULES = Path("planningops/config/memory-tier-rules.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/memory-tier-rules-report.json")
REQUIRED_TIERS = ["L0", "L1", "L2"]
REQUIRED_TRIGGERS = {
    "stale_l0_uncompacted",
    "topic_compaction_required",
    "closed_issue_memory_summary_missing",
}
REQUIRED_FRONTMATTER_KEYS = {"memory_tier", "expires_on", "compacted_into", "archive_ref"}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def is_non_empty_str_list(values):
    return isinstance(values, list) and all(isinstance(v, str) and v for v in values) and len(values) > 0


def main():
    parser = argparse.ArgumentParser(description="Validate memory tier contract rules")
    parser.add_argument("--rules", default=str(DEFAULT_RULES))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    rules_path = Path(args.rules)
    doc = load_json(rules_path)
    errors = []

    if int(doc.get("policy_version", 0)) < 1:
        errors.append("policy_version must be >= 1")

    tiers = doc.get("memory_tiers")
    if not isinstance(tiers, dict):
        errors.append("memory_tiers must be object")
        tiers = {}

    for tier_name in REQUIRED_TIERS:
        tier = tiers.get(tier_name)
        if not isinstance(tier, dict):
            errors.append(f"memory_tiers.{tier_name} must be object")
            continue
        roots = tier.get("default_roots")
        if not is_non_empty_str_list(roots):
            errors.append(f"memory_tiers.{tier_name}.default_roots must be non-empty string list")
        required_frontmatter = tier.get("required_frontmatter")
        if not is_non_empty_str_list(required_frontmatter):
            errors.append(f"memory_tiers.{tier_name}.required_frontmatter must be non-empty string list")
        next_tiers = tier.get("allowed_next_tiers")
        if not isinstance(next_tiers, list):
            errors.append(f"memory_tiers.{tier_name}.allowed_next_tiers must be list")

    l0 = tiers.get("L0", {})
    ttl = l0.get("ttl_days", {})
    if not isinstance(ttl, dict):
        errors.append("memory_tiers.L0.ttl_days must be object")
    else:
        min_days = ttl.get("min")
        max_days = ttl.get("max")
        default_days = ttl.get("default")
        if not all(isinstance(v, int) and v > 0 for v in [min_days, max_days, default_days]):
            errors.append("memory_tiers.L0.ttl_days min/max/default must be positive integers")
        elif not (min_days <= default_days <= max_days):
            errors.append("memory_tiers.L0.ttl_days must satisfy min <= default <= max")

    l1 = tiers.get("L1", {})
    if not isinstance(l1.get("review_cycle_days"), int) or l1.get("review_cycle_days", 0) <= 0:
        errors.append("memory_tiers.L1.review_cycle_days must be positive integer")

    l2 = tiers.get("L2", {})
    if not isinstance(l2.get("retention_days"), int) or l2.get("retention_days", 0) <= 0:
        errors.append("memory_tiers.L2.retention_days must be positive integer")

    frontmatter = doc.get("frontmatter_keys")
    if not isinstance(frontmatter, dict):
        errors.append("frontmatter_keys must be object")
        frontmatter = {}
    missing_frontmatter = sorted(REQUIRED_FRONTMATTER_KEYS - set(frontmatter))
    if missing_frontmatter:
        errors.append("missing frontmatter key rules: " + ", ".join(missing_frontmatter))

    memory_tier_cfg = frontmatter.get("memory_tier", {})
    allowed_values = memory_tier_cfg.get("allowed_values")
    if allowed_values != REQUIRED_TIERS:
        errors.append("frontmatter_keys.memory_tier.allowed_values must equal [L0, L1, L2]")

    triggers = doc.get("compaction_triggers")
    if not isinstance(triggers, list):
        errors.append("compaction_triggers must be array")
        triggers = []
    trigger_codes = {row.get("code") for row in triggers if isinstance(row, dict)}
    missing_triggers = sorted(REQUIRED_TRIGGERS - trigger_codes)
    if missing_triggers:
        errors.append("missing compaction trigger(s): " + ", ".join(missing_triggers))

    promotion_rules = doc.get("promotion_rules")
    if not isinstance(promotion_rules, dict):
        errors.append("promotion_rules must be object")
    else:
        for key in ["L0_to_L1_requires", "L0_to_L2_requires", "L1_to_L2_requires"]:
            if not is_non_empty_str_list(promotion_rules.get(key)):
                errors.append(f"promotion_rules.{key} must be non-empty string list")

    rehydrate_rules = doc.get("rehydrate_rules")
    if not isinstance(rehydrate_rules, dict):
        errors.append("rehydrate_rules must be object")
    else:
        if not is_non_empty_str_list(rehydrate_rules.get("required_inputs")):
            errors.append("rehydrate_rules.required_inputs must be non-empty string list")
        if rehydrate_rules.get("path_root") != "repo-root-relative":
            errors.append("rehydrate_rules.path_root must equal repo-root-relative")

    storage_interop = doc.get("storage_interop")
    if not isinstance(storage_interop, dict):
        errors.append("storage_interop must be object")
    else:
        if storage_interop.get("artifact_storage_contract") != "planningops/contracts/artifact-retention-tier-contract.md":
            errors.append("storage_interop.artifact_storage_contract must point to artifact-retention-tier-contract.md")
        if storage_interop.get("memory_tier_overrides_storage_tier") is not False:
            errors.append("storage_interop.memory_tier_overrides_storage_tier must be false")

    report = {
        "generated_at_utc": now_utc(),
        "rules_path": str(rules_path),
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(f"report written: {output_path}")
    print(f"error_count={len(errors)} verdict={report['verdict']}")

    if args.strict and errors:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
