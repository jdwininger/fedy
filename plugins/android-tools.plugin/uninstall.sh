#!/usr/bin/env bash
set -euo pipefail

# uninstall.sh for android-tools.plugin
if [ "$(id -u)" -ne 0 ]; then
  echo "This uninstall script must be run as root" >&2
  exit 1
fi

PACKAGES=("android-tools" "android-tools-adb" "android-tools-fastboot")

if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  REMOVE=()
  for p in "${PACKAGES[@]}"; do
    if rpm -q "$p" >/dev/null 2>&1; then
      REMOVE+=("$p")
    fi
  done
  if [ "${#REMOVE[@]}" -gt 0 ]; then
    if command -v dnf >/dev/null 2>&1; then
      dnf -y remove "${REMOVE[@]}"
    else
      yum -y remove "${REMOVE[@]}"
    fi
  fi
  exit 0
fi
echo "No supported RPM package manager found (dnf/yum). This plugin targets Fedora." >&2
exit 2
