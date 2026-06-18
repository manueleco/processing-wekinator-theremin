#!/usr/bin/env python3
"""Run the Python rehab app from the repository checkout."""

from __future__ import annotations

import sys
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parent
SRC = APP_ROOT / "src"
sys.path.insert(0, str(SRC))

from theremin_rehab.app import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
