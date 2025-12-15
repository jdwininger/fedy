#!/usr/bin/env bash
set -euo pipefail

# Template: flatpak uninstall script for plugins
# Usage: place in your-plugin.plugin/uninstall.sh

APP_ID="net.kuribo64.melonDS"

# Ensure flatpak exists
if ! command -v flatpak >/dev/null 2>&1; then
  echo "flatpak is required but is not installed" >&2
  exit 2
fi

# Check if installed
if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
  echo "$APP_ID not installed for the user"
  exit 0
fi

# Uninstall
flatpak uninstall --user -y "$APP_ID"
exit $?
