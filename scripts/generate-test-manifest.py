#!/usr/bin/env python3
"""Generate the CI test manifest for unit/integration lane accounting."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from ci.lanes import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
