#!/usr/bin/env bash
set -euo pipefail

# status script for nvidia.plugin
# Exit codes:
# 0 = package installed (plugin should show "Remove")
# 1 = package not installed but hardware present (plugin should show "Install")
# 5 = no NVIDIA GPU detected — plugin not applicable (UI should disable the install button)

APP="akmod-nvidia" # primary package used as a canonical driver indicator

# Mirror the install list: if ANY of these packages are present consider drivers installed
PACKAGES=(
  akmod-nvidia
  xorg-x11-drv-nvidia-cuda
  xorg-x11-drv-nvidia-cuda-libs
  xorg-x11-drv-nvidia-libs.i686
  nvidia-vaapi-driver
)

# Probe for NVIDIA GPU
if command -v lspci >/dev/null 2>&1; then
  if ! lspci | grep -i -E "nvidia|geforce|nvda" >/dev/null 2>&1; then
    # no Nvidia device present
    exit 5
  fi
else
  # If lspci is missing we can't reliably check hardware. Treat as "installable" rather than blocking.
  echo "Warning: lspci not available; skipping GPU probe" >&2
fi

# Parse CLI args: --packages "a,b,c" --need-nonfree true|false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --packages)
      shift
      IFS=',' read -r -a PACKAGES <<< "$1"
      shift
      ;;
    --need-nonfree)
      shift
      NEED_NONFREE="$1"
      shift
      ;;
    *)
      break
      ;;
  esac
done

# If GPU detected, check whether any of the known driver packages are installed
for p in "${PACKAGES[@]}"; do
  if rpm -q "$p" >/dev/null 2>&1; then
    exit 0
  fi
done

# None of the driver packages matched; report installable
exit 1
