#!/usr/bin/env bash
set -euo pipefail

# Template: flatpak install script for plugins
# Usage: place in your-plugin.plugin/install.sh
# Sets APP_ID and REMOTE (default flathub). Per-user install.

APP_ID="net.pcsx2.PCSX2"
REMOTE="${REMOTE:-flathub}"

# Ensure flatpak exists
if ! command -v flatpak >/dev/null 2>&1; then
  echo "flatpak is required but is not installed" >&2
  exit 2
fi

# Add remote if missing
if ! flatpak remotes --columns=name --user | awk '{print $1}' | grep -xq "$REMOTE"; then
  echo "Remote $REMOTE not found, adding..."
  flatpak remote-add --if-not-exists --user "$REMOTE" https://flathub.org/repo/flathub.flatpakrepo || {
    echo "Failed to add remote $REMOTE" >&2
    exit 3
  }
fi

# Check if app already installed
if flatpak info --user "$APP_ID" >/dev/null 2>&1; then
  echo "$APP_ID is already installed"
  exit 0
fi

# Install
echo "Installing $APP_ID from $REMOTE (user)..."
flatpak install --user -y "$REMOTE" "$APP_ID"
exit $?