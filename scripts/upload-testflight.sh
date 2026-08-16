#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/upload-testflight.sh --group internal [options]

Options:
  --group GROUP       Required TestFlight internal group.
  --version VERSION   Optional marketing version (for example 0.10.2).
  --build BUILD       Optional positive build number.
  --watch             Wait for the dispatched workflow to finish.
  --ref REF           Dispatch from this ref (default: main).
  --help              Show this help.
USAGE
}

group=""
version=""
build=""
watch=false
ref="main"

while (($#)); do
    case "$1" in
        --group)
            group="${2:-}"
            shift 2
            ;;
        --version)
            version="${2:-}"
            shift 2
            ;;
        --build)
            build="${2:-}"
            shift 2
            ;;
        --watch)
            watch=true
            shift
            ;;
        --ref)
            ref="${2:-}"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ "$group" != "internal" ]]; then
    echo "--group must be exactly internal" >&2
    exit 2
fi
if [[ -n "$version" && ! "$version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "--version must match X.Y or X.Y.Z" >&2
    exit 2
fi
if [[ -n "$build" && ! "$build" =~ ^[1-9][0-9]*$ ]]; then
    echo "--build must be a positive base-10 integer" >&2
    exit 2
fi
if [[ "$ref" != "main" ]]; then
    echo "--ref must be main; releases are only dispatched from main" >&2
    exit 2
fi

command -v gh >/dev/null || { echo "gh is required" >&2; exit 1; }
workflow="TestFlight Release"
gh workflow run "$workflow" \
    --ref main \
    -f "group=$group" \
    -f "marketing_version=$version" \
    -f "build_number=$build"

# gh workflow run does not print the created run consistently across CLI
# versions, so resolve the newest dispatch for the exact workflow/ref.
run_id=""
for _ in {1..12}; do
    run_id=$(gh run list --workflow testflight-release.yml --branch main \
        --event workflow_dispatch --limit 1 --json databaseId -q '.[0].databaseId')
    [[ -n "$run_id" ]] && break
    sleep 1
done

echo "Dispatched TestFlight Release run ${run_id:-unknown}"
if [[ "$watch" == true && -n "${run_id:-}" ]]; then
    gh run watch "$run_id" --exit-status
fi
