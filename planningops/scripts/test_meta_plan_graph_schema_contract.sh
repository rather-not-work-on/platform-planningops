#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
from pathlib import Path


schema = json.loads(Path("planningops/schemas/meta-plan-graph.schema.json").read_text(encoding="utf-8"))
sample = json.loads(Path("planningops/fixtures/meta-plan-graph-sample.json").read_text(encoding="utf-8"))

assert "meta_plan_graph" in sample, "meta_plan_graph missing"
graph = sample["meta_plan_graph"]
required_graph_keys = ["meta_plan_id", "graph_revision", "source_of_truth", "initiative", "nodes", "edges"]
for key in required_graph_keys:
    assert key in graph, f"missing graph key: {key}"

nodes = graph["nodes"]
edges = graph["edges"]
assert isinstance(nodes, list) and nodes, "nodes must be non-empty list"
assert isinstance(edges, list), "edges must be list"

node_required = [
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
]
node_component_enum = set(schema["$defs"]["node"]["properties"]["component"]["enum"])
node_workflow_enum = set(schema["$defs"]["node"]["properties"]["workflow_state"]["enum"])
node_loop_enum = set(schema["$defs"]["node"]["properties"]["loop_profile"]["enum"])
node_status_enum = set(schema["$defs"]["node"]["properties"]["status"]["enum"])
node_verdict_enum = set(schema["$defs"]["node"]["properties"]["last_verdict"]["enum"])

node_ids = set()
execution_orders = set()
for idx, node in enumerate(nodes):
    for key in node_required:
        assert key in node, f"node[{idx}] missing key: {key}"
    assert node["node_id"] not in node_ids, f"duplicate node_id: {node['node_id']}"
    node_ids.add(node["node_id"])

    assert int(node["execution_order"]) > 0, f"invalid execution_order: {node['execution_order']}"
    assert node["execution_order"] not in execution_orders, f"duplicate execution_order: {node['execution_order']}"
    execution_orders.add(node["execution_order"])

    assert node["component"] in node_component_enum, f"invalid component: {node['component']}"
    assert node["workflow_state"] in node_workflow_enum, f"invalid workflow_state: {node['workflow_state']}"
    assert node["loop_profile"] in node_loop_enum, f"invalid loop_profile: {node['loop_profile']}"
    assert node["status"] in node_status_enum, f"invalid status: {node['status']}"
    assert node["last_verdict"] in node_verdict_enum, f"invalid last_verdict: {node['last_verdict']}"

edge_required = ["from", "to", "type"]
edge_type_enum = set(schema["$defs"]["edge"]["properties"]["type"]["enum"])
edge_keys = set()
for idx, edge in enumerate(edges):
    for key in edge_required:
        assert key in edge, f"edge[{idx}] missing key: {key}"
    assert edge["type"] in edge_type_enum, f"invalid edge type: {edge['type']}"
    assert edge["from"] in node_ids, f"edge[{idx}] unknown from: {edge['from']}"
    assert edge["to"] in node_ids, f"edge[{idx}] unknown to: {edge['to']}"
    assert edge["from"] != edge["to"], f"edge[{idx}] self-edge not allowed"

    edge_key = (edge["from"], edge["to"], edge["type"])
    assert edge_key not in edge_keys, f"duplicate edge: {edge_key}"
    edge_keys.add(edge_key)


def has_cycle(edge_rows):
    graph_map = {}
    for edge in edge_rows:
        graph_map.setdefault(edge["from"], set()).add(edge["to"])

    visiting = set()
    visited = set()

    def dfs(node_id):
        if node_id in visiting:
            return True
        if node_id in visited:
            return False
        visiting.add(node_id)
        for child in graph_map.get(node_id, set()):
            if dfs(child):
                return True
        visiting.remove(node_id)
        visited.add(node_id)
        return False

    for node_id in node_ids:
        if dfs(node_id):
            return True
    return False


acyclic_types = {"depends_on", "blocks"}
filtered_edges = [edge for edge in edges if edge["type"] in acyclic_types]
assert not has_cycle(filtered_edges), "depends_on/blocks graph must be acyclic"

print("meta-plan graph schema contract tests ok")
PY
