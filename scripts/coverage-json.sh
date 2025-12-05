#!/bin/bash

# Coverage JSON query script - provides JSON coverage data for analysis
# Usage:
#   ./scripts/coverage-json.sh                    # Full JSON report
#   ./scripts/coverage-json.sh DataController     # Filter by filename
#   ./scripts/coverage-json.sh --functions        # Show function-level coverage
#   ./scripts/coverage-json.sh --summary          # Show file summaries only

set -e

RESULT_BUNDLE=".coverage/coverage.xcresult"

if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ No coverage data found at $RESULT_BUNDLE"
    echo "🔧 Run tests with coverage first: ./scripts/check-all.sh --skip-ui"
    exit 1
fi

# Get the JSON report
JSON_REPORT=$(xcrun xccov view --report --json "$RESULT_BUNDLE")

case "$1" in
    --summary)
        echo "📊 File Coverage Summary:"
        echo "$JSON_REPORT" | jq -r '.targets[] | .files[] | "\(.name): \(.lineCoverage)% (\(.coveredLines)/\(.executableLines))"' | grep -v "Tests.swift" | sort -k2 -nr
        ;;
    --functions)
        echo "🔧 Function Coverage Details:"
        echo "$JSON_REPORT" | jq -r '.targets[] | .files[] | select(.name | test("\\.(swift)$")) | "\n📁 \(.name)\n" + (.functions[] | select(.coveredLines < .executableLines) | "  ❌ \(.name): \(.lineCoverage)% (\(.coveredLines)/\(.executableLines))")'
        ;;
    "")
        echo "📊 Full JSON Coverage Report:"
        echo "$JSON_REPORT" | jq '.'
        ;;
    *)
        echo "🔍 Coverage for files matching: $1"
        echo "$JSON_REPORT" | jq --arg filter "$1" '.targets[] | .files[] | select(.name | contains($filter))'
        ;;
esac

echo ""
echo "💡 Usage examples:"
echo "   ./scripts/coverage-json.sh --summary     # Quick file overview"
echo "   ./scripts/coverage-json.sh --functions   # Uncovered functions"
echo "   ./scripts/coverage-json.sh DataController # Specific file JSON"