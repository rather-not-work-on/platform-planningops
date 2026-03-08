#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import sys

SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

# Compatibility wrapper target: federation/adapter_registry.py
from federation.adapter_registry import *  # noqa: F401,F403


if __name__ == "__main__":
    from federation.adapter_registry import supported_repositories

    for repo in supported_repositories():
        print(repo)
