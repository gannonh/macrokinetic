"""Reusable food-database pipeline primitives."""

from .normalization import (
    FoodRecord,
    normalize_barcode,
    normalize_off_product,
    normalize_usda_food,
)
from .validation import ValidationResult, validate_database
from .delta import (
    DeltaInterval,
    DeltaPayloadError,
    DeltaSelection,
    apply_delta_chain,
    parse_delta_filename,
    select_delta_chain,
)

__all__ = [
    "FoodRecord",
    "normalize_barcode",
    "normalize_off_product",
    "normalize_usda_food",
    "ValidationResult",
    "validate_database",
    "DeltaInterval",
    "DeltaPayloadError",
    "DeltaSelection",
    "apply_delta_chain",
    "parse_delta_filename",
    "select_delta_chain",
]
