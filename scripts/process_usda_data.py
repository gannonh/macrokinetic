#!/usr/bin/env python3
"""
USDA Food Data Processor

Converts USDA FoodData Central JSON exports (Foundation Foods + SR Legacy)
into a compact SQLite database with FTS5 full-text search for the JabTracker app.

Usage:
    python3 process_usda_data.py

Output:
    JabTracker/Resources/usda_foods.sqlite
"""

import json
import sqlite3
from pathlib import Path

from food_database.normalization import normalize_usda_food

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = SCRIPT_DIR / "usda_data"
OUTPUT_DIR = PROJECT_ROOT / "JabTracker" / "Resources"
OUTPUT_DB = OUTPUT_DIR / "usda_foods.sqlite"

FOUNDATION_JSON = DATA_DIR / "foundation" / "foundationDownload.json"
SR_LEGACY_JSON = DATA_DIR / "sr_legacy" / "FoodData_Central_sr_legacy_food_json_2018-04.json"


def process_food(food: dict, source: str) -> dict | None:
    """Normalize one USDA food through the shared source boundary."""
    record = normalize_usda_food(food, source)
    return record.to_database_row() if record is not None else None


def create_database(foods: list):
    """Create SQLite database with FTS5 full-text search."""
    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Remove existing database
    if OUTPUT_DB.exists():
        OUTPUT_DB.unlink()

    conn = sqlite3.connect(OUTPUT_DB)
    cursor = conn.cursor()

    # Create main foods table
    # Column names match what LocalFoodDatabase.swift expects
    cursor.execute("""
        CREATE TABLE foods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fdc_id INTEGER NOT NULL,
            barcode TEXT DEFAULT '',
            name TEXT NOT NULL,
            brand TEXT DEFAULT '',
            category TEXT DEFAULT '',
            source TEXT DEFAULT '',
            calories_per_100g REAL DEFAULT 0,
            protein_per_100g REAL DEFAULT 0,
            carbs_per_100g REAL DEFAULT 0,
            fat_per_100g REAL DEFAULT 0,
            fiber_per_100g REAL DEFAULT 0,
            serving_size REAL DEFAULT 100,
            serving_unit TEXT DEFAULT 'g',
            serving_options TEXT DEFAULT '[]'
        )
    """)

    # Create FTS5 virtual table for full-text search
    cursor.execute("""
        CREATE VIRTUAL TABLE foods_fts USING fts5(
            name,
            category,
            content=foods,
            content_rowid=rowid
        )
    """)

    # Create triggers to keep FTS in sync
    cursor.execute("""
        CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
            INSERT INTO foods_fts(rowid, name, category)
            VALUES (new.rowid, new.name, new.category);
        END
    """)

    cursor.execute("""
        CREATE TRIGGER foods_ad AFTER DELETE ON foods BEGIN
            INSERT INTO foods_fts(foods_fts, rowid, name, category)
            VALUES ('delete', old.rowid, old.name, old.category);
        END
    """)

    cursor.execute("""
        CREATE TRIGGER foods_au AFTER UPDATE ON foods BEGIN
            INSERT INTO foods_fts(foods_fts, rowid, name, category)
            VALUES ('delete', old.rowid, old.name, old.category);
            INSERT INTO foods_fts(rowid, name, category)
            VALUES (new.rowid, new.name, new.category);
        END
    """)

    # Insert foods
    cursor.executemany("""
        INSERT INTO foods (
            fdc_id, barcode, name, brand, category, source,
            calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g,
            serving_size, serving_unit, serving_options
        ) VALUES (
            :fdc_id, :barcode, :name, :brand, :category, :source,
            :calories_per_100g, :protein_per_100g, :carbs_per_100g, :fat_per_100g, :fiber_per_100g,
            :serving_size, :serving_unit, :serving_options
        )
    """, foods)

    # Create indexes for common queries
    cursor.execute("CREATE INDEX idx_foods_fdc_id ON foods(fdc_id)")
    cursor.execute("CREATE INDEX idx_foods_barcode ON foods(barcode)")
    cursor.execute("CREATE INDEX idx_foods_name ON foods(name)")
    cursor.execute("CREATE INDEX idx_foods_category ON foods(category)")
    cursor.execute("CREATE INDEX idx_foods_calories ON foods(calories_per_100g)")
    cursor.execute(
        """
        CREATE UNIQUE INDEX idx_foods_off_barcode
        ON foods(barcode)
        WHERE source = 'openFoodFacts' AND barcode <> ''
        """
    )

    conn.commit()

    # Optimize FTS index
    cursor.execute("INSERT INTO foods_fts(foods_fts) VALUES ('optimize')")
    conn.commit()

    # Vacuum to minimize file size
    cursor.execute("VACUUM")
    conn.commit()

    conn.close()


def main():
    print("USDA Food Data Processor")
    print("=" * 50)

    all_foods = []

    # Process Foundation Foods
    print(f"\nLoading Foundation Foods from {FOUNDATION_JSON}...")
    with open(FOUNDATION_JSON, "r") as f:
        data = json.load(f)

    foundation_foods = data.get("FoundationFoods", [])
    print(f"  Found {len(foundation_foods)} foods")

    for food in foundation_foods:
        processed = process_food(food, "foundation")
        if processed is not None:
            all_foods.append(processed)

    print(f"  Processed {len([f for f in all_foods if f['source'] == 'foundation'])} foods")

    # Process SR Legacy
    print(f"\nLoading SR Legacy from {SR_LEGACY_JSON}...")
    with open(SR_LEGACY_JSON, "r") as f:
        data = json.load(f)

    sr_foods = data.get("SRLegacyFoods", [])
    print(f"  Found {len(sr_foods)} foods")

    for food in sr_foods:
        processed = process_food(food, "sr_legacy")
        if processed is not None:
            all_foods.append(processed)

    print(f"  Processed {len([f for f in all_foods if f['source'] == 'sr_legacy'])} foods")

    # Remove duplicates by FDC ID
    seen_ids = set()
    unique_foods = []
    for food in all_foods:
        if food["fdc_id"] not in seen_ids:
            seen_ids.add(food["fdc_id"])
            unique_foods.append(food)

    print(f"\nTotal unique foods: {len(unique_foods)}")

    # Create database
    print(f"\nCreating SQLite database at {OUTPUT_DB}...")
    create_database(unique_foods)

    # Report stats
    db_size = OUTPUT_DB.stat().st_size
    print(f"\nDatabase created successfully!")
    print(f"  Size: {db_size / 1024 / 1024:.2f} MB")
    print(f"  Foods: {len(unique_foods)}")

    # Test a sample query
    print("\nTesting FTS search for 'chicken'...")
    conn = sqlite3.connect(OUTPUT_DB)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT f.fdc_id, f.name, f.calories_per_100g, f.protein_per_100g
        FROM foods f
        JOIN foods_fts fts ON f.id = fts.rowid
        WHERE foods_fts MATCH 'chicken'
        ORDER BY f.calories_per_100g DESC
        LIMIT 5
    """)
    results = cursor.fetchall()
    print(f"  Found {len(results)} results:")
    for row in results:
        print(f"    - {row[1]}: {row[2]} cal, {row[3]}g protein")
    conn.close()

    print("\nDone!")


if __name__ == "__main__":
    main()
