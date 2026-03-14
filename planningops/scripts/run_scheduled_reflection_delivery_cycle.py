#!/usr/bin/env python3

import runpy
from pathlib import Path


if __name__ == "__main__":
    target = Path(__file__).resolve().parent / "federation" / "run_scheduled_reflection_delivery_cycle.py"
    runpy.run_path(str(target), run_name="__main__")
