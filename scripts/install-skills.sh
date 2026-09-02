#!/usr/bin/env bash
# Install the plan-build-verify plugin for a GitHub-issue product repo.
#
# Installs the Cursor plugin from gannonh/plan-build-verify. Does not npx-add
# the deleted gannonh/skills pack skill or address-pr-comments.
# Does not install ps, okf, or kata-linear. pstack is a separate Cursor plugin.
#
# Usage:
#   bash scripts/install-skills.sh

set -euo pipefail

PLUGIN_REPO="https://github.com/gannonh/plan-build-verify.git"
CURSOR_PLUGIN_DIR="${HOME}/.cursor/plugins/local/plan-build-verify"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

echo "==> Installing plan-build-verify Cursor plugin"
mkdir -p "$(dirname "$CURSOR_PLUGIN_DIR")"
git clone --depth 1 --filter=blob:none --sparse "$PLUGIN_REPO" "$tmpdir"
git -C "$tmpdir" sparse-checkout set plugins/cursor
rm -rf "$CURSOR_PLUGIN_DIR"
cp -R "$tmpdir/plugins/cursor" "$CURSOR_PLUGIN_DIR"
echo "    Installed to $CURSOR_PLUGIN_DIR"
echo "    Enable Allow Local Plugin Imports in Cursor, then enable plan-build-verify."
echo "    Claude Code: /plugin marketplace add gannonh/plan-build-verify"
echo "                 /plugin install plan-build-verify@plan-build-verify"
