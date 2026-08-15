#!/usr/bin/env python3
"""Build a complete food database from pinned USDA and OFF source files."""

from __future__ import annotations

import argparse
from pathlib import Path

from food_database.full_build import build_full_database


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--foundation-json", type=Path, required=True)
    parser.add_argument("--sr-legacy-json", type=Path, required=True)
    parser.add_argument("--off-csv-gzip", type=Path, required=True)
    parser.add_argument("--off-cursor", type=int, required=True)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("JabTracker/Resources/usda_foods.sqlite"),
    )
    parser.add_argument("--us-only", action="store_true")
    args = parser.parse_args()

    result = build_full_database(
        args.output,
        foundation_json=args.foundation_json,
        sr_legacy_json=args.sr_legacy_json,
        off_csv_gzip=args.off_csv_gzip,
        off_cursor=args.off_cursor,
        us_only=args.us_only,
    )
    print(f"Database: {result.database_path}")
    print(f"Rows: {result.total_rows:,}")
    print(f"Rows by source: {result.rows_by_source}")
    print(f"Open Food Facts cursor: {result.off_cursor}")


if __name__ == "__main__":
    main()
