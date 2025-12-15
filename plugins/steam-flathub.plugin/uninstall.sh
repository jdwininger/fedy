#!/usr/bin/env bash
set -euo pipefail

# uninstall.sh for steam-flathub.plugin
if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak is not available on this system." >&2
  exit 3
fi

flatpak uninstall --user com.valvesoftware.Steam -y
exit $?
