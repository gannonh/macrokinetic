#!/usr/bin/env bash

set -euo pipefail

archive_app="$1"
ipa="$2"
expected_version="$3"
expected_build="$4"
expected_database_sha="$5"

archive_plist="$RUNNER_TEMP/archive-info.plist"
plutil -convert xml1 -o "$archive_plist" "$archive_app/Info.plist"
archive_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$archive_plist")
archive_build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$archive_plist")
[[ "$archive_version" == "$expected_version" && "$archive_build" == "$expected_build" ]] || exit 1
archive_db_sha=$(shasum -a 256 "$archive_app/usda_foods.sqlite" | awk '{print $1}')
[[ "$archive_db_sha" == "$expected_database_sha" ]] || { echo "archive database checksum mismatch" >&2; exit 1; }

ipa_dir="$RUNNER_TEMP/ipa-inspection"
rm -rf "$ipa_dir"
mkdir -p "$ipa_dir"
unzip -q "$ipa" -d "$ipa_dir"
ipa_app="$ipa_dir/Payload/JabTracker.app"
plutil -convert xml1 -o "$RUNNER_TEMP/ipa-info.plist" "$ipa_app/Info.plist"
ipa_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$RUNNER_TEMP/ipa-info.plist")
ipa_build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$RUNNER_TEMP/ipa-info.plist")
[[ "$ipa_version" == "$expected_version" && "$ipa_build" == "$expected_build" ]] || exit 1
ipa_db_sha=$(shasum -a 256 "$ipa_app/usda_foods.sqlite" | awk '{print $1}')
[[ "$ipa_db_sha" == "$expected_database_sha" ]] || { echo "IPA database checksum mismatch" >&2; exit 1; }

echo "archive and IPA version/build/checksum verification passed"
