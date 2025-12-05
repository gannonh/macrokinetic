#!/bin/bash

# Coverage detail script - provides detailed coverage information
# Usage:
#   ./scripts/coverage-detail.sh [file_pattern]
#   ./scripts/coverage-detail.sh DataController  # Show DataController coverage
#   ./scripts/coverage-detail.sh                 # Show all coverage

set -e

RESULT_BUNDLE=".coverage/coverage.xcresult"

if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ No coverage data found at $RESULT_BUNDLE"
    echo "🔧 Run tests with coverage first: ./scripts/check-all.sh --skip-ui"
    exit 1
fi

if [ -n "$1" ]; then
    echo "🔍 Coverage details for files matching: $1"
    echo "================================"
    xcrun xccov view --report "$RESULT_BUNDLE" | grep -A 50 "$1"
else
    echo "📊 Full coverage report:"
    echo "========================"
    xcrun xccov view --report "$RESULT_BUNDLE"
fi

echo ""
echo "💡 Quick commands:"
echo "   ./scripts/coverage-detail.sh DataController"
echo "   ./scripts/coverage-detail.sh AuthenticationManager" 
echo "   ./scripts/coverage-detail.sh BiometricAuth"
echo ""
echo "📁 Result bundle: $RESULT_BUNDLE"