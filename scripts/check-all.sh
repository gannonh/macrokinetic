#!/bin/bash

# Comprehensive check script for local CI testing
# Runs all tests, SwiftLint, and build verification

set -e  # Exit on any error
set -o pipefail  # Ensure pipeline failures are detected

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Use the same configuration as test.sh - DEFAULT_DEVICE from working setup
DEFAULT_DEVICE="iPhone 15,OS=17.5"
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

FAILED_CHECKS=0

# 1. SwiftLint check
print_header "1️⃣ SwiftLint Code Quality Check"
if ! run_check "SwiftLint" "swiftlint"; then
    ((FAILED_CHECKS++))
    print_warning "Run 'swiftlint --fix' to auto-fix some issues"
fi

# 2. Build check
print_header "2️⃣ Build Verification"
if ! run_check "Build" "set -o pipefail && xcodebuild build -scheme JabTracker -destination '$SIMULATOR' CODE_SIGNING_ALLOWED=NO | xcpretty --color"; then
    ((FAILED_CHECKS++))
fi

# 3. Unit tests
print_header "3️⃣ Unit Tests"
if ! run_check "Unit Tests" "set -o pipefail && xcodebuild test -scheme JabTracker -destination '$SIMULATOR' -only-testing:JabTrackerTests CODE_SIGNING_ALLOWED=NO | xcpretty --color"; then
    ((FAILED_CHECKS++))
fi

# 4. UI tests
print_header "4️⃣ UI Tests"
if ! run_check "UI Tests" "set -o pipefail && xcodebuild test -scheme JabTracker -destination '$SIMULATOR' -only-testing:JabTrackerUITests CODE_SIGNING_ALLOWED=NO | xcpretty --color"; then
    ((FAILED_CHECKS++))
fi

# 5. SwiftFormat check (if available)
print_header "5️⃣ SwiftFormat Style Check"
if command -v swiftformat &> /dev/null; then
    if ! run_check "SwiftFormat Check" "swiftformat --lint ."; then
        ((FAILED_CHECKS++))
        print_warning "Run 'swiftformat .' to fix formatting issues"
    fi
else
    print_warning "SwiftFormat not installed - skipping format check"
    print_warning "Install with: brew install swiftformat"
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
    echo "• Format issues: swiftformat ."
    echo "• Re-run: ./scripts/check-all.sh"
    echo ""
    exit 1
fi