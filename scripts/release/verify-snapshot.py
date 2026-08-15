#!/usr/bin/env python3
"""Verify a downloaded promoted snapshot before it becomes a base."""

from __future__ import annotations

import argparse
import gzip
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from food_database.manifest import verify_manifest
from food_database.snapshots import SNAPSHOT_TAG
from food_database.validation import validate_database


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--gzip", dest="gzip_path", type=Path, required=True)
    args = parser.parse_args()
    match = SNAPSHOT_TAG.fullmatch(args.tag)
    if match is None:
        raise SystemExit(f"invalid snapshot tag: {args.tag}")
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    if manifest.get("created_epoch") != int(match.group(1)):
        raise SystemExit("snapshot tag epoch does not match manifest")
    commit = str(manifest.get("commit_sha", "")).lower()
    if len(commit) != 40 or commit[:12] != match.group(2).lower():
        raise SystemExit("snapshot tag commit provenance does not match manifest")
    with tempfile.TemporaryDirectory(prefix="food-snapshot-") as directory:
        database = Path(directory) / "usda_foods.sqlite"
        with gzip.open(args.gzip_path, "rb") as source, database.open("wb") as target:
            shutil.copyfileobj(source, target)
        errors = verify_manifest(manifest, database, args.gzip_path)
        errors += tuple(validate_database(database, production=True).errors)
    if errors:
        raise SystemExit("invalid promoted snapshot: " + "; ".join(errors))


if __name__ == "__main__":
    main()
