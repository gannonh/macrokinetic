#!/usr/bin/env bash

set -euo pipefail

project_file="${1:-project.yml}"

value_for() {
    local key="$1"
    awk -v key="$key" '
        /^[[:space:]]*#/ { next }
        $0 ~ "^[[:space:]]*" key ":" {
            sub("^[^:]*:[[:space:]]*", "", $0)
            sub(/[[:space:]]+#.*/, "", $0)
            gsub(/[\"]/, "", $0)
            print $0
            exit
        }
    ' "$project_file"
}

version=$(value_for MARKETING_VERSION)
if [[ -z "$version" ]]; then
    echo "MARKETING_VERSION is missing from $project_file" >&2
    exit 1
fi
printf '%s\n' "$version"
