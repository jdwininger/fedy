#!/usr/bin/env bash
set -euo pipefail

# status.sh for steam.plugin (RPM)
# Exit codes:
# 0 = RPM steam package installed
# 1 = installable
# 5 = blocked because Flatpak Steam is installed

# If Flatpak Steam is installed (system or user), mark this plugin not applicable
if command -v flatpak >/dev/null 2>&1; then
  if flatpak info --user com.valvesoftware.Steam >/dev/null 2>&1 || flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    exit 5
  fi
fi

# Check RPM package
if rpm -q steam >/dev/null 2>&1; then
  exit 0
fi

exit 1
