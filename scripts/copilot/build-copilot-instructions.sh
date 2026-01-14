#!/bin/bash

# Build copilot-instructions.md from planning docs
# This script concatenates all planning documentation into a single file
# for GitHub Copilot context

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OUTPUT_FILE="$PROJECT_ROOT/.github/copilot-instructions.md"

# Source files in order
SOURCE_FILES=(
    "CLAUDE.md"
    ".planning/codebase/ARCHITECTURE.md"
    ".planning/codebase/CONCERNS.md"
    ".planning/codebase/CONVENTIONS.md"
    ".planning/codebase/INTEGRATIONS.md"
    ".planning/codebase/STACK.md"
    ".planning/codebase/STRUCTURE.md"
    ".planning/codebase/TESTING.md"
    ".planning/MILESTONES.md"
    ".planning/PROJECT.md"
    ".planning/ROADMAP.md"
    ".planning/STATE.md"
    "/Users/gannonhall/.claude/rules/development-ios.md"
    "/Users/gannonhall/.claude/rules/e2e-testing-ios.md"
    "/Users/gannonhall/.claude/rules/unit-testing-ios.md"
)

echo "Building copilot-instructions.md..."

# Clear/create output file
> "$OUTPUT_FILE"

for file in "${SOURCE_FILES[@]}"; do
    # Use path as-is if absolute, otherwise prepend PROJECT_ROOT
    if [[ "$file" == /* ]]; then
        full_path="$file"
    else
        full_path="$PROJECT_ROOT/$file"
    fi

    if [[ -f "$full_path" ]]; then
        echo "  Adding: $file"
        cat "$full_path" >> "$OUTPUT_FILE"
        echo -e "\n\n" >> "$OUTPUT_FILE"
    else
        echo "  Warning: $file not found, skipping"
    fi
done

echo "Done! Output written to: $OUTPUT_FILE"
