#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This uninstaller must be run as root." >&2
  exit 2
fi

pkgs=(winetricks wine)

if command -v dnf >/dev/null 2>&1; then
  dnf -y remove "${pkgs[@]}"
else
  echo "DNF not found. Please remove packages manually: ${pkgs[*]}" >&2
  exit 1
fi

exit 0
