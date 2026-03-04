#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from build_meta_plan_graph import (
    compute_ready_set,
    has_cycle,
    normalize_graph,
    read_json,
    validate_meta_graph,
    validate_meta_graph_schema,
    write_json,
)


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def build_pipeline_commands(node):
    component = node.get("component")
    # Local-first deterministic baseline pipeline.
    base = [
        ["bash", "planningops/scripts/test_meta_plan_graph_schema_contract.sh"],
        [
            "python3",
            "planningops/scripts/compile_plan_to_backlog.py",
            "--contract-file",
            "planningops/fixtures/plan-execution-contract-sample.json",
            "--output",
            "planningops/artifacts/validation/plan-compile-report.json",
        ],
        [
            "python3",
            "planningops/scripts/verify_plan_projection.py",
            "--contract-file",
            "planningops/fixtures/plan-execution-contract-sample.json",
            "--snapshot-file",
            "planningops/fixtures/plan-projection-snapshot-sample.json",
            "--strict",
            "--output",
            "planningops/artifacts/validation/plan-projection-report.json",
        ],
    ]

    # Keep pipeline stable for now; this hook enables future component-specific branching.
    if component in {"contracts", "planningops", "orchestrator", "runtime", "provider_gateway", "observability_gateway"}:
        return base
    return base


def main():
    parser = argparse.ArgumentParser(description="Meta plan orchestrator (MPG v1) for ready-set execution planning")
    parser.add_argument(
        "--meta-graph-contract",
        default="planningops/fixtures/meta-plan-graph-sample.json",
        help="Meta plan graph contract json path",
    )
    parser.add_argument(
        "--meta-graph-output",
        default="planningops/artifacts/meta-plan/meta-graph.json",
        help="Normalized graph output path",
    )
    parser.add_argument(
        "--output",
        default="planningops/artifacts/meta-plan/meta-execution-report.json",
        help="Meta execution report path",
    )
    parser.add_argument(
        "--schema-file",
        default="planningops/schemas/meta-plan-graph.schema.json",
        help="Meta plan graph schema path",
    )
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument("--max-nodes", type=int, default=1, help="Maximum ready nodes to schedule in one run")
    parser.add_argument("--strict", action="store_true", help="Return non-zero on fail verdict")
    args = parser.parse_args()

    contract_doc = read_json(Path(args.meta_graph_contract))
    schema_doc = read_json(Path(args.schema_file))
    validation_errors = validate_meta_graph_schema(contract_doc, schema_doc) + validate_meta_graph(contract_doc)
    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "mode": args.mode,
        "meta_graph_contract": args.meta_graph_contract,
        "schema_file": args.schema_file,
        "meta_graph_output": args.meta_graph_output,
        "validation_errors": validation_errors,
    }

    if validation_errors:
        report["verdict"] = "fail"
        report["reasons"] = ["meta_graph_contract_invalid"]
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    mpg = normalize_graph(contract_doc["meta_plan_graph"])
    if has_cycle(mpg["nodes"], mpg["edges"], {"depends_on", "blocks"}):
        report["verdict"] = "fail"
        report["reasons"] = ["meta_graph_cycle_detected"]
        report["meta_plan_graph"] = mpg
        write_json(Path(args.meta_graph_output), {"verdict": "fail", "reason": "cycle_detected", "meta_plan_graph": mpg})
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    ready_set, blocked_nodes = compute_ready_set(mpg["nodes"], mpg["edges"])
    node_by_id = {node["node_id"]: node for node in mpg["nodes"]}
    selected_node_ids = ready_set[: max(0, args.max_nodes)]
    skipped_ready_node_ids = ready_set[max(0, args.max_nodes) :]

    execution_rows = []
    failure_count = 0

    for node_id in selected_node_ids:
        node = node_by_id[node_id]
        commands = build_pipeline_commands(node)
        command_results = []
        node_fail = False

        for cmd in commands:
            if args.mode == "dry-run":
                command_results.append(
                    {
                        "command": " ".join(cmd),
                        "rc": None,
                        "verdict": "simulated",
                        "stdout": "",
                        "stderr": "",
                    }
                )
                continue

            rc, out, err = run(cmd)
            command_results.append(
                {
                    "command": " ".join(cmd),
                    "rc": rc,
                    "verdict": "pass" if rc == 0 else "fail",
                    "stdout": out[:2000],
                    "stderr": err[:2000],
                }
            )
            if rc != 0:
                node_fail = True
                break

        node_verdict = "pass"
        reason = "pipeline_pass"
        if args.mode == "dry-run":
            node_verdict = "simulated"
            reason = "dry_run_pipeline_not_executed"
        elif node_fail:
            node_verdict = "fail"
            reason = "pipeline_command_failed"
            failure_count += 1

        execution_rows.append(
            {
                "node_id": node_id,
                "execution_order": node["execution_order"],
                "component": node["component"],
                "status_before": node["status"],
                "pipeline_command_count": len(commands),
                "command_results": command_results,
                "node_verdict": node_verdict,
                "reason": reason,
            }
        )

    report.update(
        {
            "meta_plan_id": mpg["meta_plan_id"],
            "graph_revision": mpg["graph_revision"],
            "initiative": mpg["initiative"],
            "node_count": len(mpg["nodes"]),
            "edge_count": len(mpg["edges"]),
            "ready_set_count": len(ready_set),
            "ready_set": ready_set,
            "selected_node_ids": selected_node_ids,
            "skipped_ready_node_ids": skipped_ready_node_ids,
            "blocked_nodes": blocked_nodes,
            "execution_rows": execution_rows,
            "failure_count": failure_count,
            "meta_plan_graph": mpg,
        }
    )

    if args.mode == "dry-run":
        report["verdict"] = "pass"
        report["reasons"] = ["dry_run_only"]
    elif failure_count == 0:
        report["verdict"] = "pass"
        report["reasons"] = []
    else:
        report["verdict"] = "fail"
        report["reasons"] = ["node_pipeline_failure"]

    write_json(Path(args.meta_graph_output), {"verdict": report["verdict"], "meta_plan_graph": mpg, "ready_set": ready_set})
    write_json(Path(args.output), report)
    print(json.dumps(report, ensure_ascii=True, indent=2))

    if args.strict and report["verdict"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
