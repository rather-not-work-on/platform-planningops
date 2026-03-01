#!/usr/bin/env python3

import argparse
import ast
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_POLICY_PATH = Path("planningops/config/refactor-hygiene-policy.json")
DEFAULT_OUTPUT_ROOT = Path("planningops/artifacts/refactor-hygiene")
JS_EXTENSIONS = {".js", ".ts", ".tsx"}
PY_EXTENSIONS = {".py"}


def utc_now_iso():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def save_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def parse_args():
    parser = argparse.ArgumentParser(description="Build module-level refactor hygiene queue")
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--policy-file", default=str(DEFAULT_POLICY_PATH))
    parser.add_argument("--run-id", default=None)
    parser.add_argument("--output-root", default=str(DEFAULT_OUTPUT_ROOT))
    return parser.parse_args()


def read_policy(path: Path):
    if not path.exists():
        raise ValueError(f"policy file not found: {path}")
    doc = load_json(path)
    required = ["scan_roots", "include_extensions", "exclude_dirs", "max_modules_per_cycle"]
    for key in required:
        if key not in doc:
            raise ValueError(f"policy missing required key: {key}")
    return doc


def should_skip(path: Path, exclude_dirs):
    parts = set(path.parts)
    return any(name in parts for name in exclude_dirs)


def gather_source_files(repo_root: Path, policy: dict):
    include_exts = set(policy.get("include_extensions", []))
    exclude_dirs = set(policy.get("exclude_dirs", []))
    roots = []
    files = []

    for rel_root in policy.get("scan_roots", []):
        abs_root = (repo_root / rel_root).resolve()
        if not abs_root.exists():
            continue
        roots.append((rel_root, abs_root))
        for path in abs_root.rglob("*"):
            if not path.is_file():
                continue
            if path.name.startswith("._"):
                continue
            if path.suffix not in include_exts:
                continue
            if should_skip(path, exclude_dirs):
                continue
            files.append((rel_root, abs_root, path.resolve()))

    return roots, sorted(files, key=lambda x: str(x[2]))


def module_id_for_file(path: Path, root_abs: Path, root_rel: str, multi_root: bool):
    rel = path.relative_to(root_abs)
    if len(rel.parts) > 1:
        raw_module = rel.parts[0]
    else:
        raw_module = rel.stem
    if not multi_root:
        return raw_module
    root_label = root_rel.replace("/", "_").replace("\\", "_")
    return f"{root_label}:{raw_module}"


def extract_python_imports(path: Path):
    text = path.read_text(encoding="utf-8", errors="ignore")
    tree = ast.parse(text)
    imports = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for item in node.names:
                imports.append({"kind": "import", "module": item.name, "level": 0})
        elif isinstance(node, ast.ImportFrom):
            imports.append({"kind": "from", "module": node.module or "", "level": node.level})
    return imports


JS_IMPORT_RE = re.compile(
    r"""(?:
        import\s+(?:[^'"]+?\s+from\s+)?['"](?P<import_path>[^'"]+)['"]|
        require\(\s*['"](?P<require_path>[^'"]+)['"]\s*\)|
        import\(\s*['"](?P<dynamic_path>[^'"]+)['"]\s*\)
    )""",
    re.VERBOSE,
)


def extract_js_imports(path: Path):
    text = path.read_text(encoding="utf-8", errors="ignore")
    results = []
    for match in JS_IMPORT_RE.finditer(text):
        value = match.group("import_path") or match.group("require_path") or match.group("dynamic_path")
        if value:
            results.append(value)
    return results


def resolve_relative_js_target(base_file: Path, import_path: str, all_files_set):
    raw = (base_file.parent / import_path).resolve()
    candidates = [raw]
    for ext in [".js", ".ts", ".tsx", ".py"]:
        candidates.append(Path(str(raw) + ext))
    for ext in [".js", ".ts", ".tsx", ".py"]:
        candidates.append((raw / f"index{ext}").resolve())
    for candidate in candidates:
        if candidate in all_files_set:
            return candidate
    return None


def package_name_for_js(import_path: str):
    if import_path.startswith("@"):
        parts = import_path.split("/")
        return "/".join(parts[:2]) if len(parts) >= 2 else import_path
    return import_path.split("/")[0]


def detect_legacy_markers(path: Path, markers):
    lower_name = str(path).lower()
    hits = []
    for marker in markers:
        marker_l = marker.lower()
        if marker_l in lower_name:
            hits.append({"marker": marker, "location": "path"})

    content = path.read_text(encoding="utf-8", errors="ignore")
    lowered = content.lower()
    for marker in markers:
        marker_l = marker.lower()
        if marker_l in lowered:
            hits.append({"marker": marker, "location": "content"})
    return hits


def tarjan_scc(graph):
    index = 0
    stack = []
    on_stack = set()
    indices = {}
    lowlink = {}
    components = []

    def strong_connect(v):
        nonlocal index
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.append(v)
        on_stack.add(v)

        for w in graph.get(v, []):
            if w not in indices:
                strong_connect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif w in on_stack:
                lowlink[v] = min(lowlink[v], indices[w])

        if lowlink[v] == indices[v]:
            comp = []
            while True:
                w = stack.pop()
                on_stack.remove(w)
                comp.append(w)
                if w == v:
                    break
            components.append(sorted(comp))

    for node in sorted(graph.keys()):
        if node not in indices:
            strong_connect(node)

    return components


def build_topology(repo_root: Path, roots, files, policy):
    multi_root = len(roots) > 1
    markers = policy.get("legacy_markers", [])
    alias_prefixes = tuple(policy.get("internal_alias_prefixes", []))
    stdlib = set(getattr(sys, "stdlib_module_names", set()))

    file_to_module = {}
    module_to_files = defaultdict(list)
    for root_rel, root_abs, path in files:
        mod_id = module_id_for_file(path, root_abs, root_rel, multi_root)
        file_to_module[path] = mod_id
        module_to_files[mod_id].append(path)

    modules = sorted(module_to_files.keys())
    module_set = set(modules)
    all_files_set = set(file_to_module.keys())

    internal_edges = defaultdict(set)
    external_deps = defaultdict(set)
    legacy_hits = defaultdict(list)
    parse_errors = []

    for path, source_module in sorted(file_to_module.items(), key=lambda x: str(x[0])):
        for row in detect_legacy_markers(path, markers):
            legacy_hits[source_module].append(
                {
                    "file": str(path.relative_to(repo_root)),
                    "marker": row["marker"],
                    "location": row["location"],
                }
            )

        try:
            if path.suffix in PY_EXTENSIONS:
                imports = extract_python_imports(path)
                for item in imports:
                    raw_mod = item["module"] or ""
                    if item["level"] > 0 and not raw_mod:
                        continue
                    if not raw_mod:
                        continue
                    top = raw_mod.split(".")[0]
                    if top in module_set and top != source_module:
                        internal_edges[source_module].add(top)
                    elif top and top not in stdlib and top != "__future__":
                        external_deps[source_module].add(top)
            elif path.suffix in JS_EXTENSIONS:
                imports = extract_js_imports(path)
                for spec in imports:
                    if spec.startswith("."):
                        target = resolve_relative_js_target(path, spec, all_files_set)
                        if target is None:
                            continue
                        target_module = file_to_module.get(target)
                        if target_module and target_module != source_module:
                            internal_edges[source_module].add(target_module)
                        continue
                    if alias_prefixes and spec.startswith(alias_prefixes):
                        continue
                    package = package_name_for_js(spec)
                    if package:
                        external_deps[source_module].add(package)
        except Exception as exc:  # noqa: BLE001
            parse_errors.append(
                {
                    "file": str(path.relative_to(repo_root)),
                    "module": source_module,
                    "error": str(exc),
                }
            )

    graph = {module: set(internal_edges.get(module, set())) for module in modules}
    indegree = {module: 0 for module in modules}
    for source in modules:
        for target in graph.get(source, set()):
            indegree[target] = indegree.get(target, 0) + 1

    components = tarjan_scc(graph)
    cycles = [comp for comp in components if len(comp) > 1]
    for node in modules:
        if node in graph.get(node, set()):
            cycles.append([node])
    cycle_nodes = {item for comp in cycles for item in comp}

    module_rows = []
    for module in modules:
        module_rows.append(
            {
                "module": module,
                "file_count": len(module_to_files[module]),
                "files": [str(p.relative_to(repo_root)) for p in sorted(module_to_files[module])],
                "internal_dependencies": sorted(graph.get(module, set())),
                "internal_out_degree": len(graph.get(module, set())),
                "internal_in_degree": indegree.get(module, 0),
                "external_dependencies": sorted(external_deps.get(module, set())),
                "legacy_hits": legacy_hits.get(module, []),
                "in_cycle": module in cycle_nodes,
            }
        )

    unique_external = sorted({d for deps in external_deps.values() for d in deps})
    edge_count = sum(len(v) for v in graph.values())

    return {
        "scan": {
            "repo_root": str(repo_root.resolve()),
            "scan_roots": [rel for rel, _ in roots],
            "files_scanned": len(files),
            "modules_discovered": len(modules),
        },
        "topology": {
            "internal_edge_count": edge_count,
            "cycle_count": len(cycles),
            "cycles": cycles,
            "external_packages": unique_external,
            "modules": module_rows,
            "parse_errors": parse_errors,
        },
    }


def build_refactor_queue(doc: dict, policy: dict):
    modules = doc["topology"]["modules"]
    budget = int(policy.get("internal_dependency_budget", {}).get("max_out_degree", 5))
    max_per_cycle = int(policy.get("max_modules_per_cycle", 3))
    max_files = int(policy.get("max_files_per_module", 20))
    checkpoint_every = int(policy.get("checkpoint_every_tasks", 2))

    external_candidates = []
    internal_candidates = []

    for row in modules:
        module = row["module"]
        ext_count = len(row["external_dependencies"])
        out_degree = int(row["internal_out_degree"])
        in_degree = int(row["internal_in_degree"])
        legacy_count = len(row["legacy_hits"])
        in_cycle = bool(row["in_cycle"])

        if ext_count > 0:
            score = ext_count * 5 + legacy_count * 2 + (3 if in_cycle else 0)
            external_candidates.append(
                {
                    "module": module,
                    "score": score,
                    "external_dependencies": row["external_dependencies"],
                    "legacy_hit_count": legacy_count,
                    "in_cycle": in_cycle,
                    "file_count": row["file_count"],
                }
            )

        needs_internal_cleanup = in_cycle or out_degree > budget or legacy_count > 0
        if needs_internal_cleanup:
            score = max(out_degree - budget, 0) * 4 + in_degree + (4 if in_cycle else 0) + legacy_count * 2
            internal_candidates.append(
                {
                    "module": module,
                    "score": score,
                    "internal_dependencies": row["internal_dependencies"],
                    "internal_out_degree": out_degree,
                    "internal_in_degree": in_degree,
                    "legacy_hit_count": legacy_count,
                    "in_cycle": in_cycle,
                    "file_count": row["file_count"],
                }
            )

    external_sorted = sorted(external_candidates, key=lambda x: (-x["score"], x["module"]))
    internal_sorted = sorted(internal_candidates, key=lambda x: (-x["score"], x["module"]))

    external_selected = external_sorted[:max_per_cycle]
    internal_selected = internal_sorted[:max_per_cycle]

    ext_task_ids = {}
    external_tasks = []
    for idx, row in enumerate(external_selected, start=1):
        task_id = f"E{idx:02d}"
        ext_task_ids[row["module"]] = task_id
        external_tasks.append(
            {
                "task_id": task_id,
                "phase": "external_dependency_cleanup",
                "module": row["module"],
                "priority_score": row["score"],
                "target_dependencies": row["external_dependencies"],
                "constraints": {
                    "max_files_touched": max_files,
                    "must_not_expand_public_interface": True,
                    "must_record_delta_note": True,
                },
                "success_criteria": [
                    "Unused/transitive external dependencies removed or pinned.",
                    "Module contract tests and CI checks remain green.",
                ],
            }
        )

    internal_tasks = []
    for idx, row in enumerate(internal_selected, start=1):
        task_id = f"I{idx:02d}"
        depends_on = []
        if row["module"] in ext_task_ids:
            depends_on.append(ext_task_ids[row["module"]])
        internal_tasks.append(
            {
                "task_id": task_id,
                "phase": "internal_dependency_cleanup",
                "module": row["module"],
                "priority_score": row["score"],
                "depends_on": depends_on,
                "coupling_snapshot": {
                    "out_degree": row["internal_out_degree"],
                    "in_degree": row["internal_in_degree"],
                    "in_cycle": row["in_cycle"],
                    "legacy_hit_count": row["legacy_hit_count"],
                },
                "constraints": {
                    "max_files_touched": max_files,
                    "must_reduce_or_keep_out_degree": True,
                    "must_preserve_behavior": True,
                    "must_record_interface_changes": True,
                },
                "success_criteria": [
                    "Internal dependency direction is clearer and module boundary is simpler.",
                    "No new bidirectional dependency is introduced.",
                ],
            }
        )

    execution_order = [t["task_id"] for t in external_tasks] + [t["task_id"] for t in internal_tasks]
    checkpoints = []
    if checkpoint_every > 0:
        for idx in range(checkpoint_every, len(execution_order) + 1, checkpoint_every):
            checkpoints.append(
                {
                    "after_task_index": idx,
                    "actions": [
                        "Summarize decisions and touched interfaces.",
                        "Prune stale context and close irrelevant TODOs.",
                        "Re-validate topology drift before next task.",
                    ],
                }
            )

    return {
        "queues": {
            "external_first": external_tasks,
            "internal_next": internal_tasks,
            "execution_order": execution_order,
            "checkpoints": checkpoints,
        }
    }


def build_summary_md(doc: dict, queue_doc: dict, run_id: str, policy_path: Path):
    scan = doc["scan"]
    topology = doc["topology"]
    queues = queue_doc["queues"]
    ext = queues["external_first"]
    internal = queues["internal_next"]
    checkpoints = queues["checkpoints"]

    lines = [
        f"# Refactor Hygiene Summary ({run_id})",
        "",
        f"- generated_at_utc: {utc_now_iso()}",
        f"- policy_file: {policy_path}",
        f"- files_scanned: {scan['files_scanned']}",
        f"- modules_discovered: {scan['modules_discovered']}",
        f"- internal_edge_count: {topology['internal_edge_count']}",
        f"- cycle_count: {topology['cycle_count']}",
        "",
        "## External-First Queue",
    ]

    if not ext:
        lines.append("- none")
    else:
        for row in ext:
            deps = ", ".join(row["target_dependencies"]) if row["target_dependencies"] else "none"
            lines.append(
                f"- {row['task_id']} {row['module']} (score={row['priority_score']}): external={deps}"
            )

    lines.extend(["", "## Internal-Next Queue"])
    if not internal:
        lines.append("- none")
    else:
        for row in internal:
            dep_text = f", depends_on={','.join(row['depends_on'])}" if row["depends_on"] else ""
            coupl = row["coupling_snapshot"]
            lines.append(
                f"- {row['task_id']} {row['module']} (score={row['priority_score']}, out={coupl['out_degree']}, in={coupl['in_degree']}, cycle={coupl['in_cycle']}){dep_text}"
            )

    lines.extend(["", "## Cleanup Checkpoints"])
    if not checkpoints:
        lines.append("- none")
    else:
        for row in checkpoints:
            lines.append(f"- after task #{row['after_task_index']}: context prune + interface summary + topology re-check")

    if topology["parse_errors"]:
        lines.extend(["", "## Parse Errors"])
        for row in topology["parse_errors"]:
            lines.append(f"- {row['file']}: {row['error']}")

    return "\n".join(lines) + "\n"


def main():
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    policy_path = Path(args.policy_file).resolve()
    output_root = Path(args.output_root).resolve()
    run_id = args.run_id or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    policy = read_policy(policy_path)
    roots, files = gather_source_files(repo_root, policy)
    if not files:
        raise ValueError("no source files found for policy scan_roots/include_extensions")

    topology_doc = build_topology(repo_root, roots, files, policy)
    queue_doc = build_refactor_queue(topology_doc, policy)

    run_dir = output_root / run_id
    summary_md = build_summary_md(topology_doc, queue_doc, run_id, policy_path)

    report = {
        "run_id": run_id,
        "generated_at_utc": utc_now_iso(),
        "policy_file": str(policy_path),
        "policy": policy,
        **topology_doc,
        **queue_doc,
    }

    save_json(run_dir / "report.json", report)
    save_text(run_dir / "summary.md", summary_md)
    save_json(
        output_root / "latest.json",
        {
            "run_id": run_id,
            "generated_at_utc": report["generated_at_utc"],
            "report": str((run_dir / "report.json").relative_to(repo_root)),
            "summary": str((run_dir / "summary.md").relative_to(repo_root)),
        },
    )

    print(json.dumps({"result": "ok", "run_id": run_id, "report": str(run_dir / "report.json")}, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
