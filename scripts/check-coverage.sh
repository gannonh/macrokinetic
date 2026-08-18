#!/bin/bash
set -e

# JabTracker Coverage Policy Enforcement
# This script enforces our tiered coverage policy after running tests
#
# Usage: 
#   ./check-coverage.sh                    # Run tests and check coverage
#   ./check-coverage.sh --use-existing     # Use existing coverage data

USE_EXISTING=false
if [[ "$1" == "--use-existing" ]]; then
    USE_EXISTING=true
fi
# iPhone 17 Pro,OS=26.5
RESULT_BUNDLE="${RESULT_BUNDLE:-.coverage/coverage.xcresult}"
SCHEME="JabTrackerUnitTests"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5"
CONFIG_FILE="$(dirname "$0")/../coverage-config.json"

if [ "$USE_EXISTING" = false ]; then
    echo "🔍 Running tests with coverage..."

    # Ensure coverage directory exists
    mkdir -p .coverage

    # Clean up any existing result bundle
    rm -rf "$RESULT_BUNDLE"

    # Run tests with coverage enabled
    xcodebuild test -scheme "$SCHEME" -destination "$DESTINATION" \
        -enableCodeCoverage YES \
        -resultBundlePath "$RESULT_BUNDLE" \
        -only-testing:JabTrackerUnitTests | xcbeautify
else
    echo "📊 Using existing coverage data from $RESULT_BUNDLE"
fi

# Check if result bundle was created
if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ Coverage result bundle not created at $RESULT_BUNDLE"
    exit 1
fi

echo "📊 Generating coverage report..."
COVERAGE_JSON=$(xcrun xccov view --report --json "$RESULT_BUNDLE")

# Load configuration from JSON
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Coverage configuration file not found: $CONFIG_FILE"
    exit 1
fi

CONFIG_JSON=$(cat "$CONFIG_FILE")

# Extract file lists and thresholds from config
PURE_BUSINESS_LOGIC_FILES=($(echo "$CONFIG_JSON" | jq -r '.policy.tiers.pure_business_logic.files[]'))
PURE_BUSINESS_LOGIC_THRESHOLD=$(echo "$CONFIG_JSON" | jq -r '.policy.tiers.pure_business_logic.threshold')

INFRASTRUCTURE_FILES=($(echo "$CONFIG_JSON" | jq -r '.policy.tiers.infrastructure.files[]'))
INFRASTRUCTURE_THRESHOLD=$(echo "$CONFIG_JSON" | jq -r '.policy.tiers.infrastructure.threshold')

FRAMEWORK_INTEGRATION_FILES=($(echo "$CONFIG_JSON" | jq -r '.policy.tiers.framework_integration.files[]'))
FRAMEWORK_INTEGRATION_THRESHOLD=$(echo "$CONFIG_JSON" | jq -r '.policy.tiers.framework_integration.threshold')

TESTING_INFRASTRUCTURE_FILES=($(echo "$CONFIG_JSON" | jq -r '.policy.tiers.testing_infrastructure.files[]'))
TESTING_INFRASTRUCTURE_THRESHOLD=$(echo "$CONFIG_JSON" | jq -r '.policy.tiers.testing_infrastructure.threshold')

VIEW_MODEL_FILES=($(echo "$CONFIG_JSON" | jq -r '.policy.tiers.view_models.files[]'))
VIEW_MODEL_THRESHOLD=$(echo "$CONFIG_JSON" | jq -r '.policy.tiers.view_models.threshold')

UTILITIES_FILES=($(echo "$CONFIG_JSON" | jq -r '.policy.tiers.utilities.files[]'))
UTILITIES_THRESHOLD=$(echo "$CONFIG_JSON" | jq -r '.policy.tiers.utilities.threshold')

echo "🎯 Coverage Policy Results:"
echo "================================"

# Tier 1: Pure Business Logic
echo "🧠 Tier 1: Pure Business Logic (Target: ${PURE_BUSINESS_LOGIC_THRESHOLD}%)"
for file in "${PURE_BUSINESS_LOGIC_FILES[@]}"; do
    COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
        .targets[] | select(.name == "JabTracker.app") |
        .files[] | select(.name == ($file | split("/") | last)) |
        .lineCoverage * 100 | round
    ')
    
    # Handle empty or null coverage values
    if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
        echo "⚠️  $file: Not found in coverage report"
    elif [ "$COVERAGE" -ge "$PURE_BUSINESS_LOGIC_THRESHOLD" ] 2>/dev/null; then
        echo "✅ $file: ${COVERAGE}%"
    else
        echo "❌ $file: ${COVERAGE}% (below ${PURE_BUSINESS_LOGIC_THRESHOLD}% threshold)"
        POLICY_FAILED=true
    fi
done

# Tier 2: Infrastructure & Data
echo ""
echo "🏗️ Tier 2: Infrastructure & Data (Target: ${INFRASTRUCTURE_THRESHOLD}%)"
for file in "${INFRASTRUCTURE_FILES[@]}"; do
    COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
        .targets[] | select(.name == "JabTracker.app") |
        .files[] | select(.name == ($file | split("/") | last)) |
        .lineCoverage * 100 | round
    ')
    
    if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
        echo "⚠️  $file: Not found in coverage report"
    elif [ "$COVERAGE" -ge "$INFRASTRUCTURE_THRESHOLD" ] 2>/dev/null; then
        echo "✅ $file: ${COVERAGE}%"
    else
        echo "❌ $file: ${COVERAGE}% (below ${INFRASTRUCTURE_THRESHOLD}% threshold)"
        POLICY_FAILED=true
    fi
done

# Tier 3: Framework Integration
echo ""
echo "🔗 Tier 3: Framework Integration (Target: ${FRAMEWORK_INTEGRATION_THRESHOLD}%)"
for file in "${FRAMEWORK_INTEGRATION_FILES[@]}"; do
    COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
        .targets[] | select(.name == "JabTracker.app") |
        .files[] | select(.name == ($file | split("/") | last)) |
        .lineCoverage * 100 | round
    ')
    
    if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
        echo "⚠️  $file: Not found in coverage report"
    elif [ "$COVERAGE" -ge "$FRAMEWORK_INTEGRATION_THRESHOLD" ] 2>/dev/null; then
        echo "✅ $file: ${COVERAGE}%"
    else
        echo "❌ $file: ${COVERAGE}% (below ${FRAMEWORK_INTEGRATION_THRESHOLD}% threshold)"
        POLICY_FAILED=true
    fi
done

# Tier 3B: Testing Infrastructure
echo ""
echo "🧪 Tier 3B: Testing Infrastructure (Target: ${TESTING_INFRASTRUCTURE_THRESHOLD}%)"
for file in "${TESTING_INFRASTRUCTURE_FILES[@]}"; do
    COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
        .targets[] | select(.name == "JabTracker.app") |
        .files[] | select(.name == ($file | split("/") | last)) |
        .lineCoverage * 100 | round
    ')

    if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
        echo "⚠️  $file: Not found in coverage report"
    elif [ "$COVERAGE" -ge "$TESTING_INFRASTRUCTURE_THRESHOLD" ] 2>/dev/null; then
        echo "✅ $file: ${COVERAGE}%"
    else
        echo "❌ $file: ${COVERAGE}% (below ${TESTING_INFRASTRUCTURE_THRESHOLD}% threshold)"
        POLICY_FAILED=true
    fi
done

# Tier 4: View Models
echo ""
echo "📊 Tier 4: View Models (Target: ${VIEW_MODEL_THRESHOLD}%)"
if [ ${#VIEW_MODEL_FILES[@]} -eq 0 ]; then
    echo "ℹ️  No ViewModels defined yet"
else
    for file in "${VIEW_MODEL_FILES[@]}"; do
        COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
            .targets[] | select(.name == "JabTracker.app") |
            .files[] | select(.name == ($file | split("/") | last)) |
            .lineCoverage * 100 | round
        ')
        
        # Handle empty or null coverage values
        if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
            echo "⚠️  $file: Not found in coverage report"
        elif [ "$COVERAGE" -ge "$VIEW_MODEL_THRESHOLD" ] 2>/dev/null; then
            echo "✅ $file: ${COVERAGE}%"
        else
            echo "❌ $file: ${COVERAGE}% (below ${VIEW_MODEL_THRESHOLD}% threshold)"
            POLICY_FAILED=true
        fi
    done
fi

# Tier 5: Utilities
echo ""
echo "🔧 Tier 5: Utilities (Target: ${UTILITIES_THRESHOLD}%)"
if [ ${#UTILITIES_FILES[@]} -eq 0 ]; then
    echo "ℹ️  No utilities files defined yet"
else
    for file in "${UTILITIES_FILES[@]}"; do
        COVERAGE=$(echo "$COVERAGE_JSON" | jq -r --arg file "$file" '
            .targets[] | select(.name == "JabTracker.app") |
            .files[] | select(.name == ($file | split("/") | last)) |
            .lineCoverage * 100 | round
        ')
        
        # Handle empty or null coverage values
        if [ "$COVERAGE" = "null" ] || [ "$COVERAGE" = "" ]; then
            echo "⚠️  $file: Not found in coverage report"
        elif [ "$COVERAGE" -ge "$UTILITIES_THRESHOLD" ] 2>/dev/null; then
            echo "✅ $file: ${COVERAGE}%"
        else
            echo "❌ $file: ${COVERAGE}% (below ${UTILITIES_THRESHOLD}% threshold)"
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
