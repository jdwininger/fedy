#!/usr/bin/env bash
set -euo pipefail

# install.sh for steam-flathub.plugin
# Respect the presence of the RPM steam package - refuse to proceed if it's installed
if command -v rpm >/dev/null 2>&1; then
  if rpm -q steam >/dev/null 2>&1; then
    echo "RPM 'steam' package is installed; cannot install the Flatpak Steam at the same time." >&2
    exit 2
  fi
fi

if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak is not available on this system." >&2
  exit 3
fi

flatpak install --user flathub com.valvesoftware.Steam -y
exit $?
