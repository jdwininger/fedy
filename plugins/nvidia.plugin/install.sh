#!/usr/bin/env bash
set -euo pipefail

# Example plugin install script for packages provided by RPM Fusion
# This script MUST run as root (Fedy metadata will call it via `run-as-root -s`)

APP="akmod-nvidia"                        # package name to install (replace)
# By default NVIDIA drivers are in RPM Fusion nonfree — enable by default
NEED_NONFREE="${NEED_NONFREE:-true}"

# Parse CLI args (override internal defaults). Passing packages as a comma-separated
# string is supported via --packages "a,b,c" and the nonfree requirement via
# --need-nonfree true|false.
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

# Packages to install for NVIDIA drivers / multimedia support
# Replace or extend these if you need different packages
PACKAGES=(
  akmod-nvidia
  xorg-x11-drv-nvidia-cuda
  vulkan
  xorg-x11-drv-nvidia-cuda-libs
  xorg-x11-drv-nvidia-libs.i686
  nvidia-vaapi-driver
  libva-utils
  vdpauinfo
)

# Which rpm fusion release packages to check
FREE_REPO_PKG="rpmfusion-free-release"
NONFREE_REPO_PKG="rpmfusion-nonfree-release"

# dnf is expected to be present on target systems - no pre-check needed

# Fail fast if not executed as root - the metadata should run this with run-as-root
if [ "$(id -u)" -ne 0 ]; then
  echo "This install script must be run as root" >&2
  exit 1
fi

# Quick hardware probe for NVIDIA GPUs; require an NVIDIA PCI device before installing
if ! command -v lspci >/dev/null 2>&1; then
  # if lspci is missing, continue (we don't want to falsely block installs on minimal systems)
  echo "Warning: lspci not available, skipping NVIDIA hardware probe"
else
  if ! lspci | grep -i -E "nvidia|geforce|nvda" >/dev/null 2>&1; then
    echo "No NVIDIA GPU detected on this system — aborting to avoid installing NVIDIA packages." >&2
    # Exit code 5 indicates no NVIDIA hardware detected
    exit 5
  fi
fi

# Check whether required rpmfusion repo(s) are installed. We do NOT add repos here.
if [ "$NEED_NONFREE" = "true" ]; then
  # Package requires nonfree repo
  if ! rpm -q "$NONFREE_REPO_PKG" >/dev/null 2>&1; then
    echo "RPM Fusion (nonfree) does not appear to be enabled. Aborting install." >&2
    # Exit code 4 indicates required nonfree repo missing
    exit 4
  fi
else
  # If not explicitly requiring nonfree, accept either free or nonfree being present
  if ! rpm -q "$FREE_REPO_PKG" >/dev/null 2>&1 && ! rpm -q "$NONFREE_REPO_PKG" >/dev/null 2>&1; then
    echo "RPM Fusion (free or nonfree) does not appear to be enabled. Aborting install." >&2
    # Exit code 3 indicates repo missing
    exit 3
  fi
fi

echo "RPM Fusion detected; evaluating packages to install..."

# Determine which packages actually need installation
TO_INSTALL=()
for p in "${PACKAGES[@]}"; do
  # Use rpm -q to check install state; this supports arch-suffixed names (eg: pkg.i686)
  if rpm -q "$p" >/dev/null 2>&1; then
    echo "Already installed: $p"
  else
    TO_INSTALL+=("$p")
  fi
done

if [ "${#TO_INSTALL[@]}" -eq 0 ]; then
  echo "All requested NVIDIA packages are already installed — nothing to do."
  exit 0
fi

echo "Installing: ${TO_INSTALL[*]}"
dnf -y install "${TO_INSTALL[@]}"
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "dnf failed with exit code $RC" >&2
  exit $RC
fi

echo "Installation finished."
exit 0
