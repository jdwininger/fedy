#!/usr/bin/env bash
set -euo pipefail

# install.sh for amdgpu.plugin
# This script should run as root (metadata uses run-as-root -s)

NEED_NONFREE="${NEED_NONFREE:-false}"

# Parse CLI args (overrides)
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

# Default package list (can be overridden by metadata via app)
PACKAGES=(
  xorg-x11-drv-amdgpu
  mesa-dri-drivers
  mesa-vulkan-drivers
  vulkan
  libva-utils
  vdpauinfo
)

# Swap commands to prefer the freeworld (non-free) codec/drivers where appropriate
SWAPS=(
  "mesa-va-drivers:mesa-va-drivers-freeworld"
  "mesa-vdpau-drivers:mesa-vdpau-drivers-freeworld"
  "mesa-va-drivers.i686:mesa-va-drivers-freeworld.i686"
  "mesa-vdpau-drivers.i686:mesa-vdpau-drivers-freeworld.i686"
)

# Additional ROCm/opencl packages to install
ROCM_PACKAGES=(
  rocminfo
  rocm-opencl
  rocm-clinfo
  rocm-hip
)

# Root guard
if [ "$(id -u)" -ne 0 ]; then
  echo "This install script must be run as root" >&2
  exit 1
fi

# Quick hardware probe for AMD GPUs
if command -v lspci >/dev/null 2>&1; then
  if ! lspci | grep -i -E "amd|radeon|vega|polaris" >/dev/null 2>&1; then
    echo "No AMD GPU detected on this system — aborting." >&2
    exit 5
  fi
else
  echo "Warning: lspci not available; skipping AMD hardware probe" >&2
fi

# Repos: AMD drivers are usually in the main Fedora repos; no special repo check

echo "Evaluating AMD packages to install..."

TO_INSTALL=()
for p in "${PACKAGES[@]}"; do
  if rpm -q "$p" >/dev/null 2>&1; then
    echo "Already installed: $p"
  else
    TO_INSTALL+=("$p")
  fi
done

if [ "${#TO_INSTALL[@]}" -eq 0 ]; then
  echo "All requested AMD packages already installed — nothing to do."
  exit 0
fi

echo "Running swap steps to enable freeworld drivers (if available)..."
SWAP_FAILURE=0
for s in "${SWAPS[@]}"; do
  from=${s%%:*}
  to=${s##*:}
  echo "Attempting swap: $from -> $to"
  dnf -y swap "$from" "$to"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "Swap failed for $from -> $to with exit code $rc" >&2
    SWAP_FAILURE=1
    # continue to attempt other swaps
  fi
done

# Install ROCm packages if any missing
for rp in "${ROCM_PACKAGES[@]}"; do
  if rpm -q "$rp" >/dev/null 2>&1; then
    echo "Already installed: $rp"
  else
    TO_INSTALL+=("$rp")
  fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
  echo "Installing: ${TO_INSTALL[*]}"
  dnf -y install "${TO_INSTALL[@]}"
  RC=$?
  if [ "$RC" -ne 0 ]; then
    echo "dnf failed with exit code $RC" >&2
    exit $RC
  fi
else
  echo "No additional packages to install after swaps/ROCm checks."
fi

if [ "$SWAP_FAILURE" -ne 0 ]; then
  echo "One or more swap operations failed; please inspect the logs." >&2
  exit 1
fi
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "dnf failed with exit code $RC" >&2
  exit $RC
fi

echo "Installation finished."
exit 0
