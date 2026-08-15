#!/usr/bin/env bash

set -euo pipefail

ipa="${1:?IPA path is required}"
api_key_path="${2:?Fastlane API-key JSON path is required}"
log_path="${3:?Transporter log path is required}"

bundle exec fastlane pilot upload \
    --ipa "$ipa" \
    --api_key_path "$api_key_path" \
    --skip_waiting_for_build_processing true \
    --distribute_external false \
    2>&1 | tee "$log_path"

# Transporter prints an upload identifier when it accepts a delivery. Do not
# manufacture one: without this identifier a retry cannot prove ownership.
delivery_id=$(grep -Eio '([Dd]elivery|[Uu]pload)[[:space:]_-]*(id|identifier)[=:[:space:]]+[A-Za-z0-9._-]+' "$log_path" \
    | tail -1 \
    | sed -E 's/.*[=:[:space:]]+//' || true)
if [[ -z "$delivery_id" ]]; then
    echo "Transporter accepted no parseable delivery identifier; refusing an unsafe retry" >&2
    exit 1
fi
printf '%s\n' "$delivery_id"
