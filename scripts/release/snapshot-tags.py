#!/usr/bin/env python3
"""Print promoted food snapshot tags in deterministic newest-first order."""

from __future__ import annotations

import json
import re
import sys

TAG = re.compile(r"^food-db-(\d+)-([0-9a-fA-F]{12})$")

releases = json.load(sys.stdin)
tags = []
for release in releases:
    if release.get("isDraft") or release.get("isPrerelease"):
        continue
    tag = str(release.get("tagName", ""))
    if tag.startswith("food-db-") and TAG.fullmatch(tag) is None:
        raise SystemExit(f"invalid promoted snapshot tag: {tag}")
    match = TAG.fullmatch(tag)
    if match:
        tags.append((int(match.group(1)), tag))

for _, tag in sorted(tags, reverse=True):
    print(tag)
