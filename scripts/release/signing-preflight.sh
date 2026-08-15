#!/usr/bin/env bash

set -euo pipefail

: "${APPLE_DISTRIBUTION_CERTIFICATE_BASE64:?missing distribution certificate}"
: "${APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD:?missing certificate password}"
: "${APPLE_PROVISIONING_PROFILE_BASE64:?missing provisioning profile}"
: "${APPLE_KEYCHAIN_PASSWORD:?missing keychain password}"

keychain="$RUNNER_TEMP/jabtracker-${GITHUB_RUN_ID}.keychain-db"
certificate="$RUNNER_TEMP/distribution.p12"
profile="$RUNNER_TEMP/profile.mobileprovision"
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
python3 - "$certificate" "$profile" <<'PY'
import base64
import os
import sys

Path = __import__("pathlib").Path
Path(sys.argv[1]).write_bytes(base64.b64decode(os.environ["APPLE_DISTRIBUTION_CERTIFICATE_BASE64"]))
Path(sys.argv[2]).write_bytes(base64.b64decode(os.environ["APPLE_PROVISIONING_PROFILE_BASE64"]))
PY

security create-keychain -p "$APPLE_KEYCHAIN_PASSWORD" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$APPLE_KEYCHAIN_PASSWORD" "$keychain"
security import "$certificate" -k "$keychain" -P "$APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security list-keychains -d user -s "$keychain"
security set-key-partition-list -S apple-tool:,apple: -s -k "$APPLE_KEYCHAIN_PASSWORD" "$keychain"

identity=$(security find-identity -v -p codesigning "$keychain" | awk -F'"' '/Apple Distribution/ { print $2; exit }')
[[ -n "$identity" ]] || { echo "no Apple Distribution identity in imported keychain" >&2; exit 1; }

profile_plist="$RUNNER_TEMP/profile.plist"
security cms -D -i "$profile" > "$profile_plist"
team=$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$profile_plist")
bundle=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$profile_plist")
profile_name=$(/usr/libexec/PlistBuddy -c 'Print :Name' "$profile_plist")
expiration=$(/usr/libexec/PlistBuddy -c 'Print :ExpirationDate' "$profile_plist")
[[ "$team" == "ZBZKKWF95G" ]] || { echo "profile team mismatch: $team" >&2; exit 1; }
[[ "$bundle" == "ZBZKKWF95G.com.gannonhall.JabTracker" ]] || { echo "profile bundle mismatch: $bundle" >&2; exit 1; }
[[ -n "$expiration" ]] || { echo "profile expiration is missing" >&2; exit 1; }
get_task_allow=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:get-task-allow' "$profile_plist" 2>/dev/null || echo false)
[[ "$get_task_allow" == "false" ]] || { echo "development provisioning profile is not allowed" >&2; exit 1; }
uuid=$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$profile_plist")
cp "$profile" "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"

printf 'SIGNING_IDENTITY=%s\nPROFILE_NAME=%s\nKEYCHAIN_PATH=%s\n' "$identity" "$profile_name" "$keychain" >> "$GITHUB_ENV"
