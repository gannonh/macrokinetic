#!/bin/bash

set -o pipefail  # Ensure pipeline failures are detected

# Run tests with pretty output and device selection

# Available simulators
# NOTE: iOS 26.2 simulators recommended with Xcode 26.2 to avoid SwiftData/CloudKit crashes
# iOS 17.5 simulators have compatibility issues with Xcode 26's NSPersistentStoreCoordinator
# iPhone 17 Pro - F10F879D-2403-4529-8850-91DE259C1312
# iPhone 17- 63B35940-1E74-4D29-821B-4DB5CAB5FA9C
# iPhone 17 Pro Max - 38218630-EBEC-4196-80A2-92AB0A855715
DEVICES=(
    "iPhone 17 Pro,OS=26.2"
    "iPhone 17,OS=26.2"
    "iPhone 17 Pro Max,OS=26.2"
)

DEFAULT_DEVICE="iPhone 17 Pro,OS=26.2"
ENABLE_COVERAGE=false
RESET_DEVICE=false
ENABLE_LOGGING=true
LOG_ONLY=false

show_usage() {
    echo "Usage: $0 {unit|ui|all} [device] [test_file] [--coverage] [--reset] [--no-log] [--log-only] [--help]"
    echo ""
    echo "Test types:"
    echo "  unit - Run unit tests only"
    echo "  ui   - Run UI tests only"  
    echo "  all  - Run all tests"
    echo ""
    echo "Available devices:"
    for i in "${!DEVICES[@]}"; do
        echo "  $((i+1)). ${DEVICES[$i]}"
    done
    echo ""
    echo "Options:"
    echo "  --coverage  Generate code coverage report and display results"
    echo "  --reset     Reset simulator before running tests (clears all permissions)"
    echo "  --no-log    Disable automatic logging to ./logs directory"
    echo "  --log-only  Save logs without displaying console output"
    echo "  --help      Show this help message"
    echo ""
    echo "Available test files:"
    echo "  Unit tests (file-based organization):"
    echo "    PersistenceTests      - Core Data and persistence functionality"  
    echo "    DesignSystemTests     - UI design system and styling components"
    echo ""
    echo "  UI tests:"
    echo "    AuthenticationUITests       - Automated authentication flow tests (using --ui-testing mode)"
    echo "    ManualAuthenticationUITests - Manual Apple ID tests (excluded from CI, run in Xcode manually)"
    echo "    OnboardingUITests           - User onboarding flow tests"
    echo "    DesignSystemUITests         - Design system component tests"
    echo ""
    echo "Examples:"
    echo "  $0 ui                                                    # Run all UI tests on default device"
    echo "  $0 ui 1                                                  # Run all UI tests on iPhone 17 Pro"
    echo "  $0 ui 1 DesignSystemUITests                             # Run specific UI test class"
    echo "  $0 ui 1 DesignSystemUITests/testDesignSystemComponents  # Run specific UI test method"
    echo "  $0 ui 1 ManualAuthenticationUITests                     # Run manual Apple ID tests (requires manual interaction)"
    echo "  $0 unit 1 PersistenceTests                              # Run all persistence-related unit tests"
    echo "  $0 unit 1 DesignSystemTests                             # Run all design system unit tests"
    echo "  $0 unit 1 --coverage                                    # Run unit tests with coverage report"
    echo "  $0 ui 1 --reset                                         # Run UI tests with fresh simulator state"
    echo "  $0 all --coverage                                       # Run all tests with coverage report (excludes manual tests)"
    echo ""
    echo "Note: Unit tests use file-based organization for Swift Testing compatibility."
    echo "      Each test file focuses on a specific feature area for efficient development workflow."
    echo "      Log files include simulator identifier for parallel agent execution."
    exit 1
}

# Check for help flag first
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        show_usage
    fi
done

if [ $# -eq 0 ]; then
    show_usage
fi

# Parse arguments (handle --coverage flag anywhere in args)
TEST_TYPE="$1"
DEVICE_NUM=""
TEST_FILE=""

# Parse remaining arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            ENABLE_COVERAGE=true
            shift
            ;;
        --reset)
            RESET_DEVICE=true
            shift
            ;;
        --no-log)
            ENABLE_LOGGING=false
            shift
            ;;
        --log-only)
            LOG_ONLY=true
            shift
            ;;
        *)
            if [[ -z "$DEVICE_NUM" && "$1" =~ ^[0-9]+$ ]]; then
                DEVICE_NUM="$1"
            elif [[ -z "$TEST_FILE" && ! "$1" =~ ^[0-9]+$ ]]; then
                TEST_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Select device
if [ -n "$DEVICE_NUM" ]; then
    if [[ "$DEVICE_NUM" =~ ^[0-9]+$ ]] && [ "$DEVICE_NUM" -ge 1 ] && [ "$DEVICE_NUM" -le ${#DEVICES[@]} ]; then
        SELECTED_DEVICE="${DEVICES[$((10#$DEVICE_NUM-1))]}"
    else
        echo "❌ Invalid device number. Choose 1-${#DEVICES[@]}"
        show_usage
    fi
else
    SELECTED_DEVICE="$DEFAULT_DEVICE"
fi

SIMULATOR="platform=iOS Simulator,name=${SELECTED_DEVICE}"

# Set up logging
if [ "$ENABLE_LOGGING" = true ]; then
    # Create timestamp for this test run
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

    # Create simulator identifier for log naming (remove special characters and spaces)
    SIMULATOR_ID=$(echo "$SELECTED_DEVICE" | sed 's/[^a-zA-Z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g')

    # Determine log directory name with simulator identifier
    case "$TEST_TYPE" in
        "unit")
            LOG_DIR="logs/unit_tests_${SIMULATOR_ID}_${TIMESTAMP}"
            ;;
        "ui")
            LOG_DIR="logs/ui_tests_${SIMULATOR_ID}_${TIMESTAMP}"
            ;;
        "all")
            LOG_DIR="logs/all_tests_${SIMULATOR_ID}_${TIMESTAMP}"
            ;;
    esac

    # Create log directory
    mkdir -p "$LOG_DIR"

    # Update latest symlink (keeping for backward compatibility, but now includes simulator)
    rm -f logs/latest
    ln -s "$(basename "$LOG_DIR")" logs/latest

    # Create simulator-specific latest symlink for parallel agents
    rm -f "logs/latest_${SIMULATOR_ID}"
    ln -s "$(basename "$LOG_DIR")" "logs/latest_${SIMULATOR_ID}"

    LOG_FILE="$LOG_DIR/output.txt"
    XCRESULT_PATH="$LOG_DIR/results.xcresult"

    if [ "$LOG_ONLY" = false ]; then
        echo "📝 Logging to: $LOG_DIR"
    fi
fi

if [ "$LOG_ONLY" = false ]; then
    echo "📱 Using simulator: $SELECTED_DEVICE"
fi

# Reset simulator if requested
if [ "$RESET_DEVICE" = true ]; then
    echo "🔄 Resetting simulator to clear permissions..."
    # Extract device name without OS version for UUID lookup
    DEVICE_NAME="${SELECTED_DEVICE%,*}"
    SIMULATOR_UUID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | head -1 | grep -o '[A-F0-9-]\{36\}')
    
    if [ -n "$SIMULATOR_UUID" ]; then
        echo "🎯 Found simulator UUID: $SIMULATOR_UUID for $DEVICE_NAME"
        xcrun simctl shutdown "$SIMULATOR_UUID" 2>/dev/null || true
        xcrun simctl erase "$SIMULATOR_UUID"
        xcrun simctl boot "$SIMULATOR_UUID"
        echo "✅ Simulator reset complete"
    else
        echo "⚠️  Could not find simulator UUID for $DEVICE_NAME - continuing without reset"
    fi
fi

# Build test target based on type and test file
build_test_target() {
    local test_type="$1"
    local test_file="$2"
    
    if [ -n "$test_file" ]; then
        case "$test_type" in
            "unit")
                # Run specific unit test suite (Swift Testing supports suite-level targeting)
                echo "-only-testing:JabTrackerTests/$test_file"
                ;;
            "ui")
                # Run specific UI test file
                echo "-only-testing:JabTrackerUITests/$test_file"
                ;;
        esac
    else
        case "$test_type" in
            "unit")
                echo "-only-testing:JabTrackerTests"
                ;;
            "ui")
                # Exclude manual tests from automated runs
                echo "-only-testing:JabTrackerUITests -skip-testing:JabTrackerUITests/ManualAuthenticationUITests"
                ;;
            "all")
                # Exclude manual tests from automated runs
                echo "-skip-testing:JabTrackerUITests/ManualAuthenticationUITests"
                ;;
        esac
    fi
}

TEST_TARGET=$(build_test_target "$TEST_TYPE" "$TEST_FILE")

# Build coverage and result bundle options
COVERAGE_OPTIONS=""
RESULT_BUNDLE_PATH=""

if [ "$ENABLE_LOGGING" = true ]; then
    # Always generate xcresult when logging
    RESULT_BUNDLE_PATH="-resultBundlePath $XCRESULT_PATH"
    if [ "$ENABLE_COVERAGE" = true ]; then
        COVERAGE_OPTIONS="-enableCodeCoverage YES"
    fi
elif [ "$ENABLE_COVERAGE" = true ]; then
    # Coverage without logging uses .coverage directory
    mkdir -p .coverage
    rm -rf .coverage/coverage.xcresult
    COVERAGE_OPTIONS="-enableCodeCoverage YES"
    RESULT_BUNDLE_PATH="-resultBundlePath .coverage/coverage.xcresult"
fi

if [ "$LOG_ONLY" = false ]; then
    if [ -n "$TEST_FILE" ]; then
        case "$TEST_TYPE" in
            "unit")
                echo "🎯 Running unit tests (Note: Swift Testing runs all unit tests, but focus on $TEST_FILE results)"
                ;;
            "ui")
                echo "🎯 Running specific UI test: $TEST_FILE"
                ;;
        esac
    else
        if [ "$ENABLE_COVERAGE" = true ]; then
            echo "📊 Coverage report will be generated after test completion"
        fi
    fi
fi

# Function to run tests with appropriate output handling
run_tests() {
    local test_description="$1"

    if [ "$LOG_ONLY" = false ]; then
        echo "$test_description"
    fi

    # Disable concurrent destination testing to prevent simulator cloning overhead
    # This speeds up test startup significantly in Xcode 26
    PARALLEL_OPTIONS="-disable-concurrent-destination-testing -parallel-testing-enabled NO"

    if [ "$ENABLE_LOGGING" = true ]; then
        # Create a raw log file for complete output
        RAW_LOG_FILE="$LOG_DIR/raw_output.txt"

        if [ "$LOG_ONLY" = true ]; then
            # Log only - capture raw output
            xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET $COVERAGE_OPTIONS $RESULT_BUNDLE_PATH $PARALLEL_OPTIONS 2>&1 > "$RAW_LOG_FILE"
            # Process with xcbeautify for the main log file
            cat "$RAW_LOG_FILE" | xcbeautify > "$LOG_FILE" 2>&1
        else
            # Log and display - tee raw output to file while piping to xcbeautify for display
            # This preserves real-time output while capturing everything
            xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET $COVERAGE_OPTIONS $RESULT_BUNDLE_PATH $PARALLEL_OPTIONS 2>&1 | \
                tee "$RAW_LOG_FILE" | \
                xcbeautify --renderer terminal
            # Also save beautified version for easier reading
            cat "$RAW_LOG_FILE" | xcbeautify > "$LOG_FILE" 2>&1
        fi
        TEST_EXIT_CODE=${PIPESTATUS[0]}
    else
        # No logging - use xcbeautify with terminal renderer for real-time output
        xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET $COVERAGE_OPTIONS $RESULT_BUNDLE_PATH $PARALLEL_OPTIONS 2>&1 | \
            xcbeautify --renderer terminal
        TEST_EXIT_CODE=${PIPESTATUS[0]}
    fi
}

case "$TEST_TYPE" in
  "unit")
    run_tests "🧪 Running unit tests..."
    ;;
  "ui")
    run_tests "🖱️  Running UI tests..."
    ;;
  "all")
    run_tests "🎯 Running all tests..."
    ;;
  *)
    show_usage
    ;;
esac

# Handle coverage report
if [ "$ENABLE_COVERAGE" = true ]; then
    COVERAGE_RESULT_PATH=""
    if [ "$ENABLE_LOGGING" = true ]; then
        COVERAGE_RESULT_PATH="$XCRESULT_PATH"
    else
        COVERAGE_RESULT_PATH=".coverage/coverage.xcresult"
    fi

    if [ -d "$COVERAGE_RESULT_PATH" ]; then
        if [ "$LOG_ONLY" = false ]; then
            echo ""
            echo "📊 Code Coverage Report:"
            echo "=========================="
            xcrun xccov view --report "$COVERAGE_RESULT_PATH"
        fi

        # Save coverage JSON if logging is enabled
        if [ "$ENABLE_LOGGING" = true ]; then
            xcrun xccov view --report --json "$COVERAGE_RESULT_PATH" > "$LOG_DIR/coverage.json" 2>/dev/null
            if [ "$LOG_ONLY" = false ]; then
                echo ""
                echo "💡 Coverage data saved to: $LOG_DIR/coverage.json"
            fi
        elif [ "$LOG_ONLY" = false ]; then
            echo ""
            echo "💡 Coverage data saved to: $COVERAGE_RESULT_PATH"
            echo "💡 To view detailed coverage: xcrun xccov view --file-list $COVERAGE_RESULT_PATH"
        fi
    elif [ "$LOG_ONLY" = false ]; then
        echo ""
        echo "⚠️  Coverage report requested but result bundle not found."
        echo "💡 This may happen if tests fail to complete."
    fi
fi

# Determine actual test status from results
TESTS_PASSED=true
if [ "$ENABLE_LOGGING" = true ] && [ -f "$RAW_LOG_FILE" ]; then
    # Check for test failures in the output
    if grep -q "✘.*failed\|Test run with.*failed" "$RAW_LOG_FILE" 2>/dev/null; then
        TESTS_PASSED=false
        FINAL_EXIT_CODE=1
    else
        FINAL_EXIT_CODE=${TEST_EXIT_CODE}
    fi
else
    # Fallback to build exit code if no logs
    if [ "$TEST_EXIT_CODE" -ne 0 ]; then
        TESTS_PASSED=false
        FINAL_EXIT_CODE=${TEST_EXIT_CODE}
    else
        FINAL_EXIT_CODE=0
    fi
fi

# Show summary
if [ "$ENABLE_LOGGING" = true ]; then
    echo ""
    echo "📁 Test Results Summary:"
    echo "========================"
    if [ "$TESTS_PASSED" = true ]; then
        echo "✅ Tests passed"
    else
        echo "❌ Tests failed"
        if grep -q "✘ Test \".*\" failed" "$RAW_LOG_FILE" 2>/dev/null; then
            echo ""
            echo "Failed tests:"
            # Extract test names that failed
            grep "✘ Test \".*\" failed after" "$RAW_LOG_FILE" | while read -r line; do
                test_name=$(echo "$line" | sed -n 's/.*Test "\([^"]*\)".*/\1/p')
                echo "   • $test_name"
                # Show the assertion failures for this test
                grep "✘ Test \"$test_name\" recorded an issue" "$RAW_LOG_FILE" | sed 's/✘ Test "[^"]*" recorded an issue at /     → /' | sed 's/: Expectation failed: /: /'
            done
        fi
    fi
    echo ""
    echo "📂 Log files saved to: $LOG_DIR/"
    echo "   • Formatted output: $LOG_FILE"
    echo "   • Raw output (with debug logs): $LOG_DIR/raw_output.txt"
    echo "   • Result bundle: $XCRESULT_PATH"
    if [ "$ENABLE_COVERAGE" = true ] && [ -f "$LOG_DIR/coverage.json" ]; then
        echo "   • Coverage data: $LOG_DIR/coverage.json"
    fi
    echo ""
    echo "💡 View latest logs: cat logs/latest/output.txt"
    echo "💡 View simulator-specific logs: cat logs/latest_${SIMULATOR_ID}/output.txt"
    echo "💡 Open result bundle: open $XCRESULT_PATH"
fi

# Exit with the actual test status
exit ${FINAL_EXIT_CODE:-0}