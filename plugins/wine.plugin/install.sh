#!/usr/bin/env bash
set -euo pipefail

# This script must be run as root (metadata runs it with run-as-root -s)
if [ "$(id -u)" -ne 0 ]; then
  echo "This installer must be run as root." >&2
  exit 2
fi

pkgs=(wine winetricks)

echo "Installing ${pkgs[*]} via DNF..."
if command -v dnf >/dev/null 2>&1; then
  dnf -y install "${pkgs[@]}"
else
  echo "DNF not found. Please install packages manually: ${pkgs[*]}" >&2
  exit 1
fi

echo "Wine and Winetricks installation attempt finished."
exit 0
