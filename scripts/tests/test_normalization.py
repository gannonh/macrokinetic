import csv
import gzip
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.food_database.normalization import (
    normalize_barcode,
    normalize_off_product,
    normalize_usda_food,
)


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))


def off_product(**overrides):
    product = {
        "code": " 001 234-567 ",
        "product_name": "  Trail Mix  ",
        "brands": " Example Foods ",
        "categories": "Snacks, Nuts",
        "energy-kcal_100g": "450",
        "proteins_100g": "12",
        "carbohydrates_100g": "45",
        "fat_100g": "24",
        "fiber_100g": "8",
        "serving_size": "1 cup",
        "serving_quantity": "120",
    }
    product.update(overrides)
    return product


def off_csv_row():
    row = [""] * 151
    row[0] = " 001 234-567 "
    row[10] = "  Trail Mix  "
    row[18] = " Example Foods "
    row[50] = "1 cup"
    row[51] = "120"
    row[89] = "450"
    row[92] = "24"
    row[129] = "45"
    row[146] = "8"
    row[150] = "12"
    return row


def off_delta_product():
    return {
        "code": "001234567",
        "product_name": "Trail Mix",
        "brands": "Example Foods",
        "serving_size": "1 cup",
        "serving_quantity": "120",
        "nutriments": {
            "energy-kcal_100g": "450",
            "proteins_100g": "12",
            "carbohydrates_100g": "45",
            "fat_100g": "24",
            "fiber_100g": "8",
        },
    }


def load_off_processor():
    module_path = SCRIPTS_DIR / "process-off-data.py"
    spec = importlib.util.spec_from_file_location("process_off_data", module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class NormalizationTests(unittest.TestCase):
    def test_normalizes_barcode_identity_without_losing_leading_zeroes(self):
        self.assertEqual(normalize_barcode(" 001 234-567 "), "001234567")

    def test_normalizes_eligible_open_food_facts_product(self):
        record = normalize_off_product(off_product())

        self.assertIsNotNone(record)
        self.assertEqual(record.barcode, "001234567")
        self.assertEqual(record.name, "Trail Mix")
        self.assertEqual(record.brand, "Example Foods")
        self.assertEqual(record.source, "openFoodFacts")
        self.assertEqual(record.calories_per_100g, 450.0)
        self.assertEqual(record.serving_size, 120.0)

    def test_full_csv_and_delta_records_share_the_same_normalized_representation(self):
        self.assertEqual(
            normalize_off_product(off_csv_row()),
            normalize_off_product(off_delta_product()),
        )

    def test_rejects_open_food_facts_product_without_barcode(self):
        self.assertIsNone(normalize_off_product(off_product(code="")))

    def test_rejects_open_food_facts_product_without_eligible_nutrition(self):
        self.assertIsNone(
            normalize_off_product(
                off_product(
                    **{
                        "energy-kcal_100g": "0",
                        "proteins_100g": "1",
                        "carbohydrates_100g": "0",
                        "fat_100g": "0",
                    }
                )
            )
        )

    def test_sanitizes_suspicious_serving_density(self):
        record = normalize_off_product(
            off_product(serving_size="0.25 cup", serving_quantity="10")
        )

        self.assertIsNotNone(record)
        self.assertEqual(record.serving_options, ("100g", "1 serving (10g)"))

    def test_allows_duplicate_display_names_when_barcodes_differ(self):
        first = normalize_off_product(off_product(code="1001"))
        second = normalize_off_product(off_product(code="1002"))

        self.assertIsNotNone(first)
        self.assertIsNotNone(second)
        self.assertEqual(first.name, second.name)
        self.assertNotEqual(first.barcode, second.barcode)

    def test_csv_reader_keeps_same_name_records_with_different_barcodes(self):
        processor = load_off_processor()
        with tempfile.TemporaryDirectory() as directory:
            csv_path = Path(directory) / "products.csv.gz"
            with gzip.open(csv_path, "wt", encoding="utf-8", newline="") as output:
                writer = csv.writer(output, delimiter="\t", lineterminator="\n")
                writer.writerow(["header"] * 151)
                first = off_csv_row()
                first[0] = "0000000000001"
                writer.writerow(first)
                second = off_csv_row()
                second[0] = "0000000000002"
                writer.writerow(second)

            with patch.object(processor, "INPUT_CSV", csv_path):
                products = processor.process_csv()

        self.assertEqual(
            [product["barcode"] for product in products],
            ["0000000000001", "0000000000002"],
        )

    def test_normalizes_usda_nutrients_and_calculates_missing_calories(self):
        food = {
            "fdcId": 123,
            "description": "  Cooked Lentils ",
            "foodCategory": {"description": "Legumes"},
            "foodNutrients": [
                {"nutrient": {"id": 1003}, "amount": 9.0},
                {"nutrient": {"id": 1005}, "amount": 20.0},
                {"nutrient": {"id": 1004}, "amount": 0.4},
            ],
        }

        record = normalize_usda_food(food, "foundation")

        self.assertIsNotNone(record)
        self.assertEqual(record.name, "Cooked Lentils")
        self.assertEqual(record.category, "Legumes")
        self.assertEqual(record.source, "foundation")
        self.assertEqual(record.calories_per_100g, 119.6)
        self.assertEqual(record.barcode, "")

    def test_rejects_usda_food_with_no_name(self):
        self.assertIsNone(normalize_usda_food({"fdcId": 123}, "foundation"))


if __name__ == "__main__":
    unittest.main()
