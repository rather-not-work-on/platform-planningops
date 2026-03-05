#!/usr/bin/env python3

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


ACTIVE_BLOCKER_STATUSES = {"in_progress", "review_gate", "blocked", "replan_required"}


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")


def append_error(errors, message):
    if message not in errors:
        errors.append(message)


def _resolve_ref(root_schema, ref):
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ValueError(f"unsupported schema ref: {ref}")
    cursor = root_schema
    for token in ref[2:].split("/"):
        cursor = cursor[token]
    return cursor


def _is_type(value, type_name):
    if type_name == "object":
        return isinstance(value, dict)
    if type_name == "array":
        return isinstance(value, list)
    if type_name == "string":
        return isinstance(value, str)
    if type_name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "boolean":
        return isinstance(value, bool)
    return True


def _validate_schema_value(value, schema, root_schema, path, errors):
    if not isinstance(schema, dict):
        return

    if "$ref" in schema:
        schema = _resolve_ref(root_schema, schema["$ref"])

    expected_type = schema.get("type")
    if expected_type and not _is_type(value, expected_type):
        append_error(errors, f"schema: {path} expected type {expected_type}")
        return

    if "enum" in schema and value not in schema["enum"]:
        append_error(errors, f"schema: {path} invalid enum value: {value}")

    if expected_type == "string":
        min_len = schema.get("minLength")
        if isinstance(min_len, int) and len(value) < min_len:
            append_error(errors, f"schema: {path} minLength violation")
        pattern = schema.get("pattern")
        if pattern and not re.match(pattern, value):
            append_error(errors, f"schema: {path} does not match pattern")

    if expected_type == "integer":
        minimum = schema.get("minimum")
        if isinstance(minimum, int) and value < minimum:
            append_error(errors, f"schema: {path} below minimum {minimum}")

    if expected_type == "array":
        min_items = schema.get("minItems")
        if isinstance(min_items, int) and len(value) < min_items:
            append_error(errors, f"schema: {path} minItems violation")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for idx, row in enumerate(value):
                _validate_schema_value(row, item_schema, root_schema, f"{path}[{idx}]", errors)

    if expected_type == "object":
        required = schema.get("required", [])
        props = schema.get("properties", {})
        for key in required:
            if key not in value:
                append_error(errors, f"schema: {path}.{key} is required")
        if schema.get("additionalProperties") is False:
            for key in value.keys():
                if key not in props:
                    append_error(errors, f"schema: {path} unexpected key: {key}")
        for key, prop_schema in props.items():
            if key in value:
                _validate_schema_value(value[key], prop_schema, root_schema, f"{path}.{key}", errors)


def validate_meta_graph_schema(graph_doc, schema_doc):
    errors = []
    if not isinstance(graph_doc, dict):
        return ["document must be object"]
    if not isinstance(schema_doc, dict):
        return ["schema document must be object"]
    _validate_schema_value(graph_doc, schema_doc, schema_doc, "$", errors)
    return errors


def validate_meta_graph(graph_doc):
    errors = []
    mpg = graph_doc.get("meta_plan_graph")
    if not isinstance(mpg, dict):
        return ["meta_plan_graph object is required"]

    for key in ["meta_plan_id", "graph_revision", "source_of_truth", "initiative", "nodes", "edges"]:
        if key not in mpg:
            errors.append(f"meta_plan_graph.{key} is required")
    if errors:
        return errors

    nodes = mpg.get("nodes")
    edges = mpg.get("edges")
    if not isinstance(nodes, list) or not nodes:
        errors.append("meta_plan_graph.nodes must be non-empty list")
        return errors
    if not isinstance(edges, list):
        errors.append("meta_plan_graph.edges must be list")
        return errors

    seen_node_ids = set()
    seen_orders = set()
    for idx, node in enumerate(nodes):
        path = f"meta_plan_graph.nodes[{idx}]"
        if not isinstance(node, dict):
            errors.append(f"{path} must be object")
            continue
        for key in [
            "node_id",
            "plan_path",
            "execution_order",
            "target_repo",
            "component",
            "workflow_state",
            "loop_profile",
            "status",
            "last_verdict",
            "last_reason",
        ]:
            if key not in node:
                errors.append(f"{path}.{key} is required")

        node_id = node.get("node_id")
        if isinstance(node_id, str) and node_id:
            if node_id in seen_node_ids:
                errors.append(f"duplicate node_id: {node_id}")
            seen_node_ids.add(node_id)

        eo = node.get("execution_order")
        if isinstance(eo, int) and eo > 0:
            if eo in seen_orders:
                errors.append(f"duplicate execution_order: {eo}")
            seen_orders.add(eo)
        else:
            errors.append(f"{path}.execution_order must be integer >= 1")

    seen_edge_keys = set()
    for idx, edge in enumerate(edges):
        path = f"meta_plan_graph.edges[{idx}]"
        if not isinstance(edge, dict):
            errors.append(f"{path} must be object")
            continue
        for key in ["from", "to", "type"]:
            if key not in edge:
                errors.append(f"{path}.{key} is required")
        src = edge.get("from")
        dst = edge.get("to")
        typ = edge.get("type")
        if src == dst and src:
            errors.append(f"self-edge is not allowed: {src}")
        if src and src not in seen_node_ids:
            errors.append(f"{path}.from references unknown node: {src}")
        if dst and dst not in seen_node_ids:
            errors.append(f"{path}.to references unknown node: {dst}")
        key = (src, dst, typ)
        if src and dst and typ:
            if key in seen_edge_keys:
                errors.append(f"duplicate edge: {src}->{dst}:{typ}")
            seen_edge_keys.add(key)

    return errors


def has_cycle(nodes, edges, edge_types):
    node_ids = [node["node_id"] for node in nodes]
    graph = {node_id: set() for node_id in node_ids}
    for edge in edges:
        if edge.get("type") in edge_types:
            graph.setdefault(edge["from"], set()).add(edge["to"])

    visiting = set()
    visited = set()

    def dfs(node_id):
        if node_id in visiting:
            return True
        if node_id in visited:
            return False
        visiting.add(node_id)
        for child in graph.get(node_id, set()):
            if dfs(child):
                return True
        visiting.remove(node_id)
        visited.add(node_id)
        return False

    for node_id in node_ids:
        if dfs(node_id):
            return True
    return False


def normalize_graph(mpg):
    normalized = dict(mpg)
    normalized["nodes"] = sorted(
        [dict(node) for node in mpg.get("nodes", [])],
        key=lambda x: (x.get("execution_order", 0), x.get("node_id", "")),
    )
    normalized["edges"] = sorted(
        [dict(edge) for edge in mpg.get("edges", [])],
        key=lambda x: (x.get("from", ""), x.get("to", ""), x.get("type", "")),
    )
    return normalized


def compute_ready_set(nodes, edges):
    by_id = {node["node_id"]: node for node in nodes}
    inbound_dep = {node["node_id"]: [] for node in nodes}
    inbound_block = {node["node_id"]: [] for node in nodes}
    for edge in edges:
        if edge.get("type") == "depends_on":
            inbound_dep.setdefault(edge["to"], []).append(edge["from"])
        elif edge.get("type") == "blocks":
            inbound_block.setdefault(edge["to"], []).append(edge["from"])

    ready_set = []
    blocked_nodes = []
    for node in sorted(nodes, key=lambda x: (x["execution_order"], x["node_id"])):
        node_id = node["node_id"]
        status = node["status"]
        if status != "ready":
            blocked_nodes.append({"node_id": node_id, "reason": f"status={status}"})
            continue

        missing_done = []
        for src in inbound_dep.get(node_id, []):
            upstream_status = by_id[src]["status"]
            if upstream_status != "done":
                missing_done.append({"from": src, "status": upstream_status})
        if missing_done:
            blocked_nodes.append({"node_id": node_id, "reason": "dependency_not_done", "details": missing_done})
            continue

        active_blockers = []
        for src in inbound_block.get(node_id, []):
            upstream_status = by_id[src]["status"]
            if upstream_status in ACTIVE_BLOCKER_STATUSES:
                active_blockers.append({"from": src, "status": upstream_status})
        if active_blockers:
            blocked_nodes.append({"node_id": node_id, "reason": "blocked_by_active_node", "details": active_blockers})
            continue

        ready_set.append(node_id)

    return ready_set, blocked_nodes


def main():
    parser = argparse.ArgumentParser(description="Build deterministic meta-plan graph artifact and ready-set projection")
    parser.add_argument(
        "--contract-file",
        default="planningops/fixtures/meta-plan-graph-sample.json",
        help="MPG v1 contract json path",
    )
    parser.add_argument(
        "--output",
        default="planningops/artifacts/meta-plan/meta-graph.json",
        help="output artifact path",
    )
    parser.add_argument(
        "--schema-file",
        default="planningops/schemas/meta-plan-graph.schema.json",
        help="meta-plan graph schema path",
    )
    parser.add_argument("--strict", action="store_true", help="return non-zero when validation fails")
    args = parser.parse_args()

    contract_doc = read_json(Path(args.contract_file))
    schema_doc = read_json(Path(args.schema_file))
    validation_errors = validate_meta_graph_schema(contract_doc, schema_doc) + validate_meta_graph(contract_doc)

    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "contract_file": args.contract_file,
        "schema_file": args.schema_file,
        "validation_errors": validation_errors,
    }
    if validation_errors:
        report["verdict"] = "fail"
        report["reasons"] = ["meta_graph_contract_invalid"]
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    mpg = normalize_graph(contract_doc["meta_plan_graph"])
    cycle_detected = has_cycle(mpg["nodes"], mpg["edges"], {"depends_on", "blocks"})
    if cycle_detected:
        report["verdict"] = "fail"
        report["reasons"] = ["meta_graph_cycle_detected"]
        report["meta_plan_graph"] = mpg
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    ready_set, blocked_nodes = compute_ready_set(mpg["nodes"], mpg["edges"])
    report.update(
        {
            "meta_plan_id": mpg["meta_plan_id"],
            "graph_revision": mpg["graph_revision"],
            "source_of_truth": mpg["source_of_truth"],
            "initiative": mpg["initiative"],
            "node_count": len(mpg["nodes"]),
            "edge_count": len(mpg["edges"]),
            "ready_set_count": len(ready_set),
            "ready_set": ready_set,
            "blocked_nodes": blocked_nodes,
            "meta_plan_graph": mpg,
            "verdict": "pass",
            "reasons": [],
        }
    )

    write_json(Path(args.output), report)
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
