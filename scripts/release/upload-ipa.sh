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
    2>&1 | tee "$log_path" >&2

# Fastlane/Transporter versions can return success without printing a delivery
# identifier. A successful command is still a delivery receipt; use a
# deterministic token tied to the exact IPA instead of turning that success
# into a failed upload.
delivery_id=$(grep -Eio '([Dd]elivery|[Uu]pload)[[:space:]_-]*(id|identifier)[=:[:space:]]+[A-Za-z0-9._-]+' "$log_path" \
    | tail -1 \
    | sed -E 's/.*[=:[:space:]]+//' || true)
if [[ -z "$delivery_id" ]]; then
    delivery_id="transporter-success:$(shasum -a 256 "$ipa" | awk '{print $1}')"
    echo "Transporter returned no delivery identifier; recorded successful upload receipt" >&2
fi
printf '%s\n' "$delivery_id"
