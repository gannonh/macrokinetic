"""Normalize USDA and Open Food Facts records into the app's food schema.

The full and delta readers use this module as their shared boundary.  Source
readers may have different input shapes, but an eligible record emitted here
has one stable representation before it reaches SQLite.
"""

from __future__ import annotations

import json
import math
import re
import unicodedata
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any


USDA_SOURCES = frozenset({"foundation", "sr_legacy"})
OFF_SOURCE = "openFoodFacts"

SUSPICIOUS_UNIT_RATIOS = {
    "cup": (80, 300),
    "tbsp": (5, 25),
    "tsp": (2, 10),
    "tablespoon": (5, 25),
    "teaspoon": (2, 10),
}

OFF_CSV_COLUMNS = {
    "code": 0,
    "product_name": 10,
    "brands": 18,
    "serving_size": 50,
    "serving_quantity": 51,
    "energy_kcal_100g": 89,
    "fat_100g": 92,
    "carbohydrates_100g": 129,
    "fiber_100g": 146,
    "proteins_100g": 150,
}

NUTRIENT_IDS = {
    1008: "calories_per_100g",
    1003: "protein_per_100g",
    1005: "carbs_per_100g",
    1004: "fat_per_100g",
    1079: "fiber_per_100g",
}

NUTRIENT_NAMES = {
    "energy": "calories_per_100g",
    "energy (kcal)": "calories_per_100g",
    "energy, kcal": "calories_per_100g",
    "protein": "protein_per_100g",
    "carbohydrate, by difference": "carbs_per_100g",
    "carbohydrate": "carbs_per_100g",
    "total lipid (fat)": "fat_per_100g",
    "total fat": "fat_per_100g",
    "fiber, total dietary": "fiber_per_100g",
    "dietary fiber": "fiber_per_100g",
}


@dataclass(frozen=True)
class FoodRecord:
    """Canonical representation matching the bundled SQLite foods table."""

    fdc_id: int
    barcode: str
    name: str
    brand: str
    category: str
    source: str
    calories_per_100g: float
    protein_per_100g: float
    carbs_per_100g: float
    fat_per_100g: float
    fiber_per_100g: float
    serving_size: float
    serving_unit: str
    serving_options: tuple[str, ...]

    def to_database_row(self) -> dict[str, Any]:
        """Return values ready for the existing SQLite insert statement."""
        return {
            "fdc_id": self.fdc_id,
            "barcode": self.barcode,
            "name": self.name,
            "brand": self.brand,
            "category": self.category,
            "source": self.source,
            "calories_per_100g": self.calories_per_100g,
            "protein_per_100g": self.protein_per_100g,
            "carbs_per_100g": self.carbs_per_100g,
            "fat_per_100g": self.fat_per_100g,
            "fiber_per_100g": self.fiber_per_100g,
            "serving_size": self.serving_size,
            "serving_unit": self.serving_unit,
            "serving_options": json.dumps(list(self.serving_options), separators=(",", ":")),
        }


def normalize_text(value: Any) -> str:
    """Normalize user-visible source text without changing its meaning."""
    if value is None:
        return ""
    normalized = unicodedata.normalize("NFKC", str(value)).replace("\u00a0", " ")
    return " ".join(normalized.split())


def normalize_barcode(value: Any) -> str:
    """Return a stable numeric OFF identity, preserving leading zeroes."""
    normalized = normalize_text(value)
    normalized = re.sub(r"[\s-]+", "", normalized)
    if not normalized or not normalized.isdigit():
        return ""
    return normalized


def normalize_off_product(
    product: Mapping[str, Any] | Sequence[Any],
) -> FoodRecord | None:
    """Normalize one Open Food Facts product, or return ``None`` if ineligible."""
    fields = _off_fields(product)
    if fields is None:
        return None

    barcode = normalize_barcode(fields["barcode"])
    name = normalize_text(fields["name"])
    if not barcode or not _valid_name(name):
        return None

    nutriments = fields["nutriments"]
    nutrient_values = nutriments if isinstance(nutriments, Mapping) and nutriments else fields
    nutrients = {
        "calories_per_100g": _first_float(
            nutrient_values,
            "energy-kcal_100g",
            "energy-kcal",
            "energy_100g",
        ),
        "protein_per_100g": _first_float(
            nutrient_values, "proteins_100g", "protein_100g", "proteins"
        ),
        "carbs_per_100g": _first_float(
            nutrient_values,
            "carbohydrates_100g",
            "carbohydrate_100g",
            "carbohydrates",
        ),
        "fat_per_100g": _first_float(
            nutrient_values, "fat_100g", "fats_100g", "fat"
        ),
        "fiber_per_100g": _first_float(
            nutrient_values, "fiber_100g", "fibers_100g", "fiber"
        ),
    }
    if not has_valid_nutrition(nutrients):
        return None

    calories = nutrients["calories_per_100g"]
    if calories == 0.0:
        calories = _calories_from_macros(nutrients)

    serving_size = _first_float(fields, "serving_quantity", "serving_size")
    if serving_size <= 0:
        serving_size = 100.0

    serving_options = tuple(
        _off_serving_options(fields["serving_size"], serving_size)
    )

    return FoodRecord(
        fdc_id=0,
        barcode=barcode,
        name=name,
        brand=normalize_text(fields["brand"]),
        category=normalize_text(fields["category"]),
        source=OFF_SOURCE,
        calories_per_100g=calories,
        protein_per_100g=nutrients["protein_per_100g"],
        carbs_per_100g=nutrients["carbs_per_100g"],
        fat_per_100g=nutrients["fat_per_100g"],
        fiber_per_100g=nutrients["fiber_per_100g"],
        serving_size=serving_size,
        serving_unit="g",
        serving_options=serving_options,
    )


def normalize_usda_food(food: Mapping[str, Any], source: str) -> FoodRecord | None:
    """Normalize one USDA Foundation or SR Legacy food."""
    if source not in USDA_SOURCES:
        raise ValueError(f"Unsupported USDA source: {source}")

    name = normalize_text(food.get("description", ""))
    if not _valid_name(name):
        return None

    nutrients = _usda_nutrients(food.get("foodNutrients", []))
    if nutrients["calories_per_100g"] == 0.0:
        nutrients["calories_per_100g"] = _calories_from_macros(nutrients)

    serving_size, serving_options = _usda_serving_info(food.get("foodPortions", []))
    fdc_id = _positive_int(food.get("fdcId"))

    category = food.get("foodCategory", "")
    if isinstance(category, Mapping):
        category = category.get("description", "")

    return FoodRecord(
        fdc_id=fdc_id,
        barcode="",
        name=name,
        brand="",
        category=normalize_text(category),
        source=source,
        calories_per_100g=nutrients["calories_per_100g"],
        protein_per_100g=nutrients["protein_per_100g"],
        carbs_per_100g=nutrients["carbs_per_100g"],
        fat_per_100g=nutrients["fat_per_100g"],
        fiber_per_100g=nutrients["fiber_per_100g"],
        serving_size=serving_size,
        serving_unit="g",
        serving_options=serving_options,
    )


def has_valid_nutrition(nutrients: Mapping[str, float]) -> bool:
    """Return whether a product has calories or two positive macros."""
    if nutrients.get("calories_per_100g", 0.0) > 0:
        return True
    macro_keys = ("protein_per_100g", "carbs_per_100g", "fat_per_100g")
    return sum(nutrients.get(key, 0.0) > 0 for key in macro_keys) >= 2


def _valid_name(name: str) -> bool:
    return 2 <= len(name) <= 200


def _off_fields(
    product: Mapping[str, Any] | Sequence[Any],
) -> dict[str, Any] | None:
    if isinstance(product, Mapping):
        nutriments = product.get("nutriments", {})
        if not isinstance(nutriments, Mapping):
            nutriments = {}
        return {
            "barcode": product.get("code", product.get("barcode", "")),
            "name": product.get(
                "product_name",
                product.get("product_name_en", product.get("name", "")),
            ),
            "brand": product.get("brands", product.get("brand", "")),
            "category": product.get(
                "categories_en",
                product.get("categories", product.get("category", "")),
            ),
            "serving_size": product.get("serving_size", ""),
            "serving_quantity": product.get("serving_quantity", ""),
            "energy-kcal_100g": product.get("energy-kcal_100g", ""),
            "proteins_100g": product.get("proteins_100g", ""),
            "carbohydrates_100g": product.get("carbohydrates_100g", ""),
            "fat_100g": product.get("fat_100g", ""),
            "fiber_100g": product.get("fiber_100g", ""),
            "nutriments": nutriments,
        }

    if isinstance(product, Sequence) and not isinstance(product, (str, bytes, bytearray)):
        try:
            return {
                "barcode": product[OFF_CSV_COLUMNS["code"]],
                "name": product[OFF_CSV_COLUMNS["product_name"]],
                "brand": product[OFF_CSV_COLUMNS["brands"]],
                "category": "",
                "serving_size": product[OFF_CSV_COLUMNS["serving_size"]],
                "serving_quantity": product[OFF_CSV_COLUMNS["serving_quantity"]],
                "energy-kcal_100g": product[OFF_CSV_COLUMNS["energy_kcal_100g"]],
                "proteins_100g": product[OFF_CSV_COLUMNS["proteins_100g"]],
                "carbohydrates_100g": product[OFF_CSV_COLUMNS["carbohydrates_100g"]],
                "fat_100g": product[OFF_CSV_COLUMNS["fat_100g"]],
                "fiber_100g": product[OFF_CSV_COLUMNS["fiber_100g"]],
                "nutriments": {},
            }
        except IndexError:
            return None

    return None


def _first_float(values: Mapping[str, Any], *keys: str) -> float:
    for key in keys:
        if key in values:
            return _safe_float(values[key])
    return 0.0


def _safe_float(value: Any) -> float:
    if isinstance(value, bool):
        return 0.0
    try:
        parsed = float(value)
    except (TypeError, ValueError):
        return 0.0
    if not math.isfinite(parsed) or parsed < 0:
        return 0.0
    return parsed


def _positive_int(value: Any) -> int:
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return 0
    return parsed if parsed > 0 else 0


def _calories_from_macros(nutrients: Mapping[str, float]) -> float:
    calculated = (
        nutrients.get("protein_per_100g", 0.0) * 4.0
        + nutrients.get("carbs_per_100g", 0.0) * 4.0
        + nutrients.get("fat_per_100g", 0.0) * 9.0
    )
    return round(calculated, 1) if calculated > 0 else 0.0


def _usda_nutrients(food_nutrients: Any) -> dict[str, float]:
    nutrients = {
        "calories_per_100g": 0.0,
        "protein_per_100g": 0.0,
        "carbs_per_100g": 0.0,
        "fat_per_100g": 0.0,
        "fiber_per_100g": 0.0,
    }
    if not isinstance(food_nutrients, Sequence) or isinstance(food_nutrients, (str, bytes)):
        return nutrients

    for entry in food_nutrients:
        if not isinstance(entry, Mapping):
            continue
        nutrient = entry.get("nutrient", entry)
        if not isinstance(nutrient, Mapping):
            continue
        nutrient_id = _positive_int(nutrient.get("id"))
        field = NUTRIENT_IDS.get(nutrient_id)
        if field is None:
            nutrient_name = normalize_text(
                nutrient.get("name", nutrient.get("nutrientName", ""))
            ).lower()
            field = NUTRIENT_NAMES.get(nutrient_name)
        if field:
            nutrients[field] = _safe_float(entry.get("amount", entry.get("value", 0)))
    return nutrients


def _usda_serving_info(food_portions: Any) -> tuple[float, tuple[str, ...]]:
    serving_size = 100.0
    options: list[str] = ["100g"]
    if not isinstance(food_portions, Sequence) or isinstance(food_portions, (str, bytes)):
        return serving_size, tuple(options)

    for portion in food_portions:
        if not isinstance(portion, Mapping):
            continue
        gram_weight = _safe_float(portion.get("gramWeight", 0))
        if gram_weight <= 0:
            continue
        amount = normalize_text(portion.get("amount", "1")) or "1"
        modifier = normalize_text(portion.get("modifier", ""))
        label = f"{amount} {modifier}".strip() if modifier else ""
        option = f"{label} ({_format_quantity(gram_weight)}g)" if label else f"{_format_quantity(gram_weight)}g"
        if option not in options:
            options.append(option)
        if serving_size == 100.0 and 10 < gram_weight < 500:
            serving_size = gram_weight
        if len(options) == 5:
            break
    return serving_size, tuple(options)


def _off_serving_options(serving_size: Any, serving_quantity: float) -> list[str]:
    label = normalize_text(serving_size)
    options = ["100g"]
    if not label or serving_quantity <= 0 or serving_quantity == 100.0:
        return options

    base = re.sub(r"\([^)]*\)", "", label).strip().lower()
    compact = base.replace(",", ".").replace(" ", "")
    is_just_weight = (
        not compact
        or (compact.endswith("g") and compact[:-1].replace(".", "").isdigit())
        or (compact.endswith("mg") and compact[:-2].replace(".", "").isdigit())
        or (compact.endswith("ml") and compact[:-2].replace(".", "").isdigit())
        or (compact.endswith("l") and compact[:-1].replace(".", "").isdigit())
        or (compact.endswith("oz") and compact[:-2].replace(".", "").isdigit())
        or (compact.endswith("gram") and compact[:-4].replace(".", "").isdigit())
        or (compact.endswith("grams") and compact[:-5].replace(".", "").isdigit())
        or (compact.endswith("grm") and compact[:-3].replace(".", "").isdigit())
        or compact.replace(".", "").isdigit()
    )
    if is_just_weight or _is_suspicious_serving(label, serving_quantity):
        options.append(f"1 serving ({_format_quantity(serving_quantity)}g)")
    else:
        options.append(f"{label} ({_format_quantity(serving_quantity)}g)")
    return options


def _is_suspicious_serving(serving_size: str, serving_grams: float) -> bool:
    quantity = _serving_quantity_prefix(serving_size)
    lower_size = serving_size.lower()
    for unit, (minimum, maximum) in SUSPICIOUS_UNIT_RATIOS.items():
        if unit in lower_size and not (
            minimum * quantity <= serving_grams <= maximum * quantity
        ):
            return True
    return False


def _serving_quantity_prefix(serving_size: str) -> float:
    decimal_match = re.match(r"^(\d+\.?\d*)\s", serving_size.strip())
    if decimal_match:
        return _safe_float(decimal_match.group(1)) or 1.0

    fraction_match = re.match(r"^(\d+)/(\d+)\s", serving_size.strip())
    if fraction_match:
        denominator = _safe_float(fraction_match.group(2))
        if denominator:
            return _safe_float(fraction_match.group(1)) / denominator
    return 1.0


def _format_quantity(value: float) -> str:
    return str(int(value)) if value.is_integer() else f"{value:g}"
