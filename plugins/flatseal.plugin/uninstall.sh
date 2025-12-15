#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.github.tchx84.Flatseal"

if ! command -v flatpak >/dev/null 2>&1; then
  echo "flatpak is required but is not installed" >&2
  exit 2
fi

if ! flatpak info --user "$APP_ID" >/dev/null 2>&1 && ! flatpak info "$APP_ID" >/dev/null 2>&1; then
  echo "$APP_ID not installed for the user"
  exit 0
fi

flatpak uninstall --user -y "$APP_ID"
exit $?
