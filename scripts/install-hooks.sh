#!/bin/sh

set -eu

repo_root=$(git rev-parse --show-toplevel)
git -C "$repo_root" config core.hooksPath .githooks

echo "Installed repository hooks at $repo_root/.githooks"
echo "Pre-commit: staged whitespace, SwiftLint, and Python compile checks"
echo "Pre-push: project integrity, Python tests, unit tests, and Git LFS"
echo "Use git push --no-verify only when intentionally bypassing local checks."
