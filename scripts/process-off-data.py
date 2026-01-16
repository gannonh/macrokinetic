#!/usr/bin/env python3
"""
Open Food Facts CSV Processor

Processes the OFF CSV data dump and adds products with complete
nutrition data to the local SQLite database.

Usage:
    python3 process-off-data.py [--limit N] [--us-only]

Options:
    --limit N    Only process first N products (for testing)
    --us-only    Only include products sold in United States

Output:
    Updates JabTracker/Resources/usda_foods.sqlite with OFF data
"""

import csv
import gzip
import json
import re
import sqlite3
import sys
from pathlib import Path

# Increase CSV field size limit for large fields in OFF data
csv.field_size_limit(sys.maxsize)

# Suspicious unit ratio validation - min/max gram ranges for volume-based units
# If a serving's gram weight falls outside these ranges, use generic "serving" label
SUSPICIOUS_UNIT_RATIOS = {
    "cup": (80, 300),    # 1 cup should be 80-300g for most foods
    "tbsp": (5, 25),     # 1 tbsp should be 5-25g
    "tsp": (2, 10),      # 1 tsp should be 2-10g
    "tablespoon": (5, 25),
    "teaspoon": (2, 10),
}

# Track suspicious serving labels for monitoring
suspicious_serving_count = 0

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
INPUT_CSV = SCRIPT_DIR / "off_data" / "en.openfoodfacts.org.products.csv.gz"
OUTPUT_DB = PROJECT_ROOT / "JabTracker" / "Resources" / "usda_foods.sqlite"

# Column names we need (0-indexed)
COLUMNS = {
    "code": 0,
    "product_name": 10,
    "brands": 18,
    "countries_en": 40,
    "serving_size": 50,
    "serving_quantity": 51,
    "energy_kcal_100g": 89,
    "fat_100g": 92,
    "carbohydrates_100g": 129,
    "fiber_100g": 146,
    "proteins_100g": 150,
}


def parse_float(value: str) -> float:
    """Parse a float value, returning 0.0 for invalid/empty values."""
    if not value or value.strip() == "":
        return 0.0
    try:
        return float(value)
    except ValueError:
        return 0.0


def is_serving_label_suspicious(serving_size_str: str, serving_grams: float) -> bool:
    """
    Check if a serving label's gram value is unrealistic for its unit type.

    Args:
        serving_size_str: The serving size string (e.g., "1 cup", "2 tbsp")
        serving_grams: The gram weight for this serving

    Returns:
        True if the gram value is suspicious for the detected unit type
    """
    lower_str = serving_size_str.lower()

    for unit, (min_grams, max_grams) in SUSPICIOUS_UNIT_RATIOS.items():
        if unit in lower_str:
            # Adjust ranges based on quantity prefix (e.g., "1/4 cup" = 0.25 * range)
            # For simplicity, we use the base range - most suspicious cases are
            # "1 cup" type entries with wildly wrong gram values
            if serving_grams < min_grams or serving_grams > max_grams:
                return True

    return False


def has_valid_nutrition(row: list) -> bool:
    """Check if a row has at least some valid nutrition data."""
    try:
        calories = parse_float(row[COLUMNS["energy_kcal_100g"]])
        protein = parse_float(row[COLUMNS["proteins_100g"]])
        carbs = parse_float(row[COLUMNS["carbohydrates_100g"]])
        fat = parse_float(row[COLUMNS["fat_100g"]])

        # Must have calories OR at least 2 macros
        if calories > 0:
            return True

        macro_count = sum([protein > 0, carbs > 0, fat > 0])
        return macro_count >= 2
    except (IndexError, ValueError):
        return False


def is_us_product(row: list) -> bool:
    """Check if product is sold in United States."""
    try:
        countries = row[COLUMNS["countries_en"]].lower()
        return "united states" in countries or "usa" in countries or "us" in countries
    except (IndexError, ValueError):
        return False


def parse_row(row: list) -> dict | None:
    """Parse a CSV row into a product dict."""
    try:
        name = row[COLUMNS["product_name"]].strip()
        if not name or len(name) < 2:
            return None

        # Skip if name is too long (likely garbage data)
        if len(name) > 200:
            return None

        barcode = row[COLUMNS["code"]].strip()
        brand = row[COLUMNS["brands"]].strip()

        calories = parse_float(row[COLUMNS["energy_kcal_100g"]])
        protein = parse_float(row[COLUMNS["proteins_100g"]])
        carbs = parse_float(row[COLUMNS["carbohydrates_100g"]])
        fat = parse_float(row[COLUMNS["fat_100g"]])
        fiber = parse_float(row[COLUMNS["fiber_100g"]])

        # Calculate calories from macros if missing
        if calories == 0 and (protein > 0 or carbs > 0 or fat > 0):
            calories = round(protein * 4 + carbs * 4 + fat * 9, 1)

        # Extract serving info
        serving_size_str = row[COLUMNS["serving_size"]].strip()
        serving_quantity = parse_float(row[COLUMNS["serving_quantity"]])

        # Build serving_options JSON array
        serving_options = ["100g"]
        if serving_quantity > 0 and serving_quantity != 100:
            # Check if serving_size_str has meaningful descriptive text
            # Strip parenthetical content and check what remains
            base_str = re.sub(r"\([^)]*\)", "", serving_size_str).strip().lower()

            # Remove common noise patterns
            base_str = base_str.replace(",", ".").replace(" ", "")

            # Check if it's just a weight measurement (meaningless as a serving label)
            # Handle both abbreviated (g, mg) and full word (gram, grams) forms
            is_just_weight = (
                not base_str  # Empty after removing parentheticals
                or (base_str.endswith("g") and base_str[:-1].replace(".", "").isdigit())
                or (base_str.endswith("mg") and base_str[:-2].replace(".", "").isdigit())
                or (base_str.endswith("ml") and base_str[:-2].replace(".", "").isdigit())
                or (base_str.endswith("l") and base_str[:-1].replace(".", "").isdigit())
                or (base_str.endswith("oz") and base_str[:-2].replace(".", "").isdigit())
                or (base_str.endswith("gram") and base_str[:-4].replace(".", "").isdigit())
                or (base_str.endswith("grams") and base_str[:-5].replace(".", "").isdigit())
                or (base_str.endswith("grm") and base_str[:-3].replace(".", "").isdigit())
                or base_str.replace(".", "").isdigit()  # Just a number
            )

            if serving_size_str and not is_just_weight:
                # Has meaningful descriptive text (e.g., "1 bar", "2 cookies", "1 cup")
                # Validate serving label against density thresholds
                if is_serving_label_suspicious(serving_size_str, serving_quantity):
                    # Suspicious - use generic "serving" instead of misleading unit
                    global suspicious_serving_count
                    suspicious_serving_count += 1
                    label = f"1 serving ({serving_quantity:.0f}g)"
                else:
                    label = f"{serving_size_str} ({serving_quantity:.0f}g)"
            else:
                # No meaningful description - use "1 serving (Xg)"
                label = f"1 serving ({serving_quantity:.0f}g)"
            serving_options.append(label)

        return {
            "barcode": barcode,
            "name": name,
            "brand": brand,
            "category": "",
            "source": "openFoodFacts",
            "calories_per_100g": calories,
            "protein_per_100g": protein,
            "carbs_per_100g": carbs,
            "fat_per_100g": fat,
            "fiber_per_100g": fiber,
            "serving_quantity": serving_quantity if serving_quantity > 0 else 100,
            "serving_options": json.dumps(serving_options),
        }
    except (IndexError, ValueError):
        return None


def process_csv(limit: int = None, us_only: bool = False) -> list:
    """Process the CSV file and return list of valid products."""
    products = []
    seen_names = set()

    print(f"Reading {INPUT_CSV}...")

    with gzip.open(INPUT_CSV, "rt", encoding="utf-8", errors="replace") as f:
        reader = csv.reader(f, delimiter="\t")

        # Skip header
        header = next(reader)
        print(f"  CSV has {len(header)} columns")

        row_count = 0
        valid_count = 0

        for row in reader:
            row_count += 1

            if limit and row_count > limit:
                break

            if row_count % 100000 == 0:
                print(f"  Processed {row_count:,} rows, found {valid_count:,} valid products...")

            # Skip if not enough columns
            if len(row) < 151:
                continue

            # Filter by country if requested
            if us_only and not is_us_product(row):
                continue

            # Check nutrition data
            if not has_valid_nutrition(row):
                continue

            # Parse product
            product = parse_row(row)
            if not product:
                continue

            # Deduplicate by lowercase name
            name_key = product["name"].lower()
            if name_key in seen_names:
                continue

            seen_names.add(name_key)
            products.append(product)
            valid_count += 1

    print(f"  Total rows: {row_count:,}")
    print(f"  Valid products: {len(products):,}")

    return products


def add_to_database(products: list) -> tuple:
    """Add products to the SQLite database."""
    if not OUTPUT_DB.exists():
        print(f"Error: Database not found at {OUTPUT_DB}")
        return 0, 0

    conn = sqlite3.connect(OUTPUT_DB)
    cursor = conn.cursor()

    # Get max fdc_id to generate new IDs
    cursor.execute("SELECT MAX(fdc_id) FROM foods")
    max_id = cursor.fetchone()[0] or 0
    next_id = max(max_id + 1, 2000000)  # Start OFF IDs at 2M+

    # Get existing names for deduplication
    cursor.execute("SELECT LOWER(name) FROM foods")
    existing_names = set(row[0] for row in cursor.fetchall())

    print(f"  Existing foods in database: {len(existing_names):,}")

    added = 0
    skipped = 0

    for product in products:
        name_lower = product["name"].lower()

        if name_lower in existing_names:
            skipped += 1
            continue

        cursor.execute("""
            INSERT INTO foods (
                fdc_id, barcode, name, brand, category, source,
                calories_per_100g, protein_per_100g, carbs_per_100g,
                fat_per_100g, fiber_per_100g,
                serving_size, serving_unit, serving_options
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'g', ?)
        """, (
            next_id,
            product["barcode"],
            product["name"],
            product["brand"],
            product["category"],
            product["source"],
            product["calories_per_100g"],
            product["protein_per_100g"],
            product["carbs_per_100g"],
            product["fat_per_100g"],
            product["fiber_per_100g"],
            product["serving_quantity"],
            product["serving_options"],
        ))

        existing_names.add(name_lower)
        next_id += 1
        added += 1

    conn.commit()

    # Rebuild FTS index
    print("  Rebuilding FTS index...")
    cursor.execute("INSERT INTO foods_fts(foods_fts) VALUES ('rebuild')")
    conn.commit()

    # Vacuum to optimize
    print("  Optimizing database...")
    cursor.execute("VACUUM")
    conn.commit()

    conn.close()

    return added, skipped


def main():
    print("Open Food Facts CSV Processor")
    print("=" * 50)

    # Parse arguments
    limit = None
    us_only = False

    for i, arg in enumerate(sys.argv[1:]):
        if arg == "--limit" and i + 2 < len(sys.argv):
            limit = int(sys.argv[i + 2])
        elif arg == "--us-only":
            us_only = True

    if not INPUT_CSV.exists():
        print(f"\nError: CSV not found at {INPUT_CSV}")
        return

    if not OUTPUT_DB.exists():
        print(f"\nError: Database not found at {OUTPUT_DB}")
        print("Run ./scripts/update-food-database.sh first.")
        return

    print(f"\nOptions:")
    print(f"  Limit: {limit or 'None (all rows)'}")
    print(f"  US only: {us_only}")

    # Process CSV
    print(f"\nStep 1: Processing CSV...")
    products = process_csv(limit=limit, us_only=us_only)

    # Add to database
    print(f"\nStep 2: Adding to database...")
    added, skipped = add_to_database(products)

    # Summary
    conn = sqlite3.connect(OUTPUT_DB)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM foods")
    total = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM foods WHERE source = 'openFoodFacts'")
    off_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM foods WHERE source != 'openFoodFacts'")
    usda_count = cursor.fetchone()[0]
    conn.close()

    print("\n" + "=" * 50)
    print("Summary")
    print("=" * 50)
    print(f"  Products added:     {added:,}")
    print(f"  Products skipped:   {skipped:,} (duplicates)")
    print(f"  Suspicious labels:  {suspicious_serving_count:,} (sanitized to 'serving')")
    print(f"  USDA foods:         {usda_count:,}")
    print(f"  Open Food Facts:    {off_count:,}")
    print(f"  Total foods:        {total:,}")
    print(f"  Database size:      {OUTPUT_DB.stat().st_size / 1024 / 1024:.1f} MB")

    print("\nDone!")


if __name__ == "__main__":
    main()
