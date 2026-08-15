"""Authoritative metadata required to seed a full Open Food Facts rebuild."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping


class FullExportMetadataError(ValueError):
    """Raised when full-export metadata cannot establish a safe cursor."""


@dataclass(frozen=True)
class FullExportMetadata:
    full_export_url: str
    covered_through_delta_end: int
    source_sha256: str


def load_full_export_metadata(
    path: str | Path,
    *,
    expected_export_url: str,
) -> FullExportMetadata:
    """Load a source-issued full-export boundary without cursor fallbacks.

    The metadata producer must explicitly identify the full export, its
    covered-through Open Food Facts delta boundary, and the downloaded source
    checksum.  Download time and the live delta index are intentionally not
    accepted as substitutes.
    """
    metadata_path = Path(path)
    try:
        payload: Any = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise FullExportMetadataError(
            f"Full-export metadata is not valid JSON: {metadata_path}"
        ) from error

    if not isinstance(payload, Mapping):
        raise FullExportMetadataError("Full-export metadata must be a JSON object")

    export_url = payload.get("full_export_url")
    if export_url != expected_export_url:
        raise FullExportMetadataError(
            "Full-export metadata URL does not match the configured export URL"
        )

    cursor = payload.get("covered_through_delta_end")
    if isinstance(cursor, bool) or not isinstance(cursor, int) or cursor < 0:
        raise FullExportMetadataError(
            "Full-export metadata must contain a non-negative integer "
            "covered_through_delta_end"
        )

    checksum = payload.get("source_sha256")
    if not isinstance(checksum, str) or len(checksum) != 64:
        raise FullExportMetadataError(
            "Full-export metadata must contain a 64-character source_sha256"
        )
    try:
        int(checksum, 16)
    except ValueError as error:
        raise FullExportMetadataError(
            "Full-export metadata source_sha256 is not hexadecimal"
        ) from error

    return FullExportMetadata(export_url, cursor, checksum.lower())
