import csv
import gzip
import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

from scripts.food_database.full_build import FullBuildError, build_full_database
from scripts.food_database.validation import validate_database


def usda_food(fdc_id: int, name: str, protein: float = 10) -> dict:
    return {
        "fdcId": fdc_id,
        "description": name,
        "foodCategory": {"description": "Fixture"},
        "foodNutrients": [
            {"nutrient": {"id": 1003}, "amount": protein},
            {"nutrient": {"id": 1005}, "amount": 20},
            {"nutrient": {"id": 1004}, "amount": 2},
        ],
    }


def off_row(code: str, name: str, calories: str = "400") -> list[str]:
    row = [""] * 151
    row[0] = code
    row[10] = name
    row[18] = "Fixture Foods"
    row[50] = "1 bar"
    row[51] = "40"
    row[89] = calories
    row[92] = "20"
    row[129] = "40"
    row[146] = "4"
    row[150] = "8"
    return row


def write_sources(directory: Path) -> tuple[Path, Path, Path]:
    foundation = directory / "foundation.json"
    sr_legacy = directory / "sr_legacy.json"
    off_csv = directory / "products.csv.gz"
    foundation.write_text(
        json.dumps({"FoundationFoods": [usda_food(1, "Chicken fixture")]})
    )
    sr_legacy.write_text(
        json.dumps({"SRLegacyFoods": [usda_food(2, "Rice fixture", 3)]})
    )
    with gzip.open(off_csv, "wt", encoding="utf-8", newline="") as output:
        writer = csv.writer(output, delimiter="\t", lineterminator="\n")
        writer.writerow(["header"] * 151)
        writer.writerow(off_row("0001", "Cookie fixture"))
        writer.writerow(off_row("0002", "Cookie fixture", "410"))
        writer.writerow(off_row("0001", "Duplicate barcode should be ignored", "999"))
    return foundation, sr_legacy, off_csv


class FullBuildTests(unittest.TestCase):
    def test_build_streams_sources_and_publishes_an_atomic_valid_database(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            foundation, sr_legacy, off_csv = write_sources(root)
            output = root / "foods.sqlite"

            result = build_full_database(
                output,
                foundation_json=foundation,
                sr_legacy_json=sr_legacy,
                off_csv_gzip=off_csv,
                off_cursor=123,
            )
            validation = validate_database(
                output,
                required_searches={"chicken": 1, "cookie": 2},
            )
            with closing(sqlite3.connect(output)) as connection:
                rows = connection.execute(
                    "SELECT barcode, name, calories_per_100g FROM foods WHERE source = 'openFoodFacts' ORDER BY barcode"
                ).fetchall()

        self.assertTrue(validation.ok, validation.errors)
        self.assertEqual(result.off_cursor, 123)
        self.assertEqual(result.rows_by_source, {"foundation": 1, "sr_legacy": 1, "openFoodFacts": 2})
        self.assertEqual(
            rows,
            [("0001", "Cookie fixture", 400.0), ("0002", "Cookie fixture", 410.0)],
        )

    def test_missing_authoritative_cursor_is_rejected_before_publishing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            foundation, sr_legacy, off_csv = write_sources(root)
            output = root / "foods.sqlite"

            with self.assertRaises(FullBuildError):
                build_full_database(
                    output,
                    foundation_json=foundation,
                    sr_legacy_json=sr_legacy,
                    off_csv_gzip=off_csv,
                    off_cursor=None,
                )

        self.assertFalse(output.exists())

    def test_malformed_source_does_not_publish_partial_candidate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            foundation, _, off_csv = write_sources(root)
            malformed_sr = root / "sr-legacy.json"
            malformed_sr.write_text("not json")
            output = root / "foods.sqlite"

            with self.assertRaises(FullBuildError):
                build_full_database(
                    output,
                    foundation_json=foundation,
                    sr_legacy_json=malformed_sr,
                    off_csv_gzip=off_csv,
                    off_cursor=123,
                )

        self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
