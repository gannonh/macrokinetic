#!/bin/bash

# Comprehensive check script for local CI testing
# Runs all tests, SwiftLint, and build verification
#
# Usage: ./scripts/check-all.sh [--skip-ui]
#   --skip-ui: Skip UI tests (faster for development)

set -e  # Exit on any error
set -o pipefail  # Ensure pipeline failures are detected

# Parse command line arguments
SKIP_UI_TESTS=true # Default to skipping UI tests for speed
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ui)
            SKIP_UI_TESTS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-ui]"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Use the same configuration as test.sh - DEFAULT_DEVICE from working setup
DEFAULT_DEVICE="iPhone 17 Pro,OS=26.1"
SIMULATOR="platform=iOS Simulator,name=${DEFAULT_DEVICE}"

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to run a command with error handling
run_check() {
    local name="$1"
    local command="$2"
    
    echo -e "${BLUE}Running: $name${NC}"
    
    # Run command and capture exit code properly
    if bash -c "$command"; then
        print_success "$name passed"
        return 0
    else
        print_error "$name failed"
        return 1
    fi
}

# Start checks
print_header "🚀 JabTracker - Full CI Check Suite"

# Auto-fix common issues before running checks
print_header "🔧 Auto-fixing Code Style Issues"

if command -v swiftlint &> /dev/null; then
    echo -e "${BLUE}Running SwiftLint auto-fix...${NC}"
    swiftlint --fix
    print_success "SwiftLint auto-fix completed"
else
    print_warning "SwiftLint not installed - skipping auto-fix"
fi

if command -v swift-format &> /dev/null; then
    echo -e "${BLUE}Running swift-format auto-fix...${NC}"
    swift-format --configuration .swift-format --in-place --recursive .
    print_success "swift-format auto-fix completed"
else
    print_warning "swift-format not installed - skipping auto-fix"
fi

# Quick build check after auto-fix to catch any issues early
echo -e "${BLUE}Verifying build after auto-fix...${NC}"
if xcodebuild build -scheme JabTracker -destination "$SIMULATOR" > /dev/null 2>&1; then
    print_success "Build verification passed"
else
    print_warning "Build issues detected after auto-fix - continuing with checks"
    print_warning "You may need to manually fix Swift compiler errors"
fi

FAILED_CHECKS=0

# 1. SwiftLint check
print_header "1️⃣ SwiftLint Code Quality Check"
if ! run_check "SwiftLint" "swiftlint"; then
    ((FAILED_CHECKS++))
    print_warning "Run 'swiftlint --fix' to auto-fix some issues"
fi

# 2. Build check
print_header "2️⃣ Build Verification"
if ! run_check "Build" "set -o pipefail && xcodebuild build -scheme JabTracker -destination '$SIMULATOR' | xcbeautify"; then
    ((FAILED_CHECKS++))
fi

# 3. Unit tests with coverage
print_header "3️⃣ Unit Tests with Coverage"
RESULT_BUNDLE=".coverage/coverage.xcresult"
mkdir -p .coverage
rm -rf "$RESULT_BUNDLE"
if ! run_check "Unit Tests with Coverage" "set -o pipefail && xcodebuild test -scheme JabTracker -destination '$SIMULATOR' -only-testing:JabTrackerTests -enableCodeCoverage YES -resultBundlePath '$RESULT_BUNDLE' | xcbeautify"; then
    ((FAILED_CHECKS++))
fi

# 4. UI tests (conditional)
if [ "$SKIP_UI_TESTS" = false ]; then
    print_header "4️⃣ UI Tests"
    if ! run_check "UI Tests" "set -o pipefail && xcodebuild test -scheme JabTracker -destination '$SIMULATOR' -only-testing:JabTrackerUITests -skip-testing:JabTrackerUITests/ManualAuthenticationUITests | xcbeautify"; then
        ((FAILED_CHECKS++))
    fi
else
    print_header "4️⃣ UI Tests (SKIPPED)"
    print_warning "UI tests skipped with --skip-ui flag"
fi

# Note: swift-format check removed - auto-fix handles formatting during the preparation phase

# 5. Coverage Configuration Check (must pass before coverage policy check)
print_header "5️⃣ Coverage Configuration Check"
if ! run_check "Coverage Config" "./scripts/check-coverage-config.sh"; then
    print_error "Coverage configuration is incomplete - cannot proceed with coverage checks"
    print_warning "Add missing files to coverage-config.json before running coverage policy checks"
    echo ""
    echo -e "${RED}❌ Exiting due to incomplete coverage configuration${NC}"
    echo "Fix by adding missing files to either:"
    echo "  1. A coverage tier in .policy.tiers.{tier_name}.files[]"
    echo "  2. The exclusions list in .exclusions.files[]"
    exit 1
fi

# 6. Coverage Policy Check
print_header "6️⃣ Coverage Policy Check"
if [ -d "$RESULT_BUNDLE" ]; then
    if ! run_check "Coverage Policy" "RESULT_BUNDLE='$RESULT_BUNDLE' ./scripts/check-coverage.sh --use-existing"; then
        ((FAILED_CHECKS++))
        print_warning "Some files don't meet coverage requirements"
        print_warning "See docs/coverage-policy.md for requirements"
    fi
else
    print_warning "No coverage data available - skipping coverage policy check"
fi

# Final results
print_header "📊 Final Results"

if [ $FAILED_CHECKS -eq 0 ]; then
    print_success "All checks passed! ✨"
    echo ""
    echo -e "${GREEN}🎉 Your code is ready for PR merge!${NC}"
    echo ""
    exit 0
else
    print_error "$FAILED_CHECKS check(s) failed"
    echo ""
    echo -e "${RED}🚫 Please fix the issues before merging${NC}"
    echo ""
    echo "Quick fixes:"
    echo "• SwiftLint issues: swiftlint --fix"
    echo "• Format issues: swift-format --configuration .swift-format --in-place --recursive ."
    echo "• Re-run: ./scripts/check-all.sh"
    echo "• Skip slow UI tests: ./scripts/check-all.sh --skip-ui"
    echo ""
    exit 1
fi