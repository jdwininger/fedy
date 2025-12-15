#!/usr/bin/env bash
set -euo pipefail

APP_ID="org.videolan.VLC"

if command -v flatpak >/dev/null 2>&1; then
  if flatpak info --user "$APP_ID" >/dev/null 2>&1 || flatpak info "$APP_ID" >/dev/null 2>&1; then
    exit 0
  fi
fi

exit 1
