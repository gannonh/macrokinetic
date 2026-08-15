#!/usr/bin/env python3
"""Import Open Food Facts products into the app's local SQLite database.

The source reader delegates all product identity, eligibility, and field
normalization to ``food_database.normalization`` so a future JSON delta reader
cannot drift from full CSV imports.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import sqlite3
import sys
from pathlib import Path

from food_database.normalization import normalize_off_product


csv.field_size_limit(sys.maxsize)

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
INPUT_CSV = SCRIPT_DIR / "off_data" / "en.openfoodfacts.org.products.csv.gz"
OUTPUT_DB = PROJECT_ROOT / "JabTracker" / "Resources" / "usda_foods.sqlite"

COUNTRIES_COLUMN = 40
MINIMUM_CSV_COLUMNS = 151


def is_us_product(row: list[str]) -> bool:
    """Return whether an OFF CSV row lists the United States as a country."""
    try:
        countries = row[COUNTRIES_COLUMN].lower()
    except IndexError:
        return False
    return "united states" in countries or "usa" in countries or "us" in countries


def parse_row(row: list[str]) -> dict[str, object] | None:
    """Normalize one CSV row into values accepted by the SQLite insert."""
    record = normalize_off_product(row)
    return record.to_database_row() if record is not None else None


def process_csv(limit: int | None = None, us_only: bool = False) -> list[dict[str, object]]:
    """Stream the OFF CSV and return one normalized record per barcode."""
    products: list[dict[str, object]] = []
    seen_barcodes: set[str] = set()

    print(f"Reading {INPUT_CSV}...")
    with gzip.open(INPUT_CSV, "rt", encoding="utf-8", errors="replace") as source:
        reader = csv.reader(source, delimiter="\t")
        header = next(reader)
        print(f"  CSV has {len(header)} columns")

        row_count = 0
        for row in reader:
            row_count += 1
            if limit is not None and row_count > limit:
                break
            if len(row) < MINIMUM_CSV_COLUMNS or (us_only and not is_us_product(row)):
                continue

            product = parse_row(row)
            if product is None:
                continue
            barcode = str(product["barcode"])
            if barcode in seen_barcodes:
                continue
            seen_barcodes.add(barcode)
            products.append(product)

            if row_count % 100_000 == 0:
                print(f"  Processed {row_count:,} rows, found {len(products):,} products...")

    print(f"  Total rows: {row_count:,}")
    print(f"  Valid products: {len(products):,}")
    return products


def add_to_database(products: list[dict[str, object]]) -> tuple[int, int]:
    """Insert normalized products, keyed by OFF barcode rather than display name."""
    if not OUTPUT_DB.exists():
        print(f"Error: Database not found at {OUTPUT_DB}")
        return 0, 0

    with sqlite3.connect(OUTPUT_DB) as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT MAX(fdc_id) FROM foods")
        max_id = cursor.fetchone()[0] or 0
        next_id = max(max_id + 1, 2_000_000)

        cursor.execute(
            "SELECT barcode FROM foods WHERE source = 'openFoodFacts' AND barcode <> ''"
        )
        existing_barcodes = {row[0] for row in cursor.fetchall()}

        added = 0
        skipped = 0
        for product in products:
            barcode = str(product["barcode"])
            if barcode in existing_barcodes:
                skipped += 1
                continue

            cursor.execute(
                """
                INSERT INTO foods (
                    fdc_id, barcode, name, brand, category, source,
                    calories_per_100g, protein_per_100g, carbs_per_100g,
                    fat_per_100g, fiber_per_100g,
                    serving_size, serving_unit, serving_options
                ) VALUES (
                    :fdc_id, :barcode, :name, :brand, :category, :source,
                    :calories_per_100g, :protein_per_100g, :carbs_per_100g,
                    :fat_per_100g, :fiber_per_100g,
                    :serving_size, :serving_unit, :serving_options
                )
                """,
                {**product, "fdc_id": next_id},
            )
            existing_barcodes.add(barcode)
            next_id += 1
            added += 1

        cursor.execute("INSERT INTO foods_fts(foods_fts) VALUES ('rebuild')")
        connection.commit()

    return added, skipped


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--us-only", action="store_true")
    args = parser.parse_args()

    if not INPUT_CSV.exists():
        raise SystemExit(f"CSV not found at {INPUT_CSV}")
    if not OUTPUT_DB.exists():
        raise SystemExit(
            f"Database not found at {OUTPUT_DB}; run update-food-database.sh first"
        )

    products = process_csv(limit=args.limit, us_only=args.us_only)
    added, skipped = add_to_database(products)

    with sqlite3.connect(OUTPUT_DB) as connection:
        cursor = connection.cursor()
        total = cursor.execute("SELECT COUNT(*) FROM foods").fetchone()[0]
        off_count = cursor.execute(
            "SELECT COUNT(*) FROM foods WHERE source = 'openFoodFacts'"
        ).fetchone()[0]

    print(f"Products added: {added:,}")
    print(f"Products skipped: {skipped:,} (existing barcodes)")
    print(f"Open Food Facts: {off_count:,}")
    print(f"Total foods: {total:,}")


if __name__ == "__main__":
    main()
