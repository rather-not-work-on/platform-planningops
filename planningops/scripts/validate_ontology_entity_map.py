#!/usr/bin/env python3

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_MAP = Path("planningops/config/ontology-entity-map.json")
DEFAULT_CONTRACT = Path("planningops/contracts/control-tower-ontology-contract.md")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/ontology-entity-map-report.json")

REQUIRED_ENTITY_TYPES = {
    "Initiative",
    "PlanItem",
    "Contract",
    "RepositoryRole",
    "RuntimeArtifact",
    "MemoryRecord",
}

REQUIRED_RELATIONS = {
    ("contains", "Initiative", "PlanItem"),
    ("references", "PlanItem", "Contract"),
    ("targets", "PlanItem", "RepositoryRole"),
    ("owns", "RepositoryRole", "Contract"),
    ("emits", "RepositoryRole", "RuntimeArtifact"),
    ("evidences", "RuntimeArtifact", "PlanItem"),
    ("validates", "RuntimeArtifact", "Contract"),
    ("compacts", "MemoryRecord", "PlanItem|RuntimeArtifact"),
}

REQUIRED_REPOS = {
    "rather-not-work-on/platform-planningops",
    "rather-not-work-on/platform-contracts",
    "rather-not-work-on/platform-provider-gateway",
    "rather-not-work-on/platform-observability-gateway",
    "rather-not-work-on/monday",
}

COMPONENTS = {
    "planningops",
    "contracts",
    "provider-gateway",
    "observability-gateway",
    "runtime",
    "orchestrator",
}

PLAN_ITEM_REQUIRED_FIELDS = {
    "plan_item_id",
    "target_repo",
    "component",
    "workflow_state",
    "loop_profile",
    "execution_order",
    "depends_on",
}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate_repo_path_ref(ref: dict):
    repo = ref.get("repo")
    path = ref.get("path")
    if not isinstance(repo, str) or "/" not in repo:
        return "repo must use owner/repo format"
    if not isinstance(path, str) or not path or path.startswith("/"):
        return "path must be repo-root-relative"
    return None


def validate_entity(entity: dict):
    errors = []
    entity_type = entity.get("entity_type")
    if entity_type not in REQUIRED_ENTITY_TYPES:
        errors.append(f"invalid entity_type: {entity_type}")

    id_pattern = entity.get("id_pattern")
    if not isinstance(id_pattern, str) or not id_pattern:
        errors.append(f"{entity_type}: missing id_pattern")
    else:
        try:
            re.compile(id_pattern)
        except re.error as exc:  # noqa: PERF203
            errors.append(f"{entity_type}: invalid id_pattern ({exc})")

    required_fields = entity.get("required_fields")
    if not isinstance(required_fields, list) or not required_fields:
        errors.append(f"{entity_type}: required_fields must be a non-empty array")
    elif entity_type == "PlanItem" and not PLAN_ITEM_REQUIRED_FIELDS.issubset(set(required_fields)):
        errors.append(f"{entity_type}: missing required plan item fields")

    source = entity.get("source_of_truth")
    if not isinstance(source, dict):
        errors.append(f"{entity_type}: source_of_truth must be an object")
    else:
        issue = validate_repo_path_ref(source)
        if issue:
            errors.append(f"{entity_type}: source_of_truth {issue}")

    samples = entity.get("sample_refs")
    if not isinstance(samples, list) or not samples:
        errors.append(f"{entity_type}: sample_refs must be a non-empty array")
    else:
        for ref in samples:
            issue = validate_repo_path_ref(ref)
            if issue:
                errors.append(f"{entity_type}: sample_ref {issue}")

    return errors


def main():
    parser = argparse.ArgumentParser(description="Validate ontology entity map against control-tower ontology contract")
    parser.add_argument("--map", dest="map_path", default=str(DEFAULT_MAP))
    parser.add_argument("--contract", default=str(DEFAULT_CONTRACT))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    map_path = Path(args.map_path)
    contract_path = Path(args.contract)
    output_path = Path(args.output)

    doc = load_json(map_path)
    contract_text = contract_path.read_text(encoding="utf-8")

    errors = []

    if doc.get("initiative") != "unified-personal-agent-platform":
        errors.append("initiative must equal unified-personal-agent-platform")

    path_policy = doc.get("path_policy")
    if not isinstance(path_policy, dict):
        errors.append("path_policy must be an object")
    else:
        if path_policy.get("machine_ref_format") != "repo+path":
            errors.append("path_policy.machine_ref_format must equal repo+path")
        if path_policy.get("path_root") != "repo-root-relative":
            errors.append("path_policy.path_root must equal repo-root-relative")

    entities = doc.get("entities")
    if not isinstance(entities, list):
        errors.append("entities must be an array")
        entities = []
    entity_map = {entity.get("entity_type"): entity for entity in entities if isinstance(entity, dict)}
    missing_entities = sorted(REQUIRED_ENTITY_TYPES - set(entity_map))
    if missing_entities:
        errors.append("missing required entity types: " + ", ".join(missing_entities))

    for entity in entities:
        if isinstance(entity, dict):
            errors.extend(validate_entity(entity))

    relations = doc.get("relations")
    if not isinstance(relations, list):
        errors.append("relations must be an array")
        relations = []
    relation_set = {
        (row.get("name"), row.get("from"), row.get("to"))
        for row in relations
        if isinstance(row, dict)
    }
    missing_relations = sorted(REQUIRED_RELATIONS - relation_set)
    if missing_relations:
        errors.append(
            "missing required relations: "
            + ", ".join(f"{name}:{source}->{target}" for name, source, target in missing_relations)
        )

    role_rows = doc.get("repository_roles")
    if not isinstance(role_rows, list):
        errors.append("repository_roles must be an array")
        role_rows = []
    repos_present = set()
    for row in role_rows:
        if not isinstance(row, dict):
            errors.append("repository_roles entries must be objects")
            continue
        repo = row.get("repo")
        component = row.get("component")
        plane = row.get("plane")
        if not isinstance(repo, str) or "/" not in repo:
            errors.append("repository role repo must use owner/repo format")
        else:
            repos_present.add(repo)
        if component not in COMPONENTS:
            errors.append(f"invalid repository role component: {component}")
        if plane not in {"control-plane", "execution-plane"}:
            errors.append(f"invalid repository role plane: {plane}")
        responsibilities = row.get("responsibilities")
        if not isinstance(responsibilities, list) or not responsibilities:
            errors.append(f"repository role {repo}:{component} must declare responsibilities")

    missing_repos = sorted(REQUIRED_REPOS - repos_present)
    if missing_repos:
        errors.append("missing repository role coverage: " + ", ".join(missing_repos))

    for token in ["`Initiative`", "`PlanItem`", "`Contract`", "`RuntimeArtifact`", "`MemoryRecord`", "repo-root-relative"]:
        if token not in contract_text:
            errors.append(f"ontology contract missing expected token: {token}")

    report = {
        "generated_at_utc": now_utc(),
        "map_path": str(map_path),
        "contract_path": str(contract_path),
        "entity_count": len(entity_map),
        "relation_count": len(relations),
        "repository_role_count": len(role_rows),
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(f"report written: {output_path}")
    print(
        f"entity_count={report['entity_count']} relation_count={report['relation_count']} "
        f"repository_role_count={report['repository_role_count']} error_count={report['error_count']} verdict={report['verdict']}"
    )

    if args.strict and errors:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
