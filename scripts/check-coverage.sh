#!/bin/bash
set -e

# JabTracker Coverage Policy Enforcement
# This script enforces our tiered coverage policy after running tests

RESULT_BUNDLE="/tmp/coverage.xcresult"
SCHEME="JabTracker"
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=17.5"

echo "🔍 Running tests with coverage..."

# Clean up any existing result bundle
rm -rf "$RESULT_BUNDLE"

# Run tests with coverage enabled
xcodebuild test -scheme "$SCHEME" -destination "$DESTINATION" \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE" \
    -only-testing:JabTrackerTests | xcbeautify

# Check if result bundle was created
if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ Coverage result bundle not created at $RESULT_BUNDLE"
    exit 1
fi

echo "📊 Generating coverage report..."
COVERAGE_JSON=$(xcrun xccov view --report --json "$RESULT_BUNDLE")

# Parse coverage data for different categories
BUSINESS_LOGIC_FILES=(
    "AuthenticationManager.swift"
    "BiometricAuthManager.swift" 
    "DataController.swift"
    "PharmacokineticsEngine.swift"
    "User.swift"
    "Dose.swift"
    "MedicationProfile.swift"
)

VIEW_MODEL_FILES=(
    # Add ViewModels here when created
)

echo "🎯 Coverage Policy Results:"
echo "================================"

# Business Logic Policy: 90% minimum
echo "📈 Business Logic Coverage (Target: 90%)"
for file in "${BUSINESS_LOGIC_FILES[@]}"; do
    COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
        .targets[] | select(.name == "JabTracker.app") | 
        .files[] | select(.name | endswith($file)) | 
        .lineCoverage * 100 | round
    ')
    
    # Handle empty or null coverage values
    if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
        echo "⚠️  $file: Not found in coverage report"
    elif [ "$COVERAGE" -ge 90 ] 2>/dev/null; then
        echo "✅ $file: ${COVERAGE}%"
    else
        echo "❌ $file: ${COVERAGE}% (below 90% threshold)"
        POLICY_FAILED=true
    fi
done

# View Models Policy: 85% minimum
echo ""
echo "📊 View Models Coverage (Target: 85%)"
if [ ${#VIEW_MODEL_FILES[@]} -eq 0 ]; then
    echo "ℹ️  No ViewModels defined yet"
else
    for file in "${VIEW_MODEL_FILES[@]}"; do
        COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
            .targets[] | select(.name == "JabTracker.app") | 
            .files[] | select(.name | endswith($file)) | 
            .lineCoverage * 100 | round
        ')
        
        # Handle empty or null coverage values
        if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
            echo "⚠️  $file: Not found in coverage report"
        elif [ "$COVERAGE" -ge 85 ] 2>/dev/null; then
            echo "✅ $file: ${COVERAGE}%"
        else
            echo "❌ $file: ${COVERAGE}% (below 85% threshold)"
            POLICY_FAILED=true
        fi
    done
fi

# Overall app coverage (informational only)
echo ""
echo "📱 Overall App Coverage (Informational)"
OVERALL_COVERAGE=$(echo "$COVERAGE_JSON" | jq -r '
    .targets[] | select(.name == "JabTracker.app") | 
    .lineCoverage * 100 | round
')
echo "ℹ️  Total: ${OVERALL_COVERAGE}% (SwiftUI views excluded from requirements)"

echo ""
if [ "$POLICY_FAILED" = true ]; then
    echo "❌ Coverage policy check failed"
    echo "Run individual file coverage: xcrun xccov view --file <file_path> $RESULT_BUNDLE"
    exit 1
else
    echo "✅ All coverage policies passed"
    exit 0
fi