#!/usr/bin/env bash

set -euo pipefail

group="${1:-}"
marketing_version="${2:-}"
build_number="${3:-}"

if [[ "$group" != "dev" && "$group" != "internal" ]]; then
    echo "group must be dev or internal" >&2
    exit 1
fi
if [[ -n "$marketing_version" && ! "$marketing_version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "marketing_version must match ^[0-9]+(\\.[0-9]+){1,2}$" >&2
    exit 1
fi
if [[ -n "$build_number" && ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
    echo "build_number must be a positive base-10 integer" >&2
    exit 1
fi

echo "inputs valid: group=$group marketing_version=${marketing_version:-auto} build_number=${build_number:-auto}"
