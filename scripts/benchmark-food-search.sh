#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'USAGE'
Usage: scripts/benchmark-food-search.sh <physical-device-udid>

Runs the Release-only pizza/chicken/bread food-search benchmark. The device
must be a connected physical iPhone 17 Pro running iOS 26.2. Each query gets
10 cold runs (a fresh app process per run) and 10 warm runs (one warmed process).
The XCTest output reports cold and warm p95 in milliseconds.

Set FOOD_SEARCH_DEVICE_UDID instead of passing the UDID as the first argument.
USAGE
    exit 0
fi

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
device_udid="${1:-${FOOD_SEARCH_DEVICE_UDID:-}}"

if [[ -z "$device_udid" ]]; then
    echo "Physical benchmark unavailable: provide an iPhone 17 Pro iOS 26.2 UDID." >&2
    echo "Usage: $0 <physical-device-udid>" >&2
    exit 2
fi

if ! command -v xcrun >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "Physical benchmark unavailable: xcrun and jq are required." >&2
    exit 2
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "Release benchmark unavailable: sqlite3 is required to validate the database fixture." >&2
    exit 2
fi

device_json="$(mktemp "${TMPDIR:-/tmp}/food-search-device.XXXXXX.json")"
trap 'rm -f "$device_json"' EXIT
if ! xcrun devicectl list devices --json-output "$device_json" >/dev/null 2>&1; then
    echo "Physical benchmark unavailable: could not enumerate CoreDevice devices." >&2
    exit 2
fi

device_info="$(jq -r --arg udid "$device_udid" '
    .result.devices[]
    | select(.hardwareProperties.udid == $udid)
    | [
        .hardwareProperties.marketingName,
        .deviceProperties.osVersionNumber,
        .hardwareProperties.reality,
        .connectionProperties.tunnelState,
        (.deviceProperties.ddiServicesAvailable | tostring)
      ]
    | @tsv
' "$device_json" | head -n 1)"
IFS=$'\t' read -r device_model device_os device_reality device_tunnel device_ddi <<< "$device_info"
if [[ "$device_model" != "iPhone 17 Pro" \
    || "$device_os" != "26.2" \
    || "$device_reality" != "physical" \
    || "$device_tunnel" != "connected" \
    || "$device_ddi" != "true" ]]; then
    echo "Physical benchmark unavailable: UDID is not an online iPhone 17 Pro on iOS 26.2." >&2
    echo "Detected device: model=${device_model:-none} os=${device_os:-none} reality=${device_reality:-none} tunnel=${device_tunnel:-none} ddi=${device_ddi:-none}" >&2
    echo "Simulator, other models, other OS versions, and unavailable devices are intentionally rejected." >&2
    exit 2
fi
device_line="$device_model ($device_os) ($device_udid)"

database_path="$project_root/JabTracker/Resources/usda_foods.sqlite"
if [[ ! -f "$database_path" ]]; then
    echo "Release benchmark unavailable: missing $database_path" >&2
    echo "Install the 2M+ row release database fixture before running the benchmark." >&2
    exit 2
fi

database_bytes="$(stat -L -f '%z' "$database_path")"
database_rows="$(sqlite3 "$database_path" 'SELECT COUNT(*) FROM foods;' 2>/dev/null || true)"
expected_database_rows=2177482
expected_database_bytes=578564096
if [[ ! "$database_rows" =~ ^[0-9]+$ \
    || "$database_rows" -ne "$expected_database_rows" \
    || "$database_bytes" -ne "$expected_database_bytes" ]]; then
    echo "Release benchmark unavailable: expected ${expected_database_rows} rows and ${expected_database_bytes} bytes, found ${database_rows:-unknown} rows and ${database_bytes:-unknown} bytes." >&2
    exit 2
fi
echo "Release database fixture: ${database_rows} rows, ${database_bytes} bytes"

benchmark_log="$(mktemp "${TMPDIR:-/tmp}/food-search-release-benchmark.XXXXXX")"
trap 'rm -f "$benchmark_log" "$device_json"' EXIT

echo "Running Release food-search benchmark on: $device_line"
echo "Results are reported only after the XCTest emits all 10 cold and 10 warm runs per query."

set -o pipefail
xcodebuild test \
    -project "$project_root/JabTracker.xcodeproj" \
    -scheme JabTrackerFoodSearchBenchmark \
    -configuration Release \
    -destination "platform=iOS,id=$device_udid" \
    -only-testing:JabTrackerFoodSearchBenchmarkTests/FoodSearchReleaseBenchmarkUITests/testReleaseSearchLatencyBenchmark \
    -parallel-testing-enabled NO \
    -disable-concurrent-destination-testing \
    | tee "$benchmark_log"

echo
echo "Reported p95 results:"
if ! grep '^FOOD_SEARCH_RELEASE_BENCHMARK ' "$benchmark_log"; then
    echo "Benchmark completed without machine-readable p95 output." >&2
    exit 1
fi
