#!/usr/bin/env python3
"""Fail the StoreKit lane unless it executed tests without skips or SKInternalErrorDomain."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def evaluate_storekit_results(summary: dict, log: str) -> str | None:
    total = int(summary.get("totalTestCount") or 0)
    skipped = int(summary.get("skippedTests") or 0)
    if total < 1:
        return f"StoreKit lane executed {total} tests"
    if skipped:
        return f"StoreKit lane skipped {skipped} tests"
    if "SKInternalErrorDomain" in log:
        return "StoreKit lane log contains SKInternalErrorDomain"
    return None


def _summary(xcresult: Path) -> dict:
    raw = subprocess.check_output(
        [
            "xcrun",
            "xcresulttool",
            "get",
            "test-results",
            "summary",
            "--path",
            str(xcresult),
            "--format",
            "json",
        ],
        text=True,
    )
    return json.loads(raw)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xcresult", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args(argv)

    bundle = Path(args.xcresult)
    log_path = Path(args.log)
    if not bundle.exists():
        print("StoreKit xcresult is missing", file=sys.stderr)
        return 1

    summary = _summary(bundle)
    log = log_path.read_text(errors="replace") if log_path.exists() else ""
    error = evaluate_storekit_results(summary, log)
    if error:
        print(error, file=sys.stderr)
        return 1
    print(
        json.dumps(
            {
                "executed": int(summary.get("totalTestCount") or 0),
                "skipped": int(summary.get("skippedTests") or 0),
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
