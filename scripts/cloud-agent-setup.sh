#!/usr/bin/env bash
#
# Idempotent bootstrap for the JabTracker Cloud Agent (Linux) environment.
#
# JabTracker is an iOS app: building the app and running its XCTest/UI suites
# requires macOS + Xcode and happens on the macOS CI runners. On a Linux Cloud
# Agent this script prepares the parts of the development experience that DO run
# on Linux: the pure-Python tooling suite (food-database pipeline, CI lane
# accounting, release tooling) and the Ruby App Store Connect client those tests
# exercise. See the "CI / Python tooling" job in .github/workflows/ci.yml.
set -euo pipefail

echo "==> JabTracker Cloud Agent setup"

# Ruby is required by scripts/release/testflight.rb and the release-tooling
# tests. It ships only with the Ruby standard library (net/http, openssl, json),
# so no gems are needed for those tests.
if ! command -v ruby >/dev/null 2>&1; then
  echo "==> Installing Ruby"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ruby
fi

echo "==> Tool versions"
python3 --version
ruby --version
git --version
openssl version

# Byte-compile the Python tooling so syntax errors surface during setup rather
# than at first use. This mirrors the "python3 -m compileall -q scripts" CI step.
echo "==> Byte-compiling Python tooling"
python3 -m compileall -q scripts

echo "==> Setup complete"
