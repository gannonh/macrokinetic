#!/usr/bin/env bash

set -euo pipefail

destination="${1:?destination directory is required}"
mkdir -p "$destination"
release_json=$(mktemp)
trap 'rm -f "$release_json"' EXIT
gh api --paginate "repos/${GITHUB_REPOSITORY}/releases?per_page=100" | jq -s 'add' > "$release_json"

while IFS= read -r tag; do
    [[ -n "$tag" ]] || continue
    candidate="$destination/$tag"
    rm -rf "$candidate"
    mkdir -p "$candidate"
    if ! gh release download "$tag" --repo "$GITHUB_REPOSITORY" \
        --pattern "usda_foods.sqlite.gz" --pattern "food-db-manifest.json" \
        --dir "$candidate"; then
        continue
    fi
    if python3 scripts/release/verify-snapshot.py \
        --tag "$tag" \
        --manifest "$candidate/food-db-manifest.json" \
        --gzip "$candidate/usda_foods.sqlite.gz"; then
        printf '%s\n' "$tag"
        exit 0
    fi
done < <(python3 scripts/release/snapshot-tags.py < "$release_json")

echo "No valid promoted food snapshot found; full rebuild required" >&2
exit 2
