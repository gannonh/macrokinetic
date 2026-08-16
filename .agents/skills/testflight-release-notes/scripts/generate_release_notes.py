#!/usr/bin/env python3
"""Generate concise TestFlight release notes from the first-parent commit history."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


DEFAULT_MAX_CHARS = 4_000
CONVENTIONAL_COMMIT = re.compile(
    r"^(?P<kind>feat|fix|perf|refactor|build|docs|test|chore|ci)(?:\([^)]*\))?!?:\s*(?P<description>.+)$",
    re.IGNORECASE,
)
USER_FACING_KINDS = {"feat", "fix", "perf", "refactor", "build"}


def commit_subjects(repository: Path, from_ref: str | None, to_ref: str) -> list[str]:
    revision = f"{from_ref}..{to_ref}" if from_ref else to_ref
    result = subprocess.run(
        [
            "git",
            "-C",
            str(repository),
            "log",
            "--first-parent",
            "--no-merges",
            "--format=%s",
            revision,
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def display_changes(subjects: list[str]) -> list[tuple[str, str]]:
    changes: list[tuple[str, str]] = []
    seen: set[str] = set()

    for subject in subjects:
        match = CONVENTIONAL_COMMIT.match(subject)
        if match:
            kind = match.group("kind").lower()
            description = match.group("description").strip()
        else:
            kind = "change"
            description = subject

        key = description.casefold()
        if not description or key in seen:
            continue
        seen.add(key)
        changes.append((kind, f"{description[0].upper()}{description[1:]}"))

    return changes


def render_notes(
    version: str,
    build: str,
    changes: list[tuple[str, str]],
    focus: list[str],
    max_chars: int,
) -> str:
    lines = [f"JabTracker {version} ({build})", "", "Please test:"]
    for item in focus:
        lines.append(f"- {item.strip()}")

    user_changes = [change for change in changes if change[0] in USER_FACING_KINDS]
    if user_changes:
        lines.append("- Exercise the affected flows listed below.")
        lines.append("")
        lines.append("Changes in this build:")
        for _, description in user_changes:
            lines.append(f"- {description}")
    elif not focus:
        lines.append("- Confirm dose logging, Food Library search, and nutrition logging still work.")

    text = "\n".join(lines).strip() + "\n"
    if len(text) <= max_chars:
        return text

    truncated = text[: max_chars - 1].rstrip()
    return f"{truncated}\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Marketing version, for example 0.10.1")
    parser.add_argument("--build", required=True, help="App Store build number")
    parser.add_argument("--from-ref", help="Exclusive git revision containing the previous release")
    parser.add_argument("--to-ref", default="HEAD", help="Inclusive git revision for this release")
    parser.add_argument("--repo", type=Path, default=Path("."), help="Git repository to inspect")
    parser.add_argument("--focus", action="append", default=[], help="Additional tester focus item")
    parser.add_argument("--max-chars", type=int, default=DEFAULT_MAX_CHARS)
    parser.add_argument("--output", type=Path, help="Write notes here instead of stdout")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.max_chars < 1:
        print("--max-chars must be positive", file=sys.stderr)
        return 2

    try:
        subjects = commit_subjects(args.repo, args.from_ref, args.to_ref)
    except subprocess.CalledProcessError as error:
        message = error.stderr.strip() if error.stderr else "git log failed"
        print(message, file=sys.stderr)
        return error.returncode or 1

    notes = render_notes(
        args.version,
        args.build,
        display_changes(subjects),
        args.focus,
        args.max_chars,
    )
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(notes, encoding="utf-8")
    else:
        sys.stdout.write(notes)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
