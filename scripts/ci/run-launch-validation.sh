#!/usr/bin/env bash

set -uo pipefail

mode="${1:-}"
case "$mode" in
    harness) scheme=JabTrackerReleaseTestHarness; configuration=ReleaseTestHarness ;;
    release) scheme=JabTracker; configuration=Release ;;
    *) echo "Choose harness or release." >&2; exit 2 ;;
esac
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/../.." && pwd)"
evidence_dir="${JABTRACKER_LAUNCH_EVIDENCE_DIR:-${RUNNER_TEMP:?}/launch-$mode}"
derived_data="${RUNNER_TEMP:?}/launch-derived-$mode"
[ ! -e "$evidence_dir" ] || { echo "Evidence directory already exists." >&2; exit 2; }
[ ! -e "$derived_data" ] || { echo "Derived data directory already exists." >&2; exit 2; }
mkdir -p "$evidence_dir" || exit 1
cd "$repo_dir" || exit 1
owned_device=""
trap '
    if [ -n "$owned_device" ]; then
        xcrun simctl shutdown "$owned_device" >/dev/null 2>&1 || true
        xcrun simctl delete "$owned_device" >/dev/null 2>&1 || true
    fi
' EXIT
xcodebuild -version > "$evidence_dir/xcode-version.txt" 2>&1 || exit 1
destination="generic/platform=iOS Simulator"
if [ "$mode" = harness ]; then
    runtime="${LAUNCH_RUNTIME_IDENTIFIER:?}"
    device_type="${LAUNCH_DEVICE_TYPE:?}"
    owned_device="$(xcrun simctl create "JabTracker launch ${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}" \
        "$device_type" "$runtime" 2> "$evidence_dir/simulator-create-errors.txt")" || exit 1
    xcrun simctl boot "$owned_device" > "$evidence_dir/simulator-boot.txt" 2>&1 || exit 1
    xcrun simctl bootstatus "$owned_device" -b >> "$evidence_dir/simulator-boot.txt" 2>&1 || exit 1
    xcrun simctl list devices --json > "$evidence_dir/simulator-devices.json" || exit 1
    xcrun simctl list runtimes --json > "$evidence_dir/simulator-runtimes.json" || exit 1
    destination="platform=iOS Simulator,id=$owned_device"
fi
export LAUNCH_SCHEME="$scheme" LAUNCH_CONFIGURATION="$configuration" LAUNCH_DESTINATION="$destination"
export LAUNCH_UDID="$owned_device" LAUNCH_CONTEXT_PATH="$evidence_dir/context.json"
python3 - <<'PY' || exit 1
import json, os
from datetime import datetime, timezone
from pathlib import Path
payload = {"scheme": os.environ["LAUNCH_SCHEME"], "configuration": os.environ["LAUNCH_CONFIGURATION"],
           "destination": os.environ["LAUNCH_DESTINATION"], "started_at": datetime.now(timezone.utc).isoformat(),
           "fixture": "ci-foods-22", "signed_device_acceptance": False}
if os.environ["LAUNCH_UDID"]:
    devices = json.loads((Path(os.environ["LAUNCH_CONTEXT_PATH"]).parent / "simulator-devices.json").read_text())["devices"]
    matches = [(runtime, device) for runtime, rows in devices.items() for device in rows
               if device["udid"] == os.environ["LAUNCH_UDID"]]
    if len(matches) != 1:
        raise SystemExit("Created simulator was not resolved uniquely.")
    runtime, device = matches[0]
    payload.update(runtime_identifier=runtime, device=device)
Path(os.environ["LAUNCH_CONTEXT_PATH"]).write_text(json.dumps(payload, indent=2) + "\n")
PY
xcodebuild -showBuildSettings -json -project JabTracker.xcodeproj -scheme "$scheme" \
    -configuration "$configuration" -destination "$destination" -derivedDataPath "$derived_data" \
    > "$evidence_dir/build-settings.json" 2> "$evidence_dir/build-settings-errors.txt"
settings_status=$?
if [ "$mode" = release ]; then
    xcodebuild build -project JabTracker.xcodeproj -scheme "$scheme" -configuration "$configuration" \
        -destination "$destination" -derivedDataPath "$derived_data" \
        CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO SWIFT_ENABLE_EXPLICIT_MODULES=NO \
        > "$evidence_dir/raw_output.txt" 2>&1
    build_status=$?
    printf '%s\n' "$build_status" > "$evidence_dir/xcodebuild-status.txt"
else
    "$repo_dir/scripts/test.sh" ui --scheme "$scheme" --configuration "$configuration" \
        --suite-file "$repo_dir/scripts/ci/launch-suite.json" --device-id "$owned_device" \
        --derived-data "$derived_data" --log-dir "$evidence_dir/test-run" --log-only \
        > "$evidence_dir/runner-output.txt" 2>&1
    build_status=$?
    mkdir -p "$evidence_dir/test-run"
    printf '%s\n' "$build_status" > "$evidence_dir/test-run/runner-status.txt"
fi
app="$derived_data/Build/Products/$configuration-iphonesimulator/JabTracker.app"
python3 "$script_dir/launch.py" evidence --run-directory "$evidence_dir" --app "$app" \
    --configuration "$configuration" > "$evidence_dir/evidence-inspection.txt" 2>&1
evidence_status=$?
gate_status=0
if [ "$mode" = harness ]; then
    python3 "$script_dir/launch.py" gate --suite-file "$repo_dir/scripts/ci/launch-suite.json" \
        --run-directory "$evidence_dir" > "$evidence_dir/launch-gate.txt" 2>&1
    gate_status=$?
    printf '%s\n' "$gate_status" > "$evidence_dir/launch-gate-status.txt"
fi
final_status="$build_status"
for status in "$settings_status" "$evidence_status" "$gate_status"; do
    if [ "$final_status" -eq 0 ] && [ "$status" -ne 0 ]; then
        final_status="$status"
    fi
done
cat "$evidence_dir/evidence-inspection.txt"
if [ -f "$evidence_dir/launch-gate.txt" ]; then
    cat "$evidence_dir/launch-gate.txt"
fi
echo "Launch evidence directory: $evidence_dir"
exit "$final_status"
