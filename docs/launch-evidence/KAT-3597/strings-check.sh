#!/bin/bash
# usage: strings-check.sh <binary>  -> prints count of each control token in the binary
BIN="$1"
S=$(mktemp); strings -a "$BIN" > "$S"
# also include debug dylib if present
for t in -- "--ui-testing" "--reset-app-data" "--manual-ui-testing" "--bypass-onboarding" "--force-onboarding" "--seed-test" "--seed-check-in" "--seed-calorie-user" "--seed-collaborative" "--seed-" "-active" "TEST_DATA_" "UI_TESTING" "--mock-active-energy" "--test-titration-data" "--deeplink-url" "--disable-cloudkit" "--cloudkit-testing" "-inMemory" "--food-search-fail-once" "XCTestConfigurationFilePath" "XCTestSessionIdentifier" "SWIFT_TESTING" "--storage-fixture" "--storage-fail-first-open" "--storage-always-fail-open" "XCTestCase"; do
  [ "$t" = "--" ] && continue
  printf "%-32s %s\n" "$t" "$(grep -c -F -- "$t" "$S")"
done
rm -f "$S"
