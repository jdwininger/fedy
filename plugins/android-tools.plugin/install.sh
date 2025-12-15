#!/usr/bin/env bash
set -euo pipefail

# install.sh for android-tools.plugin
# Accepts --packages override (comma-separated)

# Parse --packages
while [ "$#" -gt 0 ]; do
  case "$1" in
    --packages)
      shift
      IFS=',' read -r -a PACKAGES <<< "$1"
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "This install script must be run as root" >&2
  exit 1
fi

# Default packages to try
PACKAGES=("android-tools" "android-tools-adb" "android-tools-fastboot")

# If apt is present, prefer deb package names
if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  INSTALL=()
  for p in "${PACKAGES[@]}"; do
    if command -v dnf >/dev/null 2>&1; then
      if dnf info "$p" >/dev/null 2>&1; then
        INSTALL+=("$p")
      fi
    else
      if yum info "$p" >/dev/null 2>&1; then
        INSTALL+=("$p")
      fi
    fi
  done
  if [ "${#INSTALL[@]}" -eq 0 ]; then
    echo "No android tools packages found in DNF/YUM repositories." >&2
    exit 2
  fi
  if command -v dnf >/dev/null 2>&1; then
    dnf -y install "${INSTALL[@]}"
  else
    yum -y install "${INSTALL[@]}"
  fi
  exit $?
fi
echo "No supported RPM package manager found (dnf/yum). This plugin targets Fedora." >&2
exit 3
