#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTINATION="${JABTRACKER_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 18 Pro,OS=latest}"
DEVICE_ID=""
LOG_DIR=""
TEST_FILE=""
ENABLE_COVERAGE=false
RESET_DEVICE=false
TEMP_LOGGING=false
LOG_ONLY=false

show_usage() {
    cat <<USAGE
Usage: $0 {unit|ui|all} [Suite[/testMethod]] [options]

Options:
  --destination VALUE  xcodebuild destination (or JABTRACKER_TEST_DESTINATION)
  --device-id UDID     Select an installed iOS simulator by UDID
  --log-dir PATH       Retain this run's output and artifacts in an empty directory
  --coverage           Save code coverage JSON
  --reset              Erase the explicitly selected simulator (requires --device-id)
  --no-log             Retain artifacts in a temporary directory instead of ./logs
  --log-only           Save output without streaming it to the console
  --help               Show this help

All runs retain stdout/stderr, xcodebuild status, xcresult summary/test inventory,
and exported attachments. Any skipped test fails this mandatory test run.
USAGE
}

fail_usage() {
    echo "Error: $1" >&2
    show_usage >&2
    exit 2
}

if [ "${1:-}" = "--help" ]; then
    show_usage
    exit 0
fi
[ $# -gt 0 ] || fail_usage "Choose unit, ui, or all."
TEST_TYPE="$1"
shift
case "$TEST_TYPE" in unit|ui|all) ;; *) fail_usage "Unknown test type: $TEST_TYPE" ;; esac
DESTINATION_SET=false
while [ $# -gt 0 ]; do
    case "$1" in
        --destination|--device-id|--log-dir)
            option="$1"
            [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != --* ]] || fail_usage "$option requires a value."
            case "$option" in
                --destination)
                    [ -z "$DEVICE_ID" ] || fail_usage "Use --destination or --device-id, not both."
                    DESTINATION="$2"
                    DESTINATION_SET=true
                    ;;
                --device-id)
                    [ "$DESTINATION_SET" = false ] || fail_usage "Use --destination or --device-id, not both."
                    [[ "$2" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail_usage "Invalid simulator UDID."
                    DEVICE_ID="$2"
                    DESTINATION="platform=iOS Simulator,id=$DEVICE_ID"
                    ;;
                --log-dir) LOG_DIR="$2" ;;
            esac
            shift 2
            ;;
        --coverage) ENABLE_COVERAGE=true; shift ;;
        --reset) RESET_DEVICE=true; shift ;;
        --no-log) TEMP_LOGGING=true; shift ;;
        --log-only) LOG_ONLY=true; shift ;;
        --help) show_usage; exit 0 ;;
        -*) fail_usage "Unknown option: $1" ;;
        *)
            [ -z "$TEST_FILE" ] || fail_usage "Only one suite or test method may be selected."
            [ "$TEST_TYPE" != all ] || fail_usage "Select unit or ui when filtering a suite."
            TEST_FILE="$1"
            shift
            ;;
    esac
done
[ -n "$DESTINATION" ] || fail_usage "Destination must not be empty."
if [ "$RESET_DEVICE" = true ] && [ -z "$DEVICE_ID" ]; then
    fail_usage "--reset requires --device-id to avoid erasing a different simulator."
fi

SCHEME="JabTracker"
TEST_ARGS=()
EXPECTED_TEST=""
case "$TEST_TYPE" in
    unit)
        SCHEME="JabTrackerUnitTests"
        EXPECTED_TEST="JabTrackerUnitTests${TEST_FILE:+/$TEST_FILE}"
        TEST_ARGS=("-only-testing:$EXPECTED_TEST")
        ;;
    ui)
        EXPECTED_TEST="JabTrackerUITests${TEST_FILE:+/$TEST_FILE}"
        TEST_ARGS=("-only-testing:$EXPECTED_TEST")
        if [ -z "$TEST_FILE" ]; then
            TEST_ARGS+=("-skip-testing:JabTrackerUITests/ManualAuthenticationUITests")
        fi
        ;;
    all) TEST_ARGS=("-skip-testing:JabTrackerUITests/ManualAuthenticationUITests") ;;
esac

if [ -n "$LOG_DIR" ]; then
    if [ -e "$LOG_DIR" ] && { [ ! -d "$LOG_DIR" ] || [ -n "$(ls -A "$LOG_DIR")" ]; }; then
        fail_usage "--log-dir must be absent or empty; previous evidence will not be overwritten."
    fi
    mkdir -p "$LOG_DIR" || exit 1
elif [ "$TEMP_LOGGING" = true ]; then
    LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jabtracker-${TEST_TYPE}.XXXXXX")" || exit 1
else
    mkdir -p logs || exit 1
    simulator_name="$(printf '%s' "$DESTINATION" | tr -cs '[:alnum:]' '_')"
    LOG_DIR="$(mktemp -d "logs/${TEST_TYPE}_${simulator_name}_$(date +%Y-%m-%d_%H-%M-%S).XXXXXX")" || exit 1
    ln -sfn "$(basename "$LOG_DIR")" logs/latest
    ln -sfn "$(basename "$LOG_DIR")" "logs/latest_${simulator_name}"
fi
LOG_DIR="$(cd "$LOG_DIR" && pwd)"
RAW_LOG_FILE="$LOG_DIR/raw_output.txt"
LOG_FILE="$LOG_DIR/output.txt"
XCRESULT_PATH="$LOG_DIR/results.xcresult"
mkdir -p "$LOG_DIR/screenshots" || exit 1
export JABTRACKER_TEST_ARTIFACT_DIR="$LOG_DIR/screenshots"
export TEST_RUNNER_JABTRACKER_TEST_ARTIFACT_DIR="$LOG_DIR/screenshots"

if [ "$RESET_DEVICE" = true ]; then
    xcrun simctl shutdown "$DEVICE_ID" >/dev/null 2>&1 || true
    xcrun simctl erase "$DEVICE_ID" || exit 1
    xcrun simctl boot "$DEVICE_ID" || exit 1
fi

BUILD_ARGS=(test -project "$SCRIPT_DIR/../JabTracker.xcodeproj" -scheme "$SCHEME"
    -destination "$DESTINATION" "${TEST_ARGS[@]}" -resultBundlePath "$XCRESULT_PATH"
    -disable-concurrent-destination-testing -parallel-testing-enabled NO)
if [ "$ENABLE_COVERAGE" = true ]; then
    BUILD_ARGS+=(-enableCodeCoverage YES)
fi
if [ "$LOG_ONLY" = false ]; then
    echo "Destination: $DESTINATION"
    echo "Run directory: $LOG_DIR"
fi

if [ "$LOG_ONLY" = true ]; then
    xcodebuild "${BUILD_ARGS[@]}" > "$RAW_LOG_FILE" 2>&1
    TEST_EXIT_CODE=$?
    xcbeautify < "$RAW_LOG_FILE" > "$LOG_FILE" 2>&1
    FORMAT_EXIT_CODE=$?
    LOG_EXIT_CODE=0
else
    xcodebuild "${BUILD_ARGS[@]}" 2>&1 | tee "$RAW_LOG_FILE" | xcbeautify --renderer terminal | tee "$LOG_FILE"
    PIPELINE_STATUS=("${PIPESTATUS[@]}")
    TEST_EXIT_CODE="${PIPELINE_STATUS[0]}"
    FORMAT_EXIT_CODE="${PIPELINE_STATUS[2]}"
    LOG_EXIT_CODE=0
    if [ "${PIPELINE_STATUS[1]}" -ne 0 ] || [ "${PIPELINE_STATUS[3]}" -ne 0 ]; then
        LOG_EXIT_CODE=1
    fi
fi
printf '%s\n' "$TEST_EXIT_CODE" > "$LOG_DIR/xcodebuild-status.txt"

python3 "$SCRIPT_DIR/verify-test-results.py" "$LOG_DIR" --expected-test "$EXPECTED_TEST" \
    > "$LOG_DIR/result-inspection.txt" 2>&1
RESULT_EXIT_CODE=$?
FINAL_EXIT_CODE="$TEST_EXIT_CODE"
for status in "$FORMAT_EXIT_CODE" "$LOG_EXIT_CODE" "$RESULT_EXIT_CODE"; do
    if [ "$FINAL_EXIT_CODE" -eq 0 ] && [ "$status" -ne 0 ]; then
        FINAL_EXIT_CODE="$status"
    fi
done

if [ "$ENABLE_COVERAGE" = true ] && [ -d "$XCRESULT_PATH" ]; then
    xcrun xccov view --report --json "$XCRESULT_PATH" > "$LOG_DIR/coverage.json" 2> "$LOG_DIR/coverage-errors.txt"
    COVERAGE_EXIT_CODE=$?
    if [ "$FINAL_EXIT_CODE" -eq 0 ] && [ "$COVERAGE_EXIT_CODE" -ne 0 ]; then
        FINAL_EXIT_CODE="$COVERAGE_EXIT_CODE"
    fi
fi

if [ "$FINAL_EXIT_CODE" -eq 0 ]; then
    echo "Tests passed (xcodebuild status: $TEST_EXIT_CODE)."
else
    echo "Tests failed (xcodebuild status: $TEST_EXIT_CODE, runner status: $FINAL_EXIT_CODE)." >&2
    cat "$LOG_DIR/result-inspection.txt" >&2
fi
echo "Run directory: $LOG_DIR"
exit "$FINAL_EXIT_CODE"
