#!/usr/bin/env python3

from __future__ import annotations

import re


PLANNING_CONTEXT_KEYS = [
    "plan_item_id",
    "target_repo",
    "component",
    "workflow_state",
    "loop_profile",
    "execution_order",
    "depends_on",
    "plan_lane",
    "execution_kind",
]


def normalize_value(raw: str | None):
    return str(raw or "").strip().strip("`")


def parse_metadata(body: str, keys=None):
    metadata = {}
    scan_keys = list(keys or PLANNING_CONTEXT_KEYS)
    for key in scan_keys:
        match = re.search(rf"(?m)^(?:-\s*)?{re.escape(key)}:\s*`?([^`\n]+)`?\s*$", body or "")
        if match:
            metadata[key] = match.group(1).strip()
    return metadata


def parse_execution_order(raw: str | None):
    value = normalize_value(raw)
    return int(value) if value.isdigit() else None


def parse_depends_on_plan_item_keys(raw: str | None, pattern: str = r"[A-Z][0-9]{2}"):
    value = normalize_value(raw)
    if not value:
        return []
    return sorted(set(re.findall(pattern, value)))
