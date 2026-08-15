import gzip
import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

from scripts.food_database.delta import (
    DeltaPayloadError,
    apply_delta_chain,
    select_delta_chain,
)
from scripts.food_database.validation import validate_database
from scripts.tests.test_validation import create_fixture_database


def write_delta(path: Path, products: object) -> None:
    with gzip.open(path, "wt", encoding="utf-8") as output:
        json.dump(products, output)


def valid_product(code: str, name: str, calories: str = "450") -> dict:
    return {
        "code": code,
        "product_name": name,
        "brands": "Example Foods",
        "serving_size": "1 serving",
        "serving_quantity": "30",
        "nutriments": {
            "energy-kcal_100g": calories,
            "proteins_100g": "6",
            "carbohydrates_100g": "60",
            "fat_100g": "20",
            "fiber_100g": "3",
        },
    }


class DeltaTests(unittest.TestCase):
    def test_selects_contiguous_intervals_from_snapshot_cursor(self):
        selection = select_delta_chain(
            "\n".join(
                [
                    "openfoodfacts_products_100_200.json.gz",
                    "openfoodfacts_products_200_300.json.gz",
                ]
            ),
            cursor=100,
        )

        self.assertEqual(selection.mode, "delta")
        self.assertEqual(selection.cursor, 300)
        self.assertEqual(
            [interval.filename for interval in selection.intervals],
            [
                "openfoodfacts_products_100_200.json.gz",
                "openfoodfacts_products_200_300.json.gz",
            ],
        )

    def test_selects_full_rebuild_for_gap_overlap_malformed_or_newer_cursor(self):
        cases = [
            ("openfoodfacts_products_100_200.json.gz\nopenfoodfacts_products_300_400.json.gz", 100),
            ("openfoodfacts_products_100_200.json.gz\nopenfoodfacts_products_150_250.json.gz", 100),
            ("openfoodfacts_products_bad.json.gz", 100),
            ("openfoodfacts_products_100_200.json.gz", 300),
        ]

        for index_text, cursor in cases:
            with self.subTest(index_text=index_text, cursor=cursor):
                selection = select_delta_chain(index_text, cursor=cursor)
                self.assertEqual(selection.mode, "full")
                self.assertEqual(selection.cursor, cursor)
                self.assertTrue(selection.reason)

    def test_delta_updates_inserts_and_removes_by_barcode_transactionally(self):
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foods.sqlite"
            delta = Path(directory) / "openfoodfacts_products_100_200.json.gz"
            create_fixture_database(database)
            write_delta(
                delta,
                [
                    valid_product("001", "Updated chocolate cookie", "510"),
                    valid_product("002", "Removed product", "0")
                    | {
                        "nutriments": {
                            "energy-kcal_100g": "0",
                            "proteins_100g": "0",
                            "carbohydrates_100g": "0",
                            "fat_100g": "0",
                        }
                    },
                    valid_product("003", "New granola", "380"),
                ],
            )

            cursor = apply_delta_chain(database, [(100, delta)], cursor=100)
            with closing(sqlite3.connect(database)) as connection:
                rows = connection.execute(
                    """
                    SELECT barcode, name, calories_per_100g
                    FROM foods
                    WHERE source = 'openFoodFacts'
                    ORDER BY barcode
                    """
                ).fetchall()
            validation = validate_database(
                database, required_searches={"cookie": 1, "granola": 1}
            )

        self.assertEqual(cursor, 200)
        self.assertTrue(validation.ok, validation.errors)
        self.assertEqual(
            rows,
            [("001", "Updated chocolate cookie", 510.0), ("003", "New granola", 380.0)],
        )

    def test_malformed_delta_rolls_back_without_partial_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foods.sqlite"
            delta = Path(directory) / "openfoodfacts_products_100_200.json.gz"
            create_fixture_database(database)
            with gzip.open(delta, "wt", encoding="utf-8") as output:
                output.write("not json")

            with self.assertRaises(DeltaPayloadError):
                apply_delta_chain(database, [(100, delta)], cursor=100)

            with closing(sqlite3.connect(database)) as connection:
                count = connection.execute(
                    "SELECT COUNT(*) FROM foods WHERE source = 'openFoodFacts'"
                ).fetchone()[0]

        self.assertEqual(count, 2)


if __name__ == "__main__":
    unittest.main()
