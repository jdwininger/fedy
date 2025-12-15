#!/usr/bin/env bash
set -euo pipefail

# status.sh for steam-flathub.plugin
# Exit codes:
# 0 = flatpak Steam installed
# 1 = installable
# 5 = blocked because RPM steam package is installed

# If RPM package steam is present, block (don't allow installing Flatpak)
if command -v rpm >/dev/null 2>&1; then
  if rpm -q steam >/dev/null 2>&1; then
    exit 5
  fi
fi

# Check if Flatpak Steam is installed (user or system)
if command -v flatpak >/dev/null 2>&1; then
  if flatpak info --user com.valvesoftware.Steam >/dev/null 2>&1 || flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    exit 0
  fi
fi

# Not installed
exit 1
