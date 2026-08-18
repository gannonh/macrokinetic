#!/usr/bin/env python3
"""Create the small deterministic food database used by PR CI.

The production SQLite database is a generated release artifact and is not
stored in Git. This fixture keeps compile, unit, and UI smoke checks fast while
covering the search terms and serving options exercised by those checks.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path

from food_database.schema import create_schema


FOODS = [
    (1001, "", "Chicken breast, roasted", "", "Poultry Products", "foundation", 165, 31, 0, 3.6, 0, 100, "g"),
    (1002, "", "Chicken breast, raw", "", "Poultry Products", "foundation", 120, 23, 0, 2.6, 0, 100, "g"),
    (1003, "", "Chicken thigh, roasted", "", "Poultry Products", "foundation", 209, 26, 0, 10.9, 0, 100, "g"),
    (1004, "", "Soup, chicken noodle", "", "Soups, Sauces, and Gravies", "foundation", 65, 3, 8, 2, 1, 100, "g"),
    (1005, "", "Salmon, Atlantic, raw", "", "Finfish and Shellfish Products", "foundation", 208, 20, 0, 13, 0, 100, "g"),
    (1006, "", "Rice, brown, cooked", "", "Cereal Grains and Pasta", "sr_legacy", 123, 2.7, 25.6, 1, 1.6, 100, "g"),
    (1007, "", "Bananas, raw", "", "Fruits and Fruit Juices", "foundation", 89, 1.1, 22.8, 0.3, 2.6, 118, "g"),
    (1008, "", "Banana, dehydrated, or banana powder, without added sugar", "", "Fruits and Fruit Juices", "foundation", 346, 3.9, 88, 1.8, 9.9, 100, "g"),
    (1009, "", "Apple, raw", "", "Fruits and Fruit Juices", "foundation", 52, 0.3, 13.8, 0.2, 2.4, 100, "g"),
    (1010, "", "Apples, raw", "", "Fruits and Fruit Juices", "foundation", 52, 0.3, 13.8, 0.2, 2.4, 100, "g"),
    (1011, "", "Egg, whole, raw", "", "Dairy and Egg Products", "foundation", 143, 12.6, 0.7, 9.5, 0, 50, "g"),
    (1012, "", "Bagel, egg", "", "Baked Products", "foundation", 250, 10, 49, 2, 2, 100, "g"),
    (1013, "", "Bread, whole-wheat", "", "Baked Products", "foundation", 247, 13, 41, 4.2, 7, 100, "g"),
    (1014, "", "Greek yogurt, plain", "", "Dairy and Egg Products", "foundation", 97, 9, 3.9, 5, 0, 170, "g"),
    (1015, "", "Tomatoes, red, ripe, raw", "", "Vegetables and Vegetable Products", "foundation", 18, 0.9, 3.9, 0.2, 1.2, 100, "g"),
    (1016, "", "Cucumber, with peel", "", "Vegetables and Vegetable Products", "foundation", 15, 0.7, 3.6, 0.1, 0.5, 100, "g"),
    (1017, "", "Pizza, cheese", "", "Fast Foods", "foundation", 266, 11, 33, 10, 2, 100, "g"),
    (1018, "", "Banana chips", "Example Foods", "Snacks", "openFoodFacts", 519, 2.3, 58, 33, 7, 30, "g"),
    (1019, "", "Banana flavored yogurt", "Example Foods", "Dairy", "openFoodFacts", 95, 4, 16, 2, 0, 150, "g"),
    (1020, "", "Chicken burger", "Example Foods", "Prepared Foods", "openFoodFacts", 220, 15, 20, 8, 1, 100, "g"),
    (1021, "", "Bread loaf", "Example Foods", "Baked Products", "openFoodFacts", 250, 9, 45, 3, 3, 100, "g"),
    (1022, "", "APPLEBEE'S sauce", "Example Foods", "Sauces", "openFoodFacts", 120, 1, 20, 4, 0, 30, "g"),
]

SERVING_OPTIONS = json.dumps(["1.0 serving (100g)", "100g"])


def create_database(output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)

    with sqlite3.connect(output) as connection:
        create_schema(connection)
        connection.executemany(
            """
            INSERT INTO foods (
                fdc_id, barcode, name, brand, category, source,
                calories_per_100g, protein_per_100g, carbs_per_100g,
                fat_per_100g, fiber_per_100g, serving_size,
                serving_unit, serving_options
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [(*food, SERVING_OPTIONS) for food in FOODS],
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="Path for the generated SQLite database")
    args = parser.parse_args()
    create_database(args.output)


if __name__ == "__main__":
    main()
