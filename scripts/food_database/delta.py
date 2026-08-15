"""Open Food Facts delta discovery and transactional application."""

from __future__ import annotations

import gzip
import json
import re
import sqlite3
from collections.abc import Mapping, Sequence
from contextlib import closing
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .normalization import normalize_barcode, normalize_off_product


DELTA_FILENAME = re.compile(r"^openfoodfacts_products_(\d+)_(\d+)\.json\.gz$")


class DeltaPayloadError(ValueError):
    """Raised when a delta file cannot be safely applied."""


@dataclass(frozen=True)
class DeltaInterval:
    start: int
    end: int
    filename: str


@dataclass(frozen=True)
class DeltaSelection:
    mode: str
    intervals: tuple[DeltaInterval, ...]
    cursor: int
    reason: str | None = None


def parse_delta_filename(filename: str) -> DeltaInterval | None:
    match = DELTA_FILENAME.fullmatch(Path(filename).name)
    if match is None:
        return None
    start, end = int(match.group(1)), int(match.group(2))
    if start >= end:
        return None
    return DeltaInterval(start, end, Path(filename).name)


def select_delta_chain(index_text: str, *, cursor: int) -> DeltaSelection:
    """Select a contiguous chain or explicitly request a full rebuild."""
    intervals: list[DeltaInterval] = []
    for raw_line in index_text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        token = next(
            (part.strip(",") for part in line.split() if "openfoodfacts_products_" in part),
            None,
        )
        if token is None:
            continue
        interval = parse_delta_filename(token)
        if interval is None:
            return _full_selection(cursor, f"Malformed delta filename: {token}")
        intervals.append(interval)

    if cursor < 0:
        return _full_selection(cursor, "Snapshot cursor is negative")
    if not intervals:
        return _full_selection(cursor, "Delta index contains no usable intervals")

    intervals.sort(key=lambda interval: (interval.start, interval.end, interval.filename))
    max_end = max(interval.end for interval in intervals)
    if cursor > max_end:
        return _full_selection(cursor, "Snapshot cursor is newer than the delta index")

    crossing = [
        interval
        for interval in intervals
        if interval.start < cursor < interval.end
    ]
    if crossing:
        return _full_selection(cursor, "Snapshot cursor falls inside a delta interval")

    if cursor == max_end:
        return DeltaSelection("delta", (), cursor, "Snapshot is current")

    selected: list[DeltaInterval] = []
    current = cursor
    while current < max_end:
        candidates = [interval for interval in intervals if interval.start == current]
        if len(candidates) > 1:
            return _full_selection(cursor, "Overlapping delta intervals share a start")
        if not candidates:
            return _full_selection(cursor, "Gap in delta chain after snapshot cursor")

        interval = candidates[0]
        for other in intervals:
            if other == interval:
                continue
            if other.start < interval.end and other.end > interval.start:
                return _full_selection(cursor, "Overlapping delta intervals detected")
        selected.append(interval)
        current = interval.end

    return DeltaSelection("delta", tuple(selected), current)


def apply_delta_chain(
    database_path: str | Path,
    delta_files: Sequence[tuple[DeltaInterval | int, str | Path]],
    *,
    cursor: int,
) -> int:
    """Apply a verified chain atomically and return its advanced cursor."""
    current_cursor = cursor
    intervals_and_paths = [
        (_coerce_interval(interval_or_start, path), Path(path))
        for interval_or_start, path in delta_files
    ]

    with closing(sqlite3.connect(database_path)) as connection, connection:
        connection.execute("BEGIN")
        next_id = _next_off_id(connection)
        for interval, path in intervals_and_paths:
            if interval.start != current_cursor:
                raise DeltaPayloadError(
                    f"Delta {interval.filename} starts at {interval.start}, expected {current_cursor}"
                )
            products = _load_products(path)
            for product in products:
                barcode = normalize_barcode(product.get("code", product.get("barcode", "")))
                if not barcode:
                    raise DeltaPayloadError(
                        f"Delta {interval.filename} contains a product without a valid barcode"
                    )

                existing = connection.execute(
                    """
                    SELECT fdc_id FROM foods
                    WHERE source = 'openFoodFacts' AND barcode = ?
                    ORDER BY fdc_id
                    LIMIT 1
                    """,
                    (barcode,),
                ).fetchone()
                connection.execute(
                    "DELETE FROM foods WHERE source = 'openFoodFacts' AND barcode = ?",
                    (barcode,),
                )

                record = normalize_off_product(product)
                if record is None:
                    continue
                row = record.to_database_row()
                row["fdc_id"] = existing[0] if existing is not None else next_id
                if existing is None:
                    next_id += 1
                connection.execute(
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
                    row,
                )
            current_cursor = interval.end

    return current_cursor


def _full_selection(cursor: int, reason: str) -> DeltaSelection:
    return DeltaSelection("full", (), cursor, reason)


def _coerce_interval(
    interval_or_start: DeltaInterval | int,
    path: str | Path,
) -> DeltaInterval:
    if isinstance(interval_or_start, DeltaInterval):
        return interval_or_start
    parsed = parse_delta_filename(Path(path).name)
    if parsed is None or parsed.start != interval_or_start:
        raise DeltaPayloadError(f"Invalid delta filename: {path}")
    return parsed


def _load_products(path: Path) -> list[Mapping[str, Any]]:
    try:
        with gzip.open(path, "rt", encoding="utf-8") as source:
            payload = json.load(source)
    except (OSError, json.JSONDecodeError) as error:
        raise DeltaPayloadError(f"Malformed delta payload: {path}") from error

    if isinstance(payload, list):
        products = payload
    elif isinstance(payload, Mapping) and isinstance(payload.get("products"), list):
        products = payload["products"]
    elif isinstance(payload, Mapping) and isinstance(payload.get("product"), Mapping):
        products = [payload["product"]]
    else:
        raise DeltaPayloadError(f"Malformed delta payload shape: {path}")

    if any(not isinstance(product, Mapping) for product in products):
        raise DeltaPayloadError(f"Malformed product in delta payload: {path}")
    return products


def _next_off_id(connection: sqlite3.Connection) -> int:
    maximum = connection.execute(
        "SELECT MAX(fdc_id) FROM foods WHERE source = 'openFoodFacts'"
    ).fetchone()[0]
    return max((maximum or 0) + 1, 2_000_000)
