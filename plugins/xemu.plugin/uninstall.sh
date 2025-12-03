#!/usr/bin/env bash
set -euo pipefail

APP_ID="app.xemu.xemu"

command -v flatpak >/dev/null 2>&1 || { echo "flatpak is required"; exit 2; }

if ! flatpak list --app --columns=application --user | awk -v id="$APP_ID" '$0==id {exit 0} END{exit 1}'; then
  echo "$APP_ID not installed for the user"
  exit 0
fi

echo "Uninstalling $APP_ID (user)..."
flatpak uninstall --user -y "$APP_ID"
exit $?