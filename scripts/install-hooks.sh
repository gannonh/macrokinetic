#!/bin/sh

set -eu

repo_root=$(git rev-parse --show-toplevel)
git -C "$repo_root" config core.hooksPath .githooks

echo "Installed repository hooks at $repo_root/.githooks"
echo "Pre-commit: staged whitespace, SwiftLint, and Python compile checks"
echo "Pre-push: Git LFS object upload"
echo "CI runs project integrity, lint, Python, and test validation."
