#!/usr/bin/env python3
"""
Message Library CSV Sync Script

Reads message data from CSV and regenerates JabTracker/Services/MessageLibraryData.swift
with proper Swift formatting and validation.

Usage:
    ./scripts/sync-message-library.py <csv_file>
    ./scripts/sync-message-library.py message-library.csv
    ./scripts/sync-message-library.py --help
"""

import csv
import sys
import subprocess
from pathlib import Path
from typing import List, Dict, Set
from dataclasses import dataclass

# Valid enum values (must match Swift enums)
VALID_CATEGORIES = {
    'goodMorning',
    'thinkingOfYou',
    'appreciation',
    'encouragement',
    'flirty',
    'supportive'
}

VALID_TIME_CONTEXTS = {
    'morning',
    'afternoon',
    'evening',
    'anytime'
}

# Category display names for comments
CATEGORY_NAMES = {
    'goodMorning': 'Good Morning',
    'thinkingOfYou': 'Thinking of You',
    'appreciation': 'Appreciation',
    'encouragement': 'Encouragement',
    'flirty': 'Flirty',
    'supportive': 'Supportive'
}


@dataclass
class Message:
    """Represents a single message from the CSV"""
    id: str
    category: str
    time_of_day_context: str
    text: str
    row_number: int  # For error reporting


class ValidationError(Exception):
    """Raised when CSV data validation fails"""
    pass


def read_csv(csv_path: Path) -> List[Message]:
    """
    Read and parse CSV file into Message objects.

    Args:
        csv_path: Path to the CSV file

    Returns:
        List of Message objects

    Raises:
        ValidationError: If CSV format is invalid
    """
    messages = []

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)

            # Validate required columns
            required_columns = {'id', 'category', 'timeOfDayContext', 'text'}
            if not required_columns.issubset(reader.fieldnames or []):
                missing = required_columns - set(reader.fieldnames or [])
                raise ValidationError(
                    f"Missing required columns: {', '.join(missing)}\n"
                    f"Expected: {', '.join(required_columns)}"
                )

            for row_num, row in enumerate(reader, start=2):  # Start at 2 (header is row 1)
                # Skip empty rows
                if not any(row.values()):
                    continue

                message = Message(
                    id=row['id'].strip(),
                    category=row['category'].strip(),
                    time_of_day_context=row['timeOfDayContext'].strip(),
                    text=row['text'].strip(),
                    row_number=row_num
                )
                messages.append(message)

    except FileNotFoundError:
        raise ValidationError(f"CSV file not found: {csv_path}")
    except csv.Error as e:
        raise ValidationError(f"CSV parsing error: {e}")

    return messages


def validate_messages(messages: List[Message]) -> None:
    """
    Validate message data for consistency and correctness.

    Args:
        messages: List of Message objects to validate

    Raises:
        ValidationError: If validation fails
    """
    errors = []
    seen_ids: Set[str] = set()

    for msg in messages:
        # Check for empty required fields
        if not msg.id:
            errors.append(f"Row {msg.row_number}: Missing message ID")
        if not msg.category:
            errors.append(f"Row {msg.row_number}: Missing category")
        if not msg.time_of_day_context:
            errors.append(f"Row {msg.row_number}: Missing timeOfDayContext")
        if not msg.text:
            errors.append(f"Row {msg.row_number}: Missing message text")

        # Check for duplicate IDs
        if msg.id in seen_ids:
            errors.append(f"Row {msg.row_number}: Duplicate message ID '{msg.id}'")
        seen_ids.add(msg.id)

        # Validate category
        if msg.category and msg.category not in VALID_CATEGORIES:
            errors.append(
                f"Row {msg.row_number}: Invalid category '{msg.category}'. "
                f"Valid values: {', '.join(sorted(VALID_CATEGORIES))}"
            )

        # Validate time context
        if msg.time_of_day_context and msg.time_of_day_context not in VALID_TIME_CONTEXTS:
            errors.append(
                f"Row {msg.row_number}: Invalid timeOfDayContext '{msg.time_of_day_context}'. "
                f"Valid values: {', '.join(sorted(VALID_TIME_CONTEXTS))}"
            )

    if errors:
        raise ValidationError("\n".join(["Validation errors found:"] + errors))


def escape_swift_string(text: str) -> str:
    """
    Escape special characters for Swift string literals.

    Args:
        text: Raw text to escape

    Returns:
        Escaped string safe for Swift
    """
    # Escape backslashes first, then quotes
    return text.replace('\\', '\\\\').replace('"', '\\"')


def generate_swift_code(messages: List[Message]) -> str:
    """
    Generate Swift code from validated messages.

    Args:
        messages: List of validated Message objects

    Returns:
        Complete Swift file content as string
    """
    # Group messages by category
    by_category: Dict[str, List[Message]] = {}
    for msg in messages:
        if msg.category not in by_category:
            by_category[msg.category] = []
        by_category[msg.category].append(msg)

    # Count total messages
    total_count = len(messages)

    # Build Swift file content
    lines = [
        "import Foundation",
        "",
        "/// Static message data for Love Taps feature",
        "///",
        "/// Contains all curated messages organized by category.",
        "/// Messages are designed to be authentic, heartfelt, and appropriate for",
        "/// romantic partners in committed relationships.",
        "///",
        "/// **NOTE: This file is AUTO-GENERATED from message-library.csv**",
        "/// **DO NOT EDIT MANUALLY - Changes will be overwritten**",
        "/// **To update messages, edit the Google Sheet and run: ./scripts/sync-message-library.py message-library.csv**",
        "///",
        "/// This file is separated from MessageLibrary.swift to keep file length manageable.",
        "enum MessageLibraryData {  // swiftlint:disable:this type_body_length",
        "",
        f"    /// All available messages in the library ({total_count} messages)",
        "    static let messages: [Message] = [",
    ]

    # Process categories in consistent order
    category_order = ['goodMorning', 'thinkingOfYou', 'appreciation',
                     'encouragement', 'flirty', 'supportive']

    for category in category_order:
        if category not in by_category:
            continue

        category_messages = by_category[category]
        category_name = CATEGORY_NAMES[category]

        # Add category comment
        lines.append(f"        // {category_name} ({len(category_messages)} messages)")

        # Add messages for this category
        for msg in category_messages:
            escaped_text = escape_swift_string(msg.text)
            lines.extend([
                "        Message(",
                f'            id: "{msg.id}",',
                f'            text: "{escaped_text}",',
                f"            category: .{msg.category},",
                f"            timeOfDayContext: .{msg.time_of_day_context}",
                "        ),",
            ])

        lines.append("")  # Blank line between categories

    # Close the array and enum
    lines.extend([
        "    ]",
        "}",
        ""  # Trailing newline
    ])

    return "\n".join(lines)


def write_swift_file(swift_code: str, output_path: Path) -> None:
    """
    Write generated Swift code to file.

    Args:
        swift_code: Generated Swift code
        output_path: Path to output file
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(swift_code)


def run_swift_format(file_path: Path) -> bool:
    """
    Run swift-format on the generated file.

    Args:
        file_path: Path to Swift file

    Returns:
        True if formatting succeeded, False otherwise
    """
    try:
        subprocess.run(
            ['swift-format', '--in-place', str(file_path)],
            check=True,
            capture_output=True
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def print_summary(messages: List[Message]) -> None:
    """
    Print summary of message counts by category.

    Args:
        messages: List of all messages
    """
    # Count by category
    by_category: Dict[str, int] = {}
    for msg in messages:
        by_category[msg.category] = by_category.get(msg.category, 0) + 1

    print("\n✅ Message Library Sync Complete!")
    print(f"\nTotal messages: {len(messages)}")
    print("\nBreakdown by category:")

    for category in ['goodMorning', 'thinkingOfYou', 'appreciation',
                     'encouragement', 'flirty', 'supportive']:
        if category in by_category:
            count = by_category[category]
            name = CATEGORY_NAMES[category]
            print(f"  • {name}: {count} messages")


def main():
    """Main script execution"""
    # Parse command line arguments
    if len(sys.argv) != 2 or sys.argv[1] in ['--help', '-h']:
        print(__doc__)
        print("\nExample:")
        print("  ./scripts/sync-message-library.py message-library.csv")
        sys.exit(0 if '--help' in sys.argv else 1)

    csv_path = Path(sys.argv[1])

    # Determine project root (script is in scripts/ subdirectory)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    output_path = project_root / "JabTracker" / "Services" / "MessageLibraryData.swift"

    try:
        print(f"📖 Reading CSV: {csv_path}")
        messages = read_csv(csv_path)

        print(f"✓ Read {len(messages)} messages")

        print("🔍 Validating data...")
        validate_messages(messages)
        print("✓ Validation passed")

        print("🔨 Generating Swift code...")
        swift_code = generate_swift_code(messages)

        print(f"💾 Writing to: {output_path}")
        write_swift_file(swift_code, output_path)
        print("✓ File written")

        print("🎨 Running swift-format...")
        if run_swift_format(output_path):
            print("✓ Formatting applied")
        else:
            print("⚠️  swift-format not available (skipping)")

        print_summary(messages)

    except ValidationError as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
