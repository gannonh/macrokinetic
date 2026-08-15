#!/usr/bin/env python3
"""Choose delta refresh or full rebuild before downloading expensive inputs."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from food_database.snapshots import select_snapshot_delta


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--off-index", type=Path, required=True)
    parser.add_argument("--snapshot-manifest", type=Path)
    parser.add_argument("--now-epoch", type=int, default=int(time.time()))
    args = parser.parse_args()

    if args.snapshot_manifest is None:
        print("full")
        return

    manifest = json.loads(args.snapshot_manifest.read_text(encoding="utf-8"))
    selection = select_snapshot_delta(
        manifest,
        args.off_index.read_text(encoding="utf-8"),
        now_epoch=args.now_epoch,
    )
    print("delta" if selection is not None else "full")


if __name__ == "__main__":
    main()
