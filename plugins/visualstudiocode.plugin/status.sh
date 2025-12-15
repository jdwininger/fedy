#!/usr/bin/env bash
set -euo pipefail

# status.sh for visualstudiocode.plugin
# Exit codes:
# 0 = package installed
# 1 = installable
# 5 = not applicable (unlikely but reserved)

# Allow overriding packages via --packages
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

# Default package name
PACKAGES=(code)

# Check for RPM (Fedora)
if command -v rpm >/dev/null 2>&1; then
  for p in "${PACKAGES[@]}"; do
    if rpm -q "$p" >/dev/null 2>&1; then
      exit 0
    fi
  done
fi

# If DNF/YUM present, it's installable
if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  exit 1
fi

# No supported RPM package manager
exit 5
