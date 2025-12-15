#!/usr/bin/env bash
set -euo pipefail

# status.sh for amdgpu.plugin
# Exit codes:
# 0 = package installed (any of the packages present)
# 1 = hardware present but driver packages not installed
# 5 = no AMD GPU present

NEED_NONFREE="${NEED_NONFREE:-false}"

# Parse CLI args for --packages and --need-nonfree
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

# Default packages if none provided
# Only set PACKAGES default if the CLI didn't provide --packages
if [ -z "${PACKAGES[*]:-}" ]; then
  PACKAGES=(
    xorg-x11-drv-amdgpu
  )
fi

# Detect AMD GPU more robustly.
# Prefer sysfs PCI vendor ids (0x1002). Fall back to lspci if sysfs isn't available.
detect_amd=false

# Check /sys (preferred, no external binary needed).
# Only treat devices that are display-class (PCI class 0x03xx) and vendor 0x1002
# as AMD GPUs. Avoid scanning arbitrary pci device vendor files which can match
# AMD vendor IDs on non-display devices.
#
# First check DRM devices (exposed GPUs / DRM cards) and framebuffer devices.
for dev in /sys/class/drm/card* /sys/class/graphics/fb*; do
  if [ -e "$dev" ]; then
    # try to find a vendor file reachable from this path
    if [ -f "$dev/device/vendor" ]; then
        vendor=$(tr -d '[:space:]' < "$dev/device/vendor" 2>/dev/null || true)
        # Some DRM / fb devices may point to non-PCI devices; check vendorID only
        if [ "${vendor:-}" = "0x1002" ] || echo "${vendor:-}" | grep -qi "1002" >/dev/null 2>&1; then
          detect_amd=true
          break
        fi
      fi
  fi
done

# If sysfs didn't find a DRM/FB AMD device, inspect PCI devices but only
# those with a class indicating display controllers (0x03XX). This avoids
# false positives from other AMD devices.
if [ "$detect_amd" = false ] && [ -d /sys/bus/pci/devices ]; then
  for d in /sys/bus/pci/devices/*; do
    if [ -f "$d/vendor" ] && [ -f "$d/class" ]; then
      vendor=$(tr -d '[:space:]' < "$d/vendor" 2>/dev/null || true)
      devclass=$(tr -d '[:space:]' < "$d/class" 2>/dev/null || true)
      # devclass will be like 0x030000 for VGA controller; match 0x03 prefix
      if echo "${devclass}" | grep -q -E '^0x03'; then
        if [ "${vendor:-}" = "0x1002" ] || echo "${vendor:-}" | grep -qi "1002" >/dev/null 2>&1; then
          detect_amd=true
          break
        fi
      fi
    fi
  done
fi

# Fall back to lspci if the above checks didn't find anything and lspci exists
# Only consider lines describing a GPU (VGA / 3D controller) and ensure
# the vendor id is 1002 (AMD). This avoids matching non-GPU AMD text in
# unrelated devices.
# lspci fallback: only consider VGA/3D lines and vendor id 1002
if [ "$detect_amd" = false ] && command -v lspci >/dev/null 2>&1; then
  if lspci -nn | grep -iE '(VGA|3D).*\[1002:' >/dev/null 2>&1; then
    detect_amd=true
  fi
fi

if [ "$detect_amd" != true ]; then
  # No AMD GPU detected — treat plugin as not applicable
  exit 5
fi

# check any of the driver packages
for p in "${PACKAGES[@]}"; do
  if rpm -q "$p" >/dev/null 2>&1; then
    exit 0
  fi
done

exit 1
