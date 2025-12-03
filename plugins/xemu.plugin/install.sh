#!/usr/bin/env bash
set -euo pipefail

APP_ID="app.xemu.xemu"
REMOTE="${REMOTE:-flathub}"

# Make sure flatpak exists
command -v flatpak >/dev/null 2>&1 || { echo "flatpak is required"; exit 2; }

# Add flathub remote if necessary
if ! flatpak remotes --columns=name | awk '{print $1}' | grep -xq "$REMOTE"; then
  echo "Adding remote: $REMOTE"
  flatpak remote-add --if-not-exists "$REMOTE" https://flathub.org/repo/flathub.flatpakrepo
fi

# Check already installed (user)
if flatpak list --app --columns=application --user | awk -v id="$APP_ID" '$0==id {exit 0} END{exit 1}'; then
  echo "$APP_ID is already installed for the user"
  exit 0
fi

# Install
echo "Installing $APP_ID (user)..."
flatpak install --user -y "$REMOTE" "$APP_ID"
exit_code=$?

if [ $exit_code -eq 0 ]; then
  echo "Installed $APP_ID"
else
  echo "Install failed with exit code $exit_code"
fi

exit $exit_code