#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import sys

SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

# Compatibility wrapper target: core/loop/runner.py
from core.loop.runner import *  # noqa: F401,F403


if __name__ == "__main__":
    from core.loop.runner import main

    sys.exit(main())
